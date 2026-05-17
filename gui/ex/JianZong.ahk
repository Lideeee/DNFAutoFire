#Requires AutoHotkey v2.0

global gJianZongGui := Gui("-MinimizeBox -MaximizeBox")
global gJianZongCtrls := Map()
global gJianZongLayout := ExLayout.Window()

UiApplyWindow(gJianZongGui)
gJianZongGui.OnEvent("Escape", JianZongGuiEscape)
gJianZongGui.OnEvent("Close", JianZongGuiClose)

contentRight := 200
fieldX := 128
fieldW := contentRight - fieldX

UiExPageTitle(gJianZongGui, exText["JianZongPageTitle"], contentRight, gJianZongLayout, JianZongHelp)
UiLabel(gJianZongGui, UiLayoutRect(gJianZongLayout, ExLayout.MarginLeft(), 54, 110, 24), exText["JianZongDelay"])
UiEdit(gJianZongCtrls, gJianZongGui, "JianZongDelay", UiLayoutRect(gJianZongLayout, fieldX, 54, fieldW, 24, "+Number -E0x200 Border"))
UiLabel(gJianZongGui, UiLayoutRect(gJianZongLayout, ExLayout.MarginLeft(), 86, 110, 24), exText["JianZongSkillKey"])
UiEdit(gJianZongCtrls, gJianZongGui, "JianZongSkillKey", UiLayoutRect(gJianZongLayout, fieldX, 86, fieldW, 24, "+ReadOnly -WantCtrlA -E0x200 Border"))
UiPlainButton(gJianZongGui, UiLayoutRect(gJianZongLayout, ExLayout.MarginLeft(), 118, contentRight - ExLayout.MarginLeft(), 26), exText["SetKey"], JianZongSetSkillKey)
UiPlainButton(gJianZongGui, UiExSaveButtonRect(gJianZongLayout, 152, contentRight, 32), exText["CommonSave"], JianZongSave, "primary")

JianZongGetCtrl(name) {
    global gJianZongCtrls
    return gJianZongCtrls.Has(name) ? gJianZongCtrls[name] : ""
}

ShowGuiJianZong(*) {
    global gMainGui, gJianZongGui, gJianZongLayout
    if IsObject(gMainGui) {
        gJianZongGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gJianZongGui.Title := exText["JianZongTitle"]
    gJianZongGui.Show("w" gJianZongLayout.Width() " h" gJianZongLayout.Height())
    JianZongLoadConfig()
    DisableGuiMain()
}

HideGuiJianZong() {
    gJianZongGui.Hide()
    EnableGuiMain()
}

JianZongGuiEscape(*) {
    JianZongSave()
}

JianZongGuiClose(*) {
    JianZongSave()
}

JianZongHelp(*) {
    UiHelpMsgBox(exText["JianZongHelp"], exText["JianZongHelpTitle"])
}

JianZongSave(*) {
    JianZongSaveConfig()
    HideGuiJianZong()
}

JianZongSetSkillKey(*) {
    JianZongGetCtrl("JianZongSkillKey").Text := GetPressKey()
}

JianZongSaveConfig() {
    SavePreset(GetNowSelectPreset(), "JianZongSkillKey", JianZongGetCtrl("JianZongSkillKey").Text)
    SavePreset(GetNowSelectPreset(), "JianZongDelay", JianZongGetCtrl("JianZongDelay").Text)
}

JianZongLoadConfig() {
    JianZongGetCtrl("JianZongSkillKey").Text := LoadPreset(GetNowSelectPreset(), "JianZongSkillKey", "A")
    JianZongGetCtrl("JianZongDelay").Text := LoadPreset(GetNowSelectPreset(), "JianZongDelay", "200")
}
