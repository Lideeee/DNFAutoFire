#Requires AutoHotkey v2.0

global gXiuLuoGui := Gui("-MinimizeBox -MaximizeBox")
global gXiuLuoCtrls := Map()
global gXiuLuoLayout := ExLayout.Window()

UiApplyWindow(gXiuLuoGui)
gXiuLuoGui.OnEvent("Escape", XiuLuoGuiEscape)
gXiuLuoGui.OnEvent("Close", XiuLuoGuiClose)

contentRight := 238
fieldX := 98
fieldW := contentRight - fieldX

UiExPageTitle(gXiuLuoGui, exText["XiuLuoPageTitle"], contentRight, gXiuLuoLayout, XiuLuoHelp)
UiLabel(gXiuLuoGui, UiLayoutRect(gXiuLuoLayout, ExLayout.MarginLeft(), 54, 76, 24), exText["XiuLuoTriggerKey"])
UiEdit(gXiuLuoCtrls, gXiuLuoGui, "XiuLuoTriggerKey", UiLayoutRect(gXiuLuoLayout, fieldX, 54, fieldW, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gXiuLuoGui, UiLayoutRect(gXiuLuoLayout, fieldX, 82, fieldW, 24), exText["SetKey"], XiuLuoSetTriggerKey)

UiLabel(gXiuLuoGui, UiLayoutRect(gXiuLuoLayout, ExLayout.MarginLeft(), 118, 76, 24), exText["XiuLuoXKey"])
UiEdit(gXiuLuoCtrls, gXiuLuoGui, "XiuLuoXKey", UiLayoutRect(gXiuLuoLayout, fieldX, 118, fieldW, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gXiuLuoGui, UiLayoutRect(gXiuLuoLayout, fieldX, 146, fieldW, 24), exText["SetKey"], XiuLuoSetXKey)

UiLabel(gXiuLuoGui, UiLayoutRect(gXiuLuoLayout, ExLayout.MarginLeft(), 182, 76, 24), exText["XiuLuoWaveKey1"])
UiEdit(gXiuLuoCtrls, gXiuLuoGui, "XiuLuoWaveKey1", UiLayoutRect(gXiuLuoLayout, fieldX, 182, fieldW, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gXiuLuoGui, UiLayoutRect(gXiuLuoLayout, fieldX, 210, fieldW, 24), exText["SetKey"], XiuLuoSetWaveKey1)

UiLabel(gXiuLuoGui, UiLayoutRect(gXiuLuoLayout, ExLayout.MarginLeft(), 246, 76, 24), exText["XiuLuoWaveKey2"])
UiEdit(gXiuLuoCtrls, gXiuLuoGui, "XiuLuoWaveKey2", UiLayoutRect(gXiuLuoLayout, fieldX, 246, fieldW, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gXiuLuoGui, UiLayoutRect(gXiuLuoLayout, fieldX, 274, fieldW, 24), exText["SetKey"], XiuLuoSetWaveKey2)

UiLabel(gXiuLuoGui, UiLayoutRect(gXiuLuoLayout, ExLayout.MarginLeft(), 310, 76, 24), exText["XiuLuoWaveKey3"])
UiEdit(gXiuLuoCtrls, gXiuLuoGui, "XiuLuoWaveKey3", UiLayoutRect(gXiuLuoLayout, fieldX, 310, fieldW, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gXiuLuoGui, UiLayoutRect(gXiuLuoLayout, fieldX, 338, fieldW, 24), exText["SetKey"], XiuLuoSetWaveKey3)

UiPlainButton(gXiuLuoGui, UiExSaveButtonRect(gXiuLuoLayout, 382, contentRight, 30), exText["CommonSave"], XiuLuoSave, "primary")

XiuLuoGetCtrl(name) {
    global gXiuLuoCtrls
    return gXiuLuoCtrls.Has(name) ? gXiuLuoCtrls[name] : ""
}

ShowGuiXiuLuo(*) {
    global gMainGui, gXiuLuoGui, gXiuLuoLayout
    if IsObject(gMainGui) {
        gXiuLuoGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gXiuLuoGui.Title := exText["XiuLuoTitle"]
    gXiuLuoGui.Show("w" gXiuLuoLayout.Width() " h" gXiuLuoLayout.Height())
    XiuLuoLoadConfig()
    DisableGuiMain()
}

HideGuiXiuLuo() {
    gXiuLuoGui.Hide()
    EnableGuiMain()
}

XiuLuoGuiEscape(*) {
    XiuLuoSave()
}

XiuLuoGuiClose(*) {
    XiuLuoSave()
}

XiuLuoHelp(*) {
    UiHelpMsgBox(exText["XiuLuoHelp"], exText["XiuLuoHelpTitle"])
}

XiuLuoSave(*) {
    XiuLuoSaveConfig()
    HideGuiXiuLuo()
}

XiuLuoSetTriggerKey(*) {
    XiuLuoGetCtrl("XiuLuoTriggerKey").Text := GetPressKey()
}

XiuLuoSetXKey(*) {
    XiuLuoGetCtrl("XiuLuoXKey").Text := GetPressKey()
}

XiuLuoSetWaveKey1(*) {
    XiuLuoGetCtrl("XiuLuoWaveKey1").Text := GetPressKey()
}

XiuLuoSetWaveKey2(*) {
    XiuLuoGetCtrl("XiuLuoWaveKey2").Text := GetPressKey()
}

XiuLuoSetWaveKey3(*) {
    XiuLuoGetCtrl("XiuLuoWaveKey3").Text := GetPressKey()
}

XiuLuoSaveConfig() {
    SavePreset(GetNowSelectPreset(), "XiuLuoTriggerKey", XiuLuoGetCtrl("XiuLuoTriggerKey").Text)
    SavePreset(GetNowSelectPreset(), "XiuLuoXKey", XiuLuoGetCtrl("XiuLuoXKey").Text)
    SavePreset(GetNowSelectPreset(), "XiuLuoWaveKey1", XiuLuoGetCtrl("XiuLuoWaveKey1").Text)
    SavePreset(GetNowSelectPreset(), "XiuLuoWaveKey2", XiuLuoGetCtrl("XiuLuoWaveKey2").Text)
    SavePreset(GetNowSelectPreset(), "XiuLuoWaveKey3", XiuLuoGetCtrl("XiuLuoWaveKey3").Text)
}

XiuLuoLoadConfig() {
    XiuLuoGetCtrl("XiuLuoTriggerKey").Text := LoadPreset(GetNowSelectPreset(), "XiuLuoTriggerKey", "")
    XiuLuoGetCtrl("XiuLuoXKey").Text := LoadPreset(GetNowSelectPreset(), "XiuLuoXKey", "X")
    XiuLuoGetCtrl("XiuLuoWaveKey1").Text := LoadPreset(GetNowSelectPreset(), "XiuLuoWaveKey1", "1")
    XiuLuoGetCtrl("XiuLuoWaveKey2").Text := LoadPreset(GetNowSelectPreset(), "XiuLuoWaveKey2", "2")
    XiuLuoGetCtrl("XiuLuoWaveKey3").Text := LoadPreset(GetNowSelectPreset(), "XiuLuoWaveKey3", "3")
}
