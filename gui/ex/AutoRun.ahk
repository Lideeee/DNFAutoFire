#Requires AutoHotkey v2.0

global gAutoRunGui := Gui("+ToolWindow -Theme")
global gAutoRunCtrls := Map()

GuiTheme_Apply(gAutoRunGui)

gAutoRunGui.OnEvent("Escape", AutoRunGuiEscape)
gAutoRunGui.OnEvent("Close", AutoRunGuiClose)

gAutoRunGui.Add("Text", "x14 y48 w72 h26 +0x200", "左方向键")
gAutoRunCtrls["AutoRunLeftKey"] := gAutoRunGui.Add("Edit", "vAutoRunLeftKey x94 y48 w168 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gAutoRunCtrls["AutoRunLeftKey"], GetKeycode.AfterCaptureEdit.Bind(gAutoRunCtrls["AutoRunLeftKey"]))
gAutoRunGui.Add("Text", "x14 y88 w72 h26 +0x200", "右方向键")
gAutoRunCtrls["AutoRunRightKey"] := gAutoRunGui.Add("Edit", "vAutoRunRightKey x94 y88 w168 h24 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gAutoRunCtrls["AutoRunRightKey"], GetKeycode.AfterCaptureEdit.Bind(gAutoRunCtrls["AutoRunRightKey"]))
GuiTheme_HRule(gAutoRunGui, 14, 132, 362)
GuiTheme_FlatBtn(gAutoRunGui, "x14 y142 w362 h36", "保存", AutoRunSave, true)
GuiTheme_FlatBtnSmall(gAutoRunGui, "x350 y14 w26 h26", "?", AutoRunHelp)

AutoRunGetCtrl(name) {
    global gAutoRunCtrls
    return gAutoRunCtrls.Has(name) ? gAutoRunCtrls[name] : ""
}

ShowGuiAutoRun(*) {
    global gMainGui, gAutoRunGui
    if IsObject(gMainGui) {
        gAutoRunGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gAutoRunGui.Title := "自动奔跑设置"
    gAutoRunGui.Show("w390 h196")
    AutoRunLoadConfig()
    DisableGuiMain()
}

HideGuiAutoRun() {
    gAutoRunGui.Hide()
    EnableGuiMain()
}

AutoRunGuiEscape(*) {
    HideGuiAutoRun()
}

AutoRunGuiClose(*) {
    HideGuiAutoRun()
}

AutoRunHelp(*) {
    MsgBox("设置自动奔跑要监听的左右键。`n如果游戏里方向键不是 Left/Right，请改成你的实际按键后保存。", "自动奔跑说明", "Iconi")
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
