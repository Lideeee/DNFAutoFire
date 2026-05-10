#Requires AutoHotkey v2.0
#Include ./ExWindowHost.ahk

global gAutoRunGui := Gui("+ToolWindow -Theme")
global gAutoRunCtrls := Map()

GuiTheme_Apply(gAutoRunGui)

gAutoRunGui.OnEvent("Escape", AutoRunGuiEscape)
gAutoRunGui.OnEvent("Close", AutoRunGuiClose)

gAutoRunGui.Add("Text", "x16 y54 w72 h26 +0x200", ExText.AutoRunLeftLabel())
gAutoRunCtrls["AutoRunLeftKey"] := gAutoRunGui.Add("Edit", "vAutoRunLeftKey x96 y54 w168 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gAutoRunCtrls["AutoRunLeftKey"], GetKeycode.AfterCaptureEdit.Bind(gAutoRunCtrls["AutoRunLeftKey"]))
gAutoRunGui.Add("Text", "x16 y94 w72 h26 +0x200", ExText.AutoRunRightLabel())
gAutoRunCtrls["AutoRunRightKey"] := gAutoRunGui.Add("Edit", "vAutoRunRightKey x96 y94 w168 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gAutoRunCtrls["AutoRunRightKey"], GetKeycode.AfterCaptureEdit.Bind(gAutoRunCtrls["AutoRunRightKey"]))
GuiTheme_HRule(gAutoRunGui, 16, 138, 358)
GuiTheme_FlatBtn(gAutoRunGui, "x16 y144 w358 h36", ExText.SaveButton(), AutoRunSave, true)
GuiTheme_FlatBtnSmall(gAutoRunGui, "x348 y16 w26 h26", GuiText.HelpButton(), AutoRunHelp)

AutoRunGetCtrl(name) {
    global gAutoRunCtrls
    return gAutoRunCtrls.Has(name) ? gAutoRunCtrls[name] : ""
}

ShowGuiAutoRun(*) {
    ExWindowHost.ShowOwnedFit(gAutoRunGui, ExText.AutoRunTitle())
    AutoRunLoadConfig()
}

HideGuiAutoRun() {
    ExWindowHost.HideOwned(gAutoRunGui)
}

AutoRunGuiEscape(*) {
    HideGuiAutoRun()
}

AutoRunGuiClose(*) {
    HideGuiAutoRun()
}

AutoRunHelp(*) {
    MsgBox(ExText.AutoRunHelp(), ExText.AutoRunHelpTitle(), "Icon!")
}

AutoRunSave(*) {
    SavePreset(GetNowSelectPreset(), "AutoRunLeftKey", AutoRunGetCtrl("AutoRunLeftKey").Text)
    SavePreset(GetNowSelectPreset(), "AutoRunRightKey", AutoRunGetCtrl("AutoRunRightKey").Text)
    HideGuiAutoRun()
}

AutoRunLoadConfig() {
    l := GetKeycode.CanonMainKey(Trim(LoadPreset(GetNowSelectPreset(), "AutoRunLeftKey", "Left")))
    r := GetKeycode.CanonMainKey(Trim(LoadPreset(GetNowSelectPreset(), "AutoRunRightKey", "Right")))
    AutoRunGetCtrl("AutoRunLeftKey").Text := l != "" ? l : "Left"
    AutoRunGetCtrl("AutoRunRightKey").Text := r != "" ? r : "Right"
}
