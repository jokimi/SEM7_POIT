#include <iostream>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <ctime>
#include <thread>
#include <chrono>
#include <mutex>
#include <unordered_map>
#include <string>
#include <windows.h>

#pragma comment(lib, "WS2_32.lib")
#pragma warning(disable: 4996)
using namespace std;

struct GETSINCRO {
    char cmd[4]; // Всегда "SINC"
    long long curvalue; // Текущее значение счетчика клиента (unix ms)
};

struct SETSINCRO {
    char cmd[4]; // Всегда "SINC"
    long long correction; // Корректировка для счетчика клиента
};

struct ClientState {
    int req_num = 0;
    long long sum_corr = 0;
};

// Структура NTP пакета (48 байт)
struct NTPPacket {
    uint8_t li_vn_mode;
    uint8_t stratum;
    uint8_t poll;
    uint8_t precision;
    uint32_t root_delay;
    uint32_t root_disp;
    uint32_t ref_id;
    uint64_t ref_ts;
    uint64_t origin_ts;
    uint64_t recv_ts;
    uint64_t tx_ts;
};

// Глобальная корректировка времени (offset в ms)
long long time_offset = 0;

// Глобальные мьютексы для синхронизации
std::mutex state_mutex;
std::mutex cout_mutex;
std::mutex offset_mutex;

// Карта для хранения состояния каждого клиента по IP
std::unordered_map<std::string, ClientState> clients;


string GetErrorMsgText(int code) {
    string msgText;
    switch (code) {
    case WSAEINTR: msgText = "Работа функции прервана"; break;
    case WSAEACCES: msgText = "Разрешение отвергнуто"; break;
    case WSAEFAULT: msgText = "Ошибочный адрес"; break;
    case WSAEINVAL: msgText = "Ошибка в аргументе"; break;
    case WSAEMFILE: msgText = "Слишком много файлов открыто"; break;
    case WSAEWOULDBLOCK: msgText = "Ресурс временно недоступен"; break;
    case WSAEINPROGRESS: msgText = "Операция в процессе развития"; break;
    case WSAEALREADY: msgText = "Операция уже выполняется"; break;
    case WSAENOTSOCK: msgText = "Сокет задан неправильно"; break;
    case WSAEDESTADDRREQ: msgText = "Требуется адрес расположения"; break;
    case WSAEMSGSIZE: msgText = "Сообщение слишком длинное"; break;
    case WSAEPROTOTYPE: msgText = "Неправильный тип протокола для сокета"; break;
    case WSAENOPROTOOPT: msgText = "Ошибка в опции протокола"; break;
    case WSAEPROTONOSUPPORT: msgText = "Протокол не поддерживается"; break;
    case WSAESOCKTNOSUPPORT: msgText = "Тип сокета не поддерживается"; break;
    case WSAEOPNOTSUPP: msgText = "Операция не поддерживается"; break;
    case WSAEPFNOSUPPORT: msgText = "Тип протоколов не поддерживается"; break;
    case WSAEAFNOSUPPORT: msgText = "Тип адресов не поддерживается протоколом"; break;
    case WSAEADDRINUSE: msgText = "Адрес уже используется"; break;
    case WSAEADDRNOTAVAIL: msgText = "Запрошенный адрес не может быть использован"; break;
    case WSAENETDOWN: msgText = "Сеть отключена"; break;
    case WSAENETUNREACH: msgText = "Сеть не достижима"; break;
    case WSAENETRESET: msgText = "Сеть разорвала соединение"; break;
    case WSAECONNABORTED: msgText = "Программный отказ связи"; break;
    case WSAECONNRESET: msgText = "Связь восстановлена"; break;
    case WSAENOBUFS: msgText = "Не хватает памяти для буферов"; break;
    case WSAEISCONN: msgText = "Сокет уже подключен"; break;
    case WSAENOTCONN: msgText = "Сокет не подключен"; break;
    case WSAESHUTDOWN: msgText = "Нельзя выполнить send: сокет завершил работу"; break;
    case WSAETIMEDOUT: msgText = "Закончился отведенный интервал времени"; break;
    case WSAECONNREFUSED: msgText = "Соединение отклонено"; break;
    case WSAEHOSTDOWN: msgText = "Хост в неработоспособном состоянии"; break;
    case WSAEHOSTUNREACH: msgText = "Нет маршрута для хоста"; break;
    case WSAEPROCLIM: msgText = "Слишком много процессов"; break;
    case WSASYSNOTREADY: msgText = "Сеть не доступна"; break;
    case WSAVERNOTSUPPORTED: msgText = "Данная версия недоступна"; break;
    case WSANOTINITIALISED: msgText = "Не выполнена инициализация WS2_32.DLL"; break;
    case WSAEDISCON: msgText = "Выполняется отключение"; break;
    case WSATYPE_NOT_FOUND: msgText = "Класс не найден"; break;
    case WSAHOST_NOT_FOUND: msgText = "Хост не найден"; break;
    case WSATRY_AGAIN: msgText = "Неавторизированный хост не найден"; break;
    case WSANO_RECOVERY: msgText = "Неопределенная ошибка"; break;
    case WSANO_DATA: msgText = "Нет записи запрошенного типа"; break;
    case WSA_INVALID_HANDLE: msgText = "Указанный дескриптор события с ошибкой"; break;
    case WSA_INVALID_PARAMETER: msgText = "Один или более параметров с ошибкой"; break;
    case WSA_IO_INCOMPLETE: msgText = "Объект ввода-вывода не в сигнальном состоянии"; break;
    case WSA_IO_PENDING: msgText = "Операция завершится позже"; break;
    case WSA_NOT_ENOUGH_MEMORY: msgText = "Не достаточно памяти"; break;
    case WSA_OPERATION_ABORTED: msgText = "Операция отвергнута"; break;
    case WSAEINVALIDPROCTABLE: msgText = "Ошибочный сервис"; break;
    case WSAEINVALIDPROVIDER: msgText = "Ошибка в версии сервиса"; break;
    case WSAEPROVIDERFAILEDINIT: msgText = "Невозможно инициализировать сервис"; break;
    case WSASYSCALLFAILURE: msgText = "Аварийное завершение системного вызова"; break;
    default: msgText = "Неизвестная ошибка"; break;
    }
    return msgText + " (" + to_string(code) + ")";
}

string SetErrorMsgText(string msgText, int code) {
    return msgText + GetErrorMsgText(code);
}

// Функция для получения текущего времени в мс с 01.01.1970 (Unix timestamp ms)
long long get_unix_ms() {
    FILETIME ft;
    GetSystemTimeAsFileTime(&ft);
    ULARGE_INTEGER uli;
    uli.HighPart = ft.dwHighDateTime;
    uli.LowPart = ft.dwLowDateTime;
    uli.QuadPart -= 116444736000000000ULL; // Смещение от 1601 к 1970
    return uli.QuadPart / 10000; // В миллисекунды
}

// Конвертация Unix ms в NTP timestamp (network byte order)
uint64_t unix_to_ntp(long long unix_ms) {
    long long unix_sec = unix_ms / 1000;
    long long frac_ms = unix_ms % 1000;
    uint64_t ntp_sec = unix_sec + 2208988800ULL; // Смещение от 1970 к 1900
    uint64_t ntp_frac = (frac_ms * 4294967296ULL) / 1000;
    uint64_t ntp_ts = (ntp_sec << 32) | ntp_frac;
    return (((uint64_t)htonl(ntp_ts)) << 32) | htonl(ntp_ts >> 32);
}

// Конвертация NTP timestamp (host byte order) в Unix ms
long long ntp_to_unix(uint64_t ntp_ts) {
    uint64_t ntp_sec = ntp_ts >> 32;
    uint64_t ntp_frac = ntp_ts & 0xFFFFFFFFULL;
    long long unix_sec = ntp_sec - 2208988800ULL;
    long long frac_ms = (ntp_frac * 1000ULL) / 4294967296ULL;
    return unix_sec * 1000 + frac_ms;
}

