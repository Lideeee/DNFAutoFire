#Requires AutoHotkey v2.0

global gSettingGui := Gui("-MinimizeBox -MaximizeBox -Theme")
global gSettingCtrls := Map()

gSettingGui.OnEvent("Escape", SettingGuiEscape)
gSettingGui.OnEvent("Close", SettingGuiClose)

gSettingCtrls["Tab"] := gSettingGui.Add("Tab3", "x0 y0 w380 h200", ["通用设置", "帮助说明", "关于"])
gSettingCtrls["Tab"].UseTab("通用设置")
gSettingCtrls["SettingAutoStart"] := gSettingGui.Add("CheckBox", "vSettingAutoStart x16 y32 h20", "软件打开后自动启动连发")
gSettingCtrls["SettingOnSystemStart"] := gSettingGui.Add("CheckBox", "vSettingOnSystemStart x16 y54 h20", "开机后自动启动")
gSettingCtrls["SettingBlockWin"] := gSettingGui.Add("CheckBox", "vSettingBlockWin x16 y76 h20", "游戏内屏蔽Win键")
gSettingCtrls["SettingAutoPresetSwitch"] := gSettingGui.Add("CheckBox", "vSettingAutoPresetSwitch x16 y98 h20 Checked0", "自动识别")
gSettingGui.Add("Button", "x16 y120 w200 h26", "自动识别设置").OnEvent("Click", ShowGuiPresetAutoSwitch)
gSettingGui.Add("Button", "x290 y152 w80 h40", "保存").OnEvent("Click", SettingSave)
gSettingCtrls["Tab"].UseTab("帮助说明")
gSettingGui.Add("Text", "x16 y32 w352 h190", "如何使用DAF连发工具")
gSettingCtrls["Tab"].UseTab("关于")
gSettingGui.Add("Text", "x16 y32 w352 h120", "作者： 某亚瑟`n图标： Ousumu")
gSettingGui.Add("Text", "x16 y60 w352 h24 +0x200", "源码：")
gSettingGui.Add("Link", "x16 y82 w352 h24", "<a href=`"https://github.com/mouyase/DNFAutoFire`">https://github.com/mouyase/DNFAutoFire</a>")
gSettingGui.Add("Text", "x16 y104 w352 h24 +0x200", "原帖地址：")
gSettingGui.Add("Link", "x16 y126 w352 h24", "<a href=`"https://bbs.colg.cn/thread-8894989-1-1.html`">https://bbs.colg.cn/thread-8894989-1-1.html</a>")
gSettingGui.Add("Text", "x16 y148 w352 h24 +0x200", "二次开发：")
gSettingGui.Add("Link", "x16 y170 w352 h24", "<a href=`"https://github.com/Lideeee/DNFAutoFire`">https://github.com/Lideeee/DNFAutoFire</a>")
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
    global gMainGui, gSettingGui
    try PresetRecognition_CancelPending()
    DisableGuiMain()
    if IsObject(gMainGui) {
        gSettingGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gSettingGui.Title := "软件设置"
    gSettingGui.Show("w380 h200")
    SettingLoad()
}

; 与 ShowGuiSetting 相同，但打开后切到「关于」标签（Tab3 第三页）
ShowGuiSettingAbout(*) {
    global gMainGui, gSettingGui
    try PresetRecognition_CancelPending()
    DisableGuiMain()
    if IsObject(gMainGui) {
        gSettingGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gSettingGui.Title := "软件设置"
    gSettingGui.Show("w380 h380")
    SettingLoad()
    try SettingGetCtrl("Tab").Value := 3
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
    settingAutoPresetSwitch := SettingGetCtrl("SettingAutoPresetSwitch").Value

    SaveConfig("SettingAutoStart", settingAutoStart)
    SaveConfig("SettingOnSystemStart", settingOnSystemStart)
    SaveConfig("SettingBlockWin", settingBlockWin)
    SaveConfig("SettingAutoPresetSwitch", settingAutoPresetSwitch ? 1 : 0)

    _OnSystemStart := settingOnSystemStart
    _BlockWin := settingBlockWin

    SettingNow()
    HideGuiSetting()
}

SettingLoad() {
    SettingGetCtrl("SettingAutoStart").Value := LoadConfig("SettingAutoStart", false)
    SettingGetCtrl("SettingOnSystemStart").Value := LoadConfig("SettingOnSystemStart", false)
    SettingGetCtrl("SettingBlockWin").Value := LoadConfig("SettingBlockWin", false)
    SettingGetCtrl("SettingAutoPresetSwitch").Value := Trim(LoadConfig("SettingAutoPresetSwitch", "0")) = "1"
}

SettingNow() {
    if (_OnSystemStart) {
        FileCreateShortcut(A_ScriptFullPath, A_Startup "\DAF连发工具.lnk")
    } else {
        try FileDelete(A_Startup "\DAF连发工具.lnk")
    }
    if (_BlockWin) {
        Hotkey("$*LWin", BlockWin, "On")
        Hotkey("$*RWin", BlockWin, "On")
    } else {
        try Hotkey("$*LWin", "Off")
        try Hotkey("$*RWin", "Off")
    }
    PresetRecognition_UpdateHotkeys()
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
