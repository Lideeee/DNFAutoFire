#Requires AutoHotkey v2.0
#Include ./ExWindowHost.ahk

global gJianZongGui := Gui("+ToolWindow -Theme")
global gJianZongCtrls := Map()

GuiTheme_Apply(gJianZongGui)

gJianZongGui.OnEvent("Escape", JianZongGuiEscape)
gJianZongGui.OnEvent("Close", JianZongGuiClose)

gJianZongGui.Add("Text", "x14 y48 w110 h24 +0x200", ExText.JianZongDelayLabel())
gJianZongCtrls["JianZongDelay"] := gJianZongGui.Add("Edit", "vJianZongDelay x126 y48 w72 h24 +Number -E0x200 Border")
gJianZongGui.Add("Text", "x14 y80 w110 h24 +0x200", ExText.JianZongSkillKeyLabel())
gJianZongCtrls["JianZongSkillKey"] := gJianZongGui.Add("Edit", "vJianZongSkillKey x126 y80 w72 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gJianZongCtrls["JianZongSkillKey"], GetKeycode.AfterCaptureEdit.Bind(gJianZongCtrls["JianZongSkillKey"]))
GuiTheme_HRule(gJianZongGui, 14, 118, 302)
GuiTheme_FlatBtn(gJianZongGui, "x89 y128 w152 h34", ExText.SaveButton(), JianZongSave, true)
GuiTheme_FlatBtnSmall(gJianZongGui, "x290 y10 w26 h26", GuiText.HelpButton(), JianZongHelp)

JianZongGetCtrl(name) {
    global gJianZongCtrls
    return gJianZongCtrls.Has(name) ? gJianZongCtrls[name] : ""
}

ShowGuiJianZong(*) {
    ExWindowHost.ShowOwned(gJianZongGui, ExText.JianZongTitle(), "w330 h188")
    JianZongLoadConfig()
}

HideGuiJianZong() {
    ExWindowHost.HideOwned(gJianZongGui)
}

JianZongGuiEscape(*) {
    HideGuiJianZong()
}

JianZongGuiClose(*) {
    HideGuiJianZong()
}

JianZongHelp(*) {
    MsgBox(ExText.JianZongHelp(), ExText.JianZongHelpTitle(), "Icon!")
}

JianZongSave(*) {
    JianZongSaveConfig()
    HideGuiJianZong()
}

JianZongSaveConfig() {
    delay := Round((Trim(JianZongGetCtrl("JianZongDelay").Text) = "" ? 200 : JianZongGetCtrl("JianZongDelay").Text) + 0)
    if (delay < 20) {
        delay := 20
    } else if (delay > 3000) {
        delay := 3000
    }
    JianZongGetCtrl("JianZongDelay").Text := delay
    SavePreset(GetNowSelectPreset(), "JianZongSkillKey", JianZongGetCtrl("JianZongSkillKey").Text)
    SavePreset(GetNowSelectPreset(), "JianZongDelay", delay)
}

JianZongLoadConfig() {
    sk := GetKeycode.CanonMainKey(Trim(LoadPreset(GetNowSelectPreset(), "JianZongSkillKey", "A")))
    JianZongGetCtrl("JianZongSkillKey").Text := sk != "" ? sk : "A"
    delay := Round(LoadPreset(GetNowSelectPreset(), "JianZongDelay", 200) + 0)
    if (delay < 20) {
        delay := 20
    } else if (delay > 3000) {
        delay := 3000
    }
    JianZongGetCtrl("JianZongDelay").Text := delay
}

