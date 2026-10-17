#include <iostream>
#include <thread>
#include <fstream>
#include <windows.h>
using namespace std;
void trigger()
{
    Sleep(500);
    ofstream f("trigger.tmp");
    f << "change";
}
int main()
{
    HANDLE h = FindFirstChangeNotificationA(".", FALSE, FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_LAST_WRITE);
    if (h == INVALID_HANDLE_VALUE)
        return 1;
    cout << "Watching directory for modifications...\n";
    thread t(trigger);
    WaitForSingleObject(h, INFINITE);
    cout << "Directory change detected!\n";
    t.join();
    FindCloseChangeNotification(h);
    DeleteFileA("trigger.tmp");
}