// Функция для синхронизации с NTP сервером
void sync_with_ntp(WSADATA& wsaData) {
    SOCKET ntp_socket = INVALID_SOCKET;
    addrinfo* result = nullptr;
    try {
        // Разрешение адреса pool.ntp.org
        addrinfo hints = { 0 };
        hints.ai_family = AF_INET;
        hints.ai_socktype = SOCK_DGRAM;
        hints.ai_protocol = IPPROTO_UDP;

        int res = getaddrinfo("pool.ntp.org", "123", &hints, &result);
        if (res != 0) {
            std::lock_guard<std::mutex> lock(cout_mutex);
            cout << "NTP: Ошибка разрешения адреса, код: " << res << endl;
            return;
        }

        // Создание UDP-сокета для NTP
        if ((ntp_socket = socket(AF_INET, SOCK_DGRAM, 0)) == INVALID_SOCKET)
            throw SetErrorMsgText("NTP Socket: ", WSAGetLastError());

        // Установка таймаута для получения ответа (5 секунд)
        int timeout = 10000;
        if (setsockopt(ntp_socket, SOL_SOCKET, SO_RCVTIMEO, (char*)&timeout, sizeof(timeout)) == SOCKET_ERROR)
            throw SetErrorMsgText("NTP Setsockopt: ", WSAGetLastError());

        // Подготовка NTP пакета
        NTPPacket packet = { 0 };
        packet.li_vn_mode = (0 << 6) | (4 << 3) | 3; // LI=0, VN=4, Mode=3 (client)

        long long T1_unix = get_unix_ms();
        packet.origin_ts = unix_to_ntp(T1_unix);

        // Отправка пакета
        if (sendto(ntp_socket, (char*)&packet, sizeof(NTPPacket), 0, result->ai_addr, result->ai_addrlen) == SOCKET_ERROR)
            throw SetErrorMsgText("NTP SendTo: ", WSAGetLastError());

        // Получение ответа
        int addr_size = result->ai_addrlen;
        if (recvfrom(ntp_socket, (char*)&packet, sizeof(NTPPacket), 0, result->ai_addr, &addr_size) == SOCKET_ERROR)
            throw SetErrorMsgText("NTP RecvFrom: ", WSAGetLastError());

        long long T4_unix = get_unix_ms();

        // Конвертация в host order
        uint64_t origin_ntp = (((uint64_t)ntohl(packet.origin_ts)) << 32) | ntohl(packet.origin_ts >> 32);
        uint64_t recv_ntp = (((uint64_t)ntohl(packet.recv_ts)) << 32) | ntohl(packet.recv_ts >> 32);
        uint64_t tx_ntp = (((uint64_t)ntohl(packet.tx_ts)) << 32) | ntohl(packet.tx_ts >> 32);

        long long T2_unix = ntp_to_unix(recv_ntp);
        long long T3_unix = ntp_to_unix(tx_ntp);

        // Вычисление offset
        long long offset = ((T2_unix - T1_unix) + (T3_unix - T4_unix)) / 2;

        {
            std::lock_guard<std::mutex> lock(offset_mutex);
            time_offset = offset;
        }

        {
            std::lock_guard<std::mutex> lock(cout_mutex);
            cout << "NTP Sync: Offset updated to " << offset << " ms" << endl;
        }
    }
    catch (string errorMsg) {
        std::lock_guard<std::mutex> lock(cout_mutex);
        cout << errorMsg << endl;
    }
    if (ntp_socket != INVALID_SOCKET) closesocket(ntp_socket);
    if (result) freeaddrinfo(result);
}

// Поток для периодической синхронизации с NTP
void ntp_sync_thread(WSADATA wsaData) {
    while (true) {
        sync_with_ntp(wsaData);
        this_thread::sleep_for(chrono::milliseconds(10000));
    }
}

