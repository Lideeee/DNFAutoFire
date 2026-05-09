#Requires AutoHotkey v2.0
;@Ahk2Exe-SetMainIcon icon_main.ico
;@Ahk2Exe-AddResource icon_alert.ico, 160
;@Ahk2Exe-AddResource icon_green.ico, 206
;@Ahk2Exe-AddResource icon_red.ico, 207

;@Ahk2Exe-SetDescription DAF连发工具
;@Ahk2Exe-SetCopyright 某亚瑟
;@Ahk2Exe-SetLanguage 0x0804
;@Ahk2Exe-SetProductName DAF连发工具
;@Ahk2Exe-SetProductVersion 0.2.8
;@Ahk2Exe-SetVersion 0.2.8

#SingleInstance Off
#WinActivateForce
SetWorkingDir(A_ScriptDir)
#Include ./core/SingleInstance.ahk
SingleInstance_TryHandOffAndExit()
A_MaxHotkeysPerInterval := 9999

global __Version := "0.2.8"

#Include <RunWithAdministrator>
; 在 UAC 判定之后：最终驻留进程（含已提升管理员的重启实例）设为高优先级。HIGH 对本进程一般无需管理员。
try ProcessSetPriority("High")
#Include <Keys>
#Include <JSON>
#Include <Time>
#Include <GetPressKey>
#Include <GdiPlusSession>
#Include <GuiTheme>
#Include ./core/SendIP.ahk
#Include ./core/GetKeycode.ahk
#Include ./core/Config.ahk
EnsureConfigInitialized()
#Include ./core/SessionState.ahk
SessionState.InitFromLastPreset()
#Include ./core/PresetExFeatures.ahk
#Include ./core/GameContext.ahk
#Include ./core/KeyRouter.ahk
#Include ./core/AutoFireController.ahk
#Include ./core/PresetRecognition.ahk
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
#Include ./gui/ex/Combo.ahk
#Include ./ex/ExCombo.ahk
#Include ./gui/PresetAutoSwitch.ahk
#Include ./gui/ex/PresetSkillIcon.ahk

; Winmm timeBeginPeriod(1) 提升定时器精度；退出时在 CleanupOnExit 与 RestoreSystemTimeLimit 成对
global _MainProcessTimePeriodActive := false
try {
    UnlockSystemTimeLimit()
    _MainProcessTimePeriodActive := true
} catch {
}

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

; 确保退出时停止连发并恢复系统计时精度（timeEndPeriod，与主进程 timeBeginPeriod 成对）
OnExit(CleanupOnExit)
CleanupOnExit(*) {
    try SingleInstance_ReleaseMutex()
    try GdiPlusSession.Shutdown()
    try PresetRecognition_DisableAllHotkeys()
    try KeyRouter.StopFocusWatcher()
    try StopAutoFire()
    try GameContext.Shutdown()
    global _MainProcessTimePeriodActive
    if (_MainProcessTimePeriodActive) {
        try RestoreSystemTimeLimit()
        _MainProcessTimePeriodActive := false
    }
}

GameContext.Init()
PresetRecognition_UpdateHotkeys()

ShowGuiMain()
KeyRouter.StartFocusWatcher()
if (_AutoStart) {
    HideGuiMain()
    StartAutoFire()
    try PresetRecognition_StartSequence()
}
