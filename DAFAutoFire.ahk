#Requires AutoHotkey v2.0
;@Ahk2Exe-SetMainIcon assets\icons\icon_main.ico
;@Ahk2Exe-AddResource assets\icons\icon_alert.ico, 160
;@Ahk2Exe-AddResource assets\icons\icon_green.ico, 206
;@Ahk2Exe-AddResource assets\icons\icon_red.ico, 207

;@Ahk2Exe-SetDescription DAF连发工具
;@Ahk2Exe-SetCopyright 木亚瑟
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
; UAC 判定完成后，把最终驻留进程提升到高优先级。
try ProcessSetPriority("High")
#Include <Keys>
#Include <JSON>
#Include <Time>
#Include <GetPressKey>
#Include <GdiPlusSession>
#Include <GuiTheme>
#Include ./gui/GuiText.ahk
#Include ./core/SendIP.ahk
#Include ./core/GetKeycode.ahk
#Include ./core/Config.ahk
EnsureConfigInitialized()
#Include ./core/SessionState.ahk
SessionState.InitFromLastPreset()
#Include ./core/PresetManager.ahk
#Include ./core/PresetExFeatures.ahk
#Include ./core/FeatureModuleRegistry.ahk
#Include ./core/GameContext.ahk
#Include ./core/KeyRouter.ahk
#Include ./core/AutoFireController.ahk
#Include ./core/PresetRecognition.ahk
#Include ./gui/main/Main.ahk
#Include ./gui/dialogs/QuickSwitch.ahk
#Include ./gui/dialogs/Setting.ahk
#Include ./gui/ExText.ahk
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
#Include ./gui/dialogs/PresetAutoSwitch.ahk
#Include ./gui/ex/PresetSkillIcon.ahk
#Include ./core/AppBootstrap.ahk

AppBootstrap.EnableHighTimerResolution()

;@Ahk2Exe-IgnoreBegin
#Include <Log>
; 需要调试时再取消下一行注释。
; Log()
;@Ahk2Exe-IgnoreEnd

AppBootstrap.Run()



