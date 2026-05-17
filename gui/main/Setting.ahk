#Requires AutoHotkey v2.0

global gSettingGui := Gui("-MinimizeBox -MaximizeBox")
global gSettingCtrls := Map()
global gSettingLayout := SettingLayout.Window()

gSettingGui.OnEvent("Escape", SettingGuiEscape)
gSettingGui.OnEvent("Close", SettingGuiClose)

gSettingCtrls["Tab"] := gSettingGui.Add("Tab3", UiLayoutRect(gSettingLayout, 0, 0, SettingLayout.TabWidth(), SettingLayout.TabHeight()), [MainText["SettingTabGeneral"], MainText["SettingTabHelp"], MainText["SettingTabAbout"]])
gSettingCtrls["Tab"].UseTab(MainText["SettingTabGeneral"])
gSettingCtrls["SettingAutoStart"] := gSettingGui.Add("CheckBox", "vSettingAutoStart x16 y32 h20", MainText["SettingAutoStart"])
gSettingCtrls["SettingOnSystemStart"] := gSettingGui.Add("CheckBox", "vSettingOnSystemStart x16 y54 h20", MainText["SettingOnSystemStart"])
gSettingCtrls["SettingBlockWin"] := gSettingGui.Add("CheckBox", "vSettingBlockWin x16 y76 h20", MainText["SettingBlockWin"])
gSettingCtrls["SettingSubprocessErrorLog"] := gSettingGui.Add("CheckBox", "vSettingSubprocessErrorLog x16 y98 h20", MainText["SettingSubprocessErrorLog"])
gSettingGui.Add("Button", "x310 y250 w80 h40", MainText["Save"]).OnEvent("Click", SettingSave)
gSettingCtrls["Tab"].UseTab(MainText["SettingTabHelp"])
gSettingGui.Add("Text", "x16 y32 w368 h268", MainText["SettingHelp"])
gSettingCtrls["Tab"].UseTab(MainText["SettingTabAbout"])
gSettingGui.Add("Text", "x16 y32 w368 h120", MainText["AboutCredits"])
gSettingGui.Add("Text", "x16 y60 w368 h24 +0x200", MainText["Source"])
gSettingGui.Add("Link", "x16 y82 w368 h24", "<a href=`"" MainText["SourceUrl"] "`">" MainText["SourceUrl"] "</a>")
gSettingGui.Add("Text", "x16 y104 w368 h24 +0x200", MainText["OriginalPost"])
gSettingGui.Add("Link", "x16 y126 w368 h24", "<a href=`"" MainText["OriginalPostUrl"] "`">" MainText["OriginalPostUrl"] "</a>")
gSettingCtrls["Tab"].UseTab()

SettingGetCtrl(name) {
    global gSettingCtrls
    return gSettingCtrls.Has(name) ? gSettingCtrls[name] : ""
}

SettingGuiEscape(*) {
    HideGuiSetting()
}

SettingGuiClose(*) {
    HideGuiSetting()
}

ShowGuiSetting(*) {
    global gMainGui, gSettingGui, gSettingLayout
    DisableGuiMain()
    if IsObject(gMainGui) {
        gSettingGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gSettingGui.Title := MainText["Setting"]
    gSettingGui.Show("w" gSettingLayout.Width() " h" gSettingLayout.Height())
    SettingLoad()
}

HideGuiSetting() {
    gSettingGui.Hide()
    EnableGuiMain()
}

SettingSave(*) {
    global _OnSystemStart, _BlockWin
    settingAutoStart := SettingGetCtrl("SettingAutoStart").Value
    settingOnSystemStart := SettingGetCtrl("SettingOnSystemStart").Value
    settingBlockWin := SettingGetCtrl("SettingBlockWin").Value
    settingSubprocessErrorLog := SettingGetCtrl("SettingSubprocessErrorLog").Value

    SaveConfig("SettingAutoStart", settingAutoStart)
    SaveConfig("SettingOnSystemStart", settingOnSystemStart)
    SaveConfig("SettingBlockWin", settingBlockWin)
    SaveConfig("SettingSubprocessErrorLog", settingSubprocessErrorLog)

    _OnSystemStart := settingOnSystemStart
    _BlockWin := settingBlockWin

    SettingNow()
    HideGuiSetting()
}

SettingLoad() {
    SettingGetCtrl("SettingAutoStart").Value := LoadConfig("SettingAutoStart", false)
    SettingGetCtrl("SettingOnSystemStart").Value := LoadConfig("SettingOnSystemStart", false)
    SettingGetCtrl("SettingBlockWin").Value := LoadConfig("SettingBlockWin", false)
    SettingGetCtrl("SettingSubprocessErrorLog").Value := LoadConfig("SettingSubprocessErrorLog", false)
}

SettingNow() {
    if (_OnSystemStart) {
        FileCreateShortcut(A_ScriptFullPath, A_Startup "\" MainText["StartupShortcutName"])
    } else {
        try FileDelete(A_Startup "\" MainText["StartupShortcutName"])
    }
    if (_BlockWin) {
        Hotkey("$*LWin", BlockWin, "On")
        Hotkey("$*RWin", BlockWin, "On")
    } else {
        try Hotkey("$*LWin", "Off")
        try Hotkey("$*RWin", "Off")
    }
}

BlockWin(*) {
}

global _AutoStart := LoadConfig("SettingAutoStart", false)
global _OnSystemStart := LoadConfig("SettingOnSystemStart", false)
global _BlockWin := LoadConfig("SettingBlockWin", false)

if (_BlockWin) {
    Hotkey("$*LWin", BlockWin, "On")
    Hotkey("$*RWin", BlockWin, "On")
}
