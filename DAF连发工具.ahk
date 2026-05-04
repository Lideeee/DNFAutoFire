#Requires AutoHotkey v2.0
;@Ahk2Exe-SetMainIcon icon_main.ico
;@Ahk2Exe-AddResource icon_alert.ico, 160
;@Ahk2Exe-AddResource icon_green.ico, 206
;@Ahk2Exe-AddResource icon_red.ico, 207

;@Ahk2Exe-SetDescription DAF连发工具
;@Ahk2Exe-SetCopyright 某亚瑟
;@Ahk2Exe-SetLanguage 0x0804
;@Ahk2Exe-SetProductName DAF连发工具
;@Ahk2Exe-SetProductVersion 0.2.6
;@Ahk2Exe-SetVersion 0.2.6

; 允许 SubProcessThread 启动并存子进程；Ignore 会把子进程直接拒绝掉
#SingleInstance Off
#WinActivateForce
SetWorkingDir(A_ScriptDir)
A_MaxHotkeysPerInterval := 9999
; 子进程（/Run=xxx）在 very early 阶段就隐藏图标，避免短暂闪出多个托盘图标
if (A_Args.Length >= 1 && InStr(A_Args[1], "/Run=")) {
    A_IconHidden := true
}

global __Version := "0.2.6"

#Include <RunWithAdministrator>
#Include <MultipleThread>
#Include <Keys>
#Include <JSON>
#Include <Time>
#Include <GetPressKey>
#Include ./core/SendIP.ahk
#Include ./core/KeyConvert.ahk
#Include ./core/Config.ahk
EnsureConfigInitialized()
#Include ./core/AutoFire.ahk
#Include ./core/Scripts.ahk
#Include ./gui/Main.ahk
#Include ./gui/QuickSwitch.ahk
#Include ./gui/Setting.ahk
#Include ./gui/ex/LvRen.ahk
#Include ./ex/ExLvRen.ahk
#Include ./gui/ex/GuanYu.ahk
#Include ./ex/ExGuanYu.ahk
#Include ./gui/ex/PetSkill.ahk
#Include ./ex/ExPetSkill.ahk
#Include ./gui/ex/ZhanFa.ahk
#Include ./ex/ExZhanFa.ahk
#Include ./gui/ex/JianZong.ahk
#Include ./ex/ExJianZong.ahk
#Include ./gui/ex/AutoRun.ahk
#Include ./ex/ExAutoRun.ahk
#Include .\gui\ex\Combo.ahk
#Include .\ex\ExCombo.ahk

; 必须放在所有 #Include 之后：子进程 /Run=XXX 需要先看到 Keys.ahk 等函数定义
SubProcessThread.ScriptStart()

;@Ahk2Exe-IgnoreBegin
#Include <Log>
; 源码直接运行时也会执行本段；Log() 会挂控制台，易导致启动异常。需要调试时再取消下一行注释。
; Log()
;@Ahk2Exe-IgnoreEnd

A_TrayMenu.Delete()
A_TrayMenu.Add("连发设置", ShowGuiMain)
A_TrayMenu.Add("软件设置", ShowGuiSetting)
A_TrayMenu.Default := "连发设置"
A_TrayMenu.Add()
A_TrayMenu.Add("退出连发", Exit)
A_TrayMenu.ClickCount := 1
A_IconTip := "DAF连发工具"
try TraySetIcon(A_ScriptDir "\icon_main.ico")

Exit(*) {
    ExitApp()
}

; 确保退出时停止连发并恢复系统计时精度（timeBeginPeriod）
OnExit(CleanupOnExit)
CleanupOnExit(*) {
    try StopAutoFire()
}

global _AutoFireThreads := []
global _AutoFireEnableKeys := []
global _AutoFireSingleProcessTimers := []
global _NowSelectPreset := LoadLastPreset()

ShowGuiMain()
SetDNFWindowClass()
if (_AutoStart) {
    HideGuiMain()
    StartAutoFire()
}
