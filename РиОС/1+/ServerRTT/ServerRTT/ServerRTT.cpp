#include <iostream>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <ctime>
#include <thread>
#include <mutex>
#include <unordered_map>
#include <string>

#pragma comment(lib, "WS2_32.lib")
#pragma warning(disable: 4996)
using namespace std;

struct GETSINCRO {
    char cmd[4]; // Всегда "SINC"
    int curvalue; // Текущее значение счетчика клиента
    clock_t client_send_time;
};

struct SETSINCRO {
    char cmd[4]; // Всегда "SINC"
    int correction; // Корректировка для счетчика клиента
    clock_t server_time;
};

struct ClientState {
    int req_num = 0;
    long long sum_corr = 0;
};

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

// Глобальные мьютексы для синхронизации
std::mutex state_mutex;
std::mutex cout_mutex;

// Карта для хранения состояния каждого клиента по IP
std::unordered_map<std::string, ClientState> clients;

// Функция обработки запроса в отдельном потоке
void handle_request(SOCKET serverSocket, SOCKADDR_IN clientAddr, GETSINCRO timeRequest, clock_t Cs) {
    // Получение IP клиента
    char ip_str[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, &clientAddr.sin_addr, ip_str, sizeof(ip_str));
    std::string ip = ip_str;

    // Вычисление коррекции
    int correction = static_cast<int>(Cs - timeRequest.curvalue);

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
    timeResponse.server_time = Cs;

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

        // Создание UDP-сокета
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

        GETSINCRO timeRequest;
        clock_t start_clock = clock(); // Время запуска сервера

        int clientAddrSize = sizeof(clientAddr);

        while (true) {
            // Получение запроса (блокирующее)
            if (recvfrom(serverSocket, (char*)&timeRequest, sizeof(timeRequest), 0, (sockaddr*)&clientAddr, &clientAddrSize) == SOCKET_ERROR)
                throw SetErrorMsgText("RecvFrom: ", WSAGetLastError());

            // Время получения запроса
            clock_t Cs = clock() - start_clock;

            // Запуск отдельного потока для обработки и отправки ответа
            std::thread t(handle_request, serverSocket, clientAddr, timeRequest, Cs);
            t.detach(); // Отделяем поток, чтобы не ждать его завершения
        }

        if (closesocket(serverSocket) == SOCKET_ERROR)
            throw SetErrorMsgText("Close socket: ", WSAGetLastError());

        if (WSACleanup() == SOCKET_ERROR)
            throw SetErrorMsgText("Cleanup: ", WSAGetLastError());
    }
    catch (string errorMsg) {
        cout << errorMsg << endl;
    }

    return 0;
}