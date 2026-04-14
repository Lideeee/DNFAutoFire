; 显示控制台并输出内容（默认自动添加换行）
log(str := "", rn := 1)
{
  if !DllCall("GetConsoleWindow") {
    pid := 0
    hwnd := WinExist("ahk_class ConsoleWindowClass")
    if hwnd {
      pid := WinGetPID("ahk_id " hwnd)
    } else {
      Run('cmd.exe /k "echo off"', , , &pid)
      WinWait("ahk_pid " pid)
    }
    DllCall("AttachConsole", "Int", pid)
  }
  FileAppend(str (rn ? "`r`n" : ""), "*")
}

; 关闭控制台（手动关闭会退出AHK程序）
logoff()
{
  DllCall("FreeConsole")
}