// Функция обработки запроса в отдельном потоке
void handle_request(SOCKET serverSocket, SOCKADDR_IN clientAddr, GETSINCRO timeRequest) {
    // Получение IP клиента
    char ip_str[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, &clientAddr.sin_addr, ip_str, sizeof(ip_str));
    std::string ip = ip_str;

    // Вычисление Cs (текущее время сервера в ms с учетом offset)
    long long Cs;
    {
        std::lock_guard<std::mutex> lock(offset_mutex);
        Cs = get_unix_ms() + time_offset;
    }

    // Вычисление коррекции
    long long correction = Cs - timeRequest.curvalue;

    int local_req_num;
    double local_avg = 0.0;
    {
        std::lock_guard<std::mutex> lock(state_mutex);
        auto& state = clients[ip]; // Создает запись, если не существует
        state.req_num++;
        local_req_num = state.req_num;
        if (local_req_num > 1) {
            state.sum_corr += correction;
            local_avg = static_cast<double>(state.sum_corr) / (local_req_num - 1);
        }
    }

    // Подготовка и отправка ответа
    SETSINCRO timeResponse;
    strcpy(timeResponse.cmd, "SINC");
    timeResponse.correction = correction;

    int clientAddrSize = sizeof(clientAddr);
    if (sendto(serverSocket, (char*)&timeResponse, sizeof(timeResponse), 0, (sockaddr*)&clientAddr, clientAddrSize) == SOCKET_ERROR) {
        std::lock_guard<std::mutex> lock(cout_mutex);
        cout << SetErrorMsgText("SendTo: ", WSAGetLastError()) << endl;
        return;
    }

    {
        std::lock_guard<std::mutex> lock(cout_mutex);
        cout << "Client IP: " << ip
            << ", Request #: " << local_req_num
            << ", Correction: " << correction;
        if (local_req_num > 1) {
            cout << ", Avg Correction: " << local_avg;
        }
        cout << endl;
    }
}

int main() {
    setlocale(LC_ALL, "ru_RU.UTF-8");

    SOCKET serverSocket;
    WSADATA wsaData;
    SOCKADDR_IN serverAddr, clientAddr;

    cout << "UDP Time Sync Server Running..." << endl;

    try {
        // Инициализация Winsock
        if (WSAStartup(MAKEWORD(2, 0), &wsaData) != 0)
            throw SetErrorMsgText("WSAStartup: ", WSAGetLastError());

        // Создание UDP-сокета для сервера
        if ((serverSocket = socket(AF_INET, SOCK_DGRAM, 0)) == INVALID_SOCKET)
            throw SetErrorMsgText("Socket: ", WSAGetLastError());

        // Настройка адреса сервера
        serverAddr.sin_family = AF_INET;
        serverAddr.sin_port = htons(5000);
        serverAddr.sin_addr.s_addr = INADDR_ANY;

        // Разрешение повторного использования адреса
        int opt = 1;
        if (setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, (char*)&opt, sizeof(opt)) == SOCKET_ERROR)
            throw SetErrorMsgText("Setsockopt: ", WSAGetLastError());

        // Привязка сокета к адресу
        if (bind(serverSocket, (LPSOCKADDR)&serverAddr, sizeof(serverAddr)) == SOCKET_ERROR)
            throw SetErrorMsgText("Bind: ", WSAGetLastError());

        // Запуск потока синхронизации с NTP
        thread ntp_thread(ntp_sync_thread, wsaData);
        ntp_thread.detach(); // Отделяем поток для независимой работы

        GETSINCRO timeRequest;
        int clientAddrSize = sizeof(clientAddr);

        while (true) {
            // Получение запроса (блокирующее)
            if (recvfrom(serverSocket, (char*)&timeRequest, sizeof(timeRequest), 0, (sockaddr*)&clientAddr, &clientAddrSize) == SOCKET_ERROR)
                throw SetErrorMsgText("RecvFrom: ", WSAGetLastError());

            // Запуск отдельного потока для обработки и отправки ответа
            std::thread t(handle_request, serverSocket, clientAddr, timeRequest);
            t.detach(); // Отделяем поток, чтобы не ждать его завершения
        }
    }
    catch (string errorMsg) {
        std::lock_guard<std::mutex> lock(cout_mutex);
        cout << errorMsg << endl;
    }

    // Закрытие сокета
    if (closesocket(serverSocket) == SOCKET_ERROR) {
        std::lock_guard<std::mutex> lock(cout_mutex);
        cout << SetErrorMsgText("Close socket: ", WSAGetLastError()) << endl;
    }

    // Очистка Winsock
    if (WSACleanup() == SOCKET_ERROR) {
        std::lock_guard<std::mutex> lock(cout_mutex);
        cout << SetErrorMsgText("Cleanup: ", WSAGetLastError()) << endl;
    }

    return 0;
}