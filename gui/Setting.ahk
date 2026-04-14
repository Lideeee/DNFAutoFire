#Requires AutoHotkey v2.0

global gSettingGui := Gui("-MinimizeBox -MaximizeBox -Theme")
global gSettingCtrls := Map()

gSettingGui.OnEvent("Escape", SettingGuiEscape)
gSettingGui.OnEvent("Close", SettingGuiClose)

gSettingCtrls["Tab"] := gSettingGui.Add("Tab3", "x0 y0 w400 h300", ["通用设置", "帮助说明", "关于"])
gSettingCtrls["Tab"].UseTab("通用设置")
gSettingCtrls["SettingAutoStart"] := gSettingGui.Add("CheckBox", "vSettingAutoStart x16 y32 h20", "软件打开后自动启动连发")
gSettingCtrls["SettingOnSystemStart"] := gSettingGui.Add("CheckBox", "vSettingOnSystemStart x16 y54 h20", "开机后自动启动")
gSettingCtrls["SettingBlockWin"] := gSettingGui.Add("CheckBox", "vSettingBlockWin x16 y76 h20", "游戏内屏蔽Win键")
gSettingGui.Add("Button", "x310 y250 w80 h40", "保存").OnEvent("Click", SettingSave)
gSettingCtrls["Tab"].UseTab("帮助说明")
gSettingGui.Add("Text", "x16 y32 w368 h268", "如何使用DAF连发工具`n`n1、点击窗口中的键盘，将想启动连发的键位变成红色`n2、输入配置名称，保存配置`n3、点击启动连发，即可使用`n`nPS：在游戏中可以打开快速切换窗口，使用上下键和回车可以快速切换已经保存的配置，记得设置快捷键哦`n默认快捷键 Alt + `` （键盘1左边，Tab上边的那个）")
gSettingCtrls["Tab"].UseTab("关于")
gSettingGui.Add("Text", "x16 y32 w368 h120", "作者： 某亚瑟`n图标： Ousumu")
gSettingGui.Add("Text", "x16 y60 w368 h24 +0x200", "源码：")
gSettingGui.Add("Link", "x16 y82 w368 h24", "<a href=`"https://github.com/mouyase/DNFAutoFire`">https://github.com/mouyase/DNFAutoFire</a>")
gSettingGui.Add("Text", "x16 y104 w368 h24 +0x200", "原帖地址：")
gSettingGui.Add("Link", "x16 y126 w368 h24", "<a href=`"https://bbs.colg.cn/thread-8894989-1-1.html`">https://bbs.colg.cn/thread-8894989-1-1.html</a>")
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
    DisableGuiMain()
    if IsObject(gMainGui) {
        gSettingGui.Opt("+Owner" gMainGui.Hwnd)
    }
    gSettingGui.Title := "软件设置"
    gSettingGui.Show("w400 h300")
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

    SaveConfig("SettingAutoStart", settingAutoStart)
    SaveConfig("SettingOnSystemStart", settingOnSystemStart)
    SaveConfig("SettingBlockWin", settingBlockWin)

    _OnSystemStart := settingOnSystemStart
    _BlockWin := settingBlockWin

    SettingNow()
    HideGuiSetting()
}

SettingLoad() {
    SettingGetCtrl("SettingAutoStart").Value := LoadConfig("SettingAutoStart", false)
    SettingGetCtrl("SettingOnSystemStart").Value := LoadConfig("SettingOnSystemStart", false)
    SettingGetCtrl("SettingBlockWin").Value := LoadConfig("SettingBlockWin", false)
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
