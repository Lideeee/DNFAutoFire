#Requires AutoHotkey v2.0
#Include ./Version.ahk
;@Ahk2Exe-SetMainIcon lib\ui\icons\icon_main.ico
;@Ahk2Exe-AddResource lib\ui\icons\icon_alert.ico, 160
;@Ahk2Exe-AddResource lib\ui\icons\icon_green.ico, 206
;@Ahk2Exe-AddResource lib\ui\icons\icon_red.ico, 207

;@Ahk2Exe-SetDescription DNFAutoFire
;@Ahk2Exe-SetCopyright 某亚瑟
;@Ahk2Exe-SetLanguage 0x0804
;@Ahk2Exe-SetProductName DNFAutoFire
;@Ahk2Exe-SetProductVersion %AppVersion%
;@Ahk2Exe-SetVersion %AppVersion%

; 允许 SubProcessThread 启动并存子进程；Ignore 会把子进程直接拒绝掉
#SingleInstance Off
#WinActivateForce
SetWorkingDir(A_ScriptDir)
SetTitleMatchMode(3)
A_MaxHotkeysPerInterval := 9999
; 子进程（/Run=xxx）在 very early 阶段就隐藏图标，避免短暂闪出多个托盘图标
if (A_Args.Length >= 1 && InStr(A_Args[1], "/Run=")) {
    A_IconHidden := true
}

global __Version := APP_VERSION

#Include <RunWithAdministrator>
#Include <MultipleThread>
#Include <Keys>
#Include <Time>
#Include <GetPressKey>
#Include ./core/SendIP.ahk
#Include ./core/KeyConvert.ahk
#Include ./core/Config.ahk
EnsureConfigInitialized()
#Include ./core/Scripts.ahk
#Include ./core/AutoFire.ahk
#Include ./core/ComboPreset.ahk
#Include ./ex/ExActionRuntime.ahk

; 子进程 /Run=… 仅解析到此为止即进入连发逻辑；主进程在返回后继续加载 GUI 等大段代码
SubProcessThread.ScriptStart()

; 自定义 IPC 消息：WM_APP + 1，用于“重复打开”时通知已运行实例停止连发并显示主界面
global IPC_WM_REVEAL_MAIN := 0x8001

global __MainInstanceMutex := EnsureMainSingleInstance()

EnsureMainSingleInstance() {
    mutexName := "DNFAutoFire.Main." StrReplace(A_ScriptFullPath, "\", ".")
    hMutex := DllCall("CreateMutex", "ptr", 0, "int", true, "str", mutexName, "ptr")
    if (!hMutex) {
        return 0
    }
    if (A_LastError = 183) {
        ; 已有实例在运行：不再弹窗，改为通知它停止连发并显示主界面，然后自身退出
        NotifyRunningInstanceReveal()
        ExitApp()
    }
    return hMutex
}

; IPC 监听窗口标题：与互斥量命名同源，保证同一路径下唯一
MainIpcWindowTitle() {
    return "DNFAutoFire.IPC." StrReplace(A_ScriptFullPath, "\", ".")
}

; 重复打开时，通知已经在运行的主实例停止连发并显示主界面
NotifyRunningInstanceReveal() {
    global IPC_WM_REVEAL_MAIN
    ipcTitle := MainIpcWindowTitle()
    prevDhw := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    try {
        hwnd := WinExist(ipcTitle)
        if (hwnd) {
            PostMessage(IPC_WM_REVEAL_MAIN, 0, 0, , "ahk_id " hwnd)
        }
    } catch {
        ; 找不到主实例 IPC 窗口时静默退出，不再弹窗
    }
    DetectHiddenWindows(prevDhw)
}

; 主实例创建隐藏 IPC 监听窗口，接收“重复打开”通知
global gMainIpcGui := ""

CreateMainIpcListener() {
    global gMainIpcGui, IPC_WM_REVEAL_MAIN
    gMainIpcGui := Gui("-Caption +ToolWindow")
    gMainIpcGui.Title := MainIpcWindowTitle()
    ; 访问 Hwnd 强制创建窗口；不调用 Show，保持隐藏，仅用于接收 PostMessage
    _ := gMainIpcGui.Hwnd
    OnMessage(IPC_WM_REVEAL_MAIN, OnIpcRevealMain)
}

OnIpcRevealMain(wParam, lParam, msg, hwnd) {
    ; 复用托盘“连发设置”同一套停止连发并显示主界面的逻辑
    try RevealStoppedMainGui()
}

#Include ./lib/GdiPlusSession.ahk
#Include ./lib/GdipUiHelpers.ahk
#Include ./lib/ToggleGdip.ahk
#Include ./core/AutoPresets.ahk
#Include ./gui/MainText.ahk
#Include ./gui/exText.ahk
#Include ./gui/AutoPresetsText.ahk
#Include ./lib/ui/Theme.ahk
#Include ./lib/ui/Layout.ahk
#Include ./lib/ui/Controls.ahk
#Include ./lib/ui/PressKeyEdit.ahk
#Include ./lib/ui/ListBoxDragSort.ahk
#Include ./lib/ui/KeyCap.ahk
#Include ./gui/main/MainLayout.ahk
#Include ./gui/ex/ExLayout.ahk
#Include ./gui/AutoPresets/AutoPresetsLayout.ahk
#Include ./gui/main/Main.ahk
#Include ./gui/AutoPresets/AutoPresets.ahk
#Include ./gui/main/QuickSwitch.ahk
#Include ./gui/main/Setting.ahk
#Include ./gui/ex/LvRen.ahk
#Include ./gui/ex/GuanYu.ahk
#Include ./gui/ex/PetSkill.ahk
#Include ./gui/ex/ZhanFa.ahk
#Include ./gui/ex/JianZong.ahk
#Include ./gui/ex/XiuLuo.ahk
#Include ./gui/ex/AutoRun.ahk
#Include ./gui/ex/Combo.ahk

global _AutoFireThreads := []
global _AutoFireEnableKeys := []
global _AutoFireKeyIntervals := Map()
global _AutoFireKeyDelays := Map()
global _NowSelectPreset := LoadLastPreset()

;@Ahk2Exe-IgnoreBegin
#Include <Log>
; 源码直接运行时也会执行本段；Log() 会挂控制台，易导致启动异常。需要调试时再取消下一行注释。
; Log()
;@Ahk2Exe-IgnoreEnd

A_TrayMenu.Delete()
A_TrayMenu.Add(MainText["TraySettings"], RevealStoppedMainGui)
A_TrayMenu.Default := MainText["TraySettings"]
A_TrayMenu.Add()
A_TrayMenu.Add(MainText["TrayExit"], Exit)
A_TrayMenu.ClickCount := 1
A_IconTip := MainText["TrayTip"]
try TraySetIcon(A_IsCompiled ? A_ScriptFullPath : A_ScriptDir "\lib\ui\icons\icon_main.ico", 1)

Exit(*) {
    try SaveCurrentPresetState()
    try StopAutoFire()
    ExitApp()
}

RevealStoppedMainGui(*) {
    SwitchToStoppedState()
    gMainGui.Show("w" MainLayout.GuiWidth() " h" MainLayout.GuiHeight())
    SetTimer(MainMutedLinkPoll, 100)
}

MainProcessOnExit(*) {
    try SaveCurrentPresetState()
    try StopAutoFire()
}

OnExit(MainProcessOnExit)

RevealStoppedMainGui()
CreateMainIpcListener()
RegisterGameWindowGroup()
if (_AutoStart) {
    EnterRunningMode()
}
