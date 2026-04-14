#Requires AutoHotkey v2.0

global gAutoRunGui := Gui("+ToolWindow")
global gAutoRunCtrls := Map()

gAutoRunGui.OnEvent("Escape", AutoRunGuiEscape)
gAutoRunGui.OnEvent("Close", AutoRunGuiClose)

gAutoRunGui.Add("Text", "x8 y8 w80 h20 +0x200", "左方向键")
gAutoRunCtrls["AutoRunLeftKey"] := gAutoRunGui.Add("Edit", "vAutoRunLeftKey x8 y32 w80 h20 +ReadOnly -WantCtrlA")
gAutoRunGui.Add("Button", "x8 y56 w80 h22", "设置按键").OnEvent("Click", AutoRunSetLeftKey)

gAutoRunGui.Add("Text", "x96 y8 w80 h20 +0x200", "右方向键")
gAutoRunCtrls["AutoRunRightKey"] := gAutoRunGui.Add("Edit", "vAutoRunRightKey x96 y32 w80 h20 +ReadOnly -WantCtrlA")
gAutoRunGui.Add("Button", "x96 y56 w80 h22", "设置按键").OnEvent("Click", AutoRunSetRightKey)

gAutoRunGui.Add("Button", "x96 y86 w80 h28", "保存").OnEvent("Click", AutoRunSave)
gAutoRunGui.Add("Button", "x158 y8 w18 h18", "?").OnEvent("Click", AutoRunHelp)

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
    gAutoRunGui.Show("w184 h122")
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

AutoRunSetLeftKey(*) {
    AutoRunGetCtrl("AutoRunLeftKey").Text := GetPressKey()
}

AutoRunSetRightKey(*) {
    AutoRunGetCtrl("AutoRunRightKey").Text := GetPressKey()
}

AutoRunSave(*) {
    SavePreset(GetNowSelectPreset(), "AutoRunLeftKey", AutoRunGetCtrl("AutoRunLeftKey").Text)
    SavePreset(GetNowSelectPreset(), "AutoRunRightKey", AutoRunGetCtrl("AutoRunRightKey").Text)
    HideGuiAutoRun()
}

AutoRunLoadConfig() {
    AutoRunGetCtrl("AutoRunLeftKey").Text := LoadPreset(GetNowSelectPreset(), "AutoRunLeftKey", "Left")
    AutoRunGetCtrl("AutoRunRightKey").Text := LoadPreset(GetNowSelectPreset(), "AutoRunRightKey", "Right")
}
