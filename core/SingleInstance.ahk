#Requires AutoHotkey v2.0

; 自定义单实例控制：重复启动时关闭现有实例，再由新实例继续启动。
global __SingleInstance_hMutex := 0

SingleInstance_MutexName() {
    p := A_ScriptFullPath
    if (StrLen(p) > 220) {
        h := 0
        loop parse p {
            h := Mod(h * 31 + Ord(A_LoopField), 0x7FFFFFFF)
        }
        p := Format("h%x", h)
    }
    return "Local\DAFAutoFire_" StrReplace(p, "\", "_")
}

SingleInstance_TryHandOffAndExit() {
    global __SingleInstance_hMutex
    name := SingleInstance_MutexName()
    DllCall("kernel32\SetLastError", "UInt", 0)
    __SingleInstance_hMutex := DllCall("kernel32\CreateMutexW", "Ptr", 0, "Int", false, "WStr", name, "Ptr")
    if DllCall("kernel32\GetLastError", "UInt") != 183 {
        return
    }
    DetectHiddenWindows(true)
    SetTitleMatchMode(2)
    try {
        hwnd := WinExist("DAF连发工具 - DNF AutoFire")
        if !hwnd {
            hwnd := WinExist("DAF连发工具")
        }
        if hwnd {
            winRef := "ahk_id " hwnd
            WinClose(winRef)
            WinWaitClose(winRef,, 3)
        }
    }
    DetectHiddenWindows(false)
    h := __SingleInstance_hMutex
    __SingleInstance_hMutex := 0
    if h {
        DllCall("kernel32\CloseHandle", "Ptr", h)
    }
    Sleep(300)
}

SingleInstance_ReleaseMutex() {
    global __SingleInstance_hMutex
    if (__SingleInstance_hMutex) {
        DllCall("kernel32\CloseHandle", "Ptr", __SingleInstance_hMutex)
        __SingleInstance_hMutex := 0
    }
}
