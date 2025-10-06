#include <iostream>
#include <winsock2.h>
#include <ctime>
#include <windows.h>
#include <string>
#pragma comment(lib, "WS2_32.lib")
#pragma warning(disable: 4996)
using namespace std;

struct GETSINCRO {
    char cmd[4]; // Всегда "SINC"
    long long curvalue; // Текущее значение счетчика клиента (теперь unix ms)
};

struct SETSINCRO {
    char cmd[4]; // Всегда "SINC"
    long long correction; // Корректировка для счетчика клиента
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

// // Функция для установки системного времени по Unix timestamp ms (требует прав администратора)
// void set_system_time(long long new_unix_ms) {
//     ULARGE_INTEGER uli;
//     uli.QuadPart = (new_unix_ms * 10000) + 116444736000000000ULL;
//     FILETIME ft;
//     ft.dwHighDateTime = uli.HighPart;
//     ft.dwLowDateTime = uli.LowPart;
//     SYSTEMTIME st;
//     FileTimeToSystemTime(&ft, &st);
//     if (!SetSystemTime(&st)) {
//         cout << "Ошибка установки системного времени: " << GetLastError() << endl;
//     } else {
//         cout << "Системное время обновлено на: " << new_unix_ms << " ms" << endl;
//     }
// }

int main(int argc, char* argv[]) {
    setlocale(LC_ALL, "ru_RU.UTF-8");

    string defaultIP = "127.0.0.1";
    string serverIP = (argc >= 2) ? argv[1] : defaultIP;
    cout << "Server IP: " << serverIP << endl;

    long Tc = (argc >= 3) ? atol(argv[2]) : 14000;
    cout << "Tc: " << Tc << " ms" << endl;

    SOCKET clientSocket;
    WSADATA wsaData;
    SOCKADDR_IN serverAddr;


    cout << "UDP Time Sync Client Running..." << endl;

    try {
        // Инициализация Winsock
        if (WSAStartup(MAKEWORD(2, 0), &wsaData) != 0)
            throw SetErrorMsgText("WSAStartup: ", WSAGetLastError());

        // Создание UDP-сокета
        if ((clientSocket = socket(AF_INET, SOCK_DGRAM, 0)) == INVALID_SOCKET)
            throw SetErrorMsgText("Socket: ", WSAGetLastError());

        // Настройка адреса сервера
        serverAddr.sin_family = AF_INET;
        serverAddr.sin_port = htons(5000); // Порт сервера
        serverAddr.sin_addr.s_addr = inet_addr(serverIP.c_str());

        GETSINCRO timeRequest;
        SETSINCRO timeResponse;
        int request_number = 0;
        long long sum_CcMinusOStime = 0;
        long long avg_CcMinusOStime;
        long long Cc;
        Cc = get_unix_ms();


        strcpy(timeRequest.cmd, "SINC");

        while (request_number < 10) {
            request_number++;
            if (request_number == 0) {
                timeRequest.curvalue = get_unix_ms();
            }
            else {
                timeRequest.curvalue = Cc;
            }
            cout << "Request #" << request_number << ", curvalue: " << timeRequest.curvalue << endl;

            if (sendto(clientSocket, (char*)&timeRequest, sizeof(timeRequest), 0, (sockaddr*)&serverAddr, sizeof(serverAddr)) == SOCKET_ERROR)
                throw SetErrorMsgText("SendTo: ", WSAGetLastError());

            int serverAddrSize = sizeof(serverAddr);
            try {
                if (recvfrom(clientSocket, (char*)&timeResponse, sizeof(timeResponse), 0, (sockaddr*)&serverAddr, &serverAddrSize) == SOCKET_ERROR)
                    throw SetErrorMsgText("RecvFrom: ", WSAGetLastError());

                // Корректировка и установка системного времени
                // Cc = get_unix_ms();
                long long current_time = get_unix_ms();
                cout << "Received correction: " << timeResponse.correction << endl;
                Cc += timeResponse.correction;

                long CcMinusOStime = Cc - get_unix_ms();
                cout << "Cc - OStime: " << CcMinusOStime << endl;

                sum_CcMinusOStime += CcMinusOStime;
                avg_CcMinusOStime = sum_CcMinusOStime / request_number;
                cout << "Avg Cc - OStime: " << avg_CcMinusOStime << endl;
            }
            catch (string errorMsg) {
                cout << errorMsg << endl;
            }

            Sleep(Tc);

            Cc += Tc;
        }

        if (closesocket(clientSocket) == SOCKET_ERROR)
            throw SetErrorMsgText("Close socket: ", WSAGetLastError());

        if (WSACleanup() == SOCKET_ERROR)
            throw SetErrorMsgText("Cleanup: ", WSAGetLastError());
    }
    catch (string errorMsg) {
        cout << errorMsg << endl;
    }

    return 0;
}