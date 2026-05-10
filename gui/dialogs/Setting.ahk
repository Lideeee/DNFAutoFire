#Requires AutoHotkey v2.0

#Include ./SettingController.ahk

global gSettingGui := Gui("-MinimizeBox -MaximizeBox -Theme")
global gSettingCtrls := Map()
global __SettingGeneralCtrls := []
global __SettingAboutCtrls := []
global gSettingSuppressQuickKeyChange := false

GuiTheme_Apply(gSettingGui)

gSettingGui.OnEvent("Escape", SettingGuiEscape)
gSettingGui.OnEvent("Close", SettingGuiClose)

gSettingCtrls["NavGeneral"] := GuiTheme_FlatBtn(gSettingGui, "x16 y16 w118 h28", GuiText.SettingNavGeneral(), (*) => SettingShowPage(1), false)
gSettingCtrls["NavAbout"] := GuiTheme_FlatBtn(gSettingGui, "x142 y16 w118 h28", GuiText.SettingNavAbout(), (*) => SettingShowPage(2), false)

gSettingCtrls["SettingAutoStart"] := gSettingGui.Add("CheckBox", "vSettingAutoStart x16 y56 h22", GuiText.SettingAutoStart())
__SettingGeneralCtrls.Push(gSettingCtrls["SettingAutoStart"])
gSettingCtrls["SettingOnSystemStart"] := gSettingGui.Add("CheckBox", "vSettingOnSystemStart x16 y84 h22", GuiText.SettingOnSystemStart())
__SettingGeneralCtrls.Push(gSettingCtrls["SettingOnSystemStart"])
gSettingCtrls["SettingBlockWin"] := gSettingGui.Add("CheckBox", "vSettingBlockWin x16 y112 h22", GuiText.SettingBlockWin())
__SettingGeneralCtrls.Push(gSettingCtrls["SettingBlockWin"])
__SettingGeneralCtrls.Push(gSettingGui.Add("Text", "x16 y140 w200 h20 +0x200", GuiText.SettingQuickSwitchLabel()))
gSettingCtrls["SettingQuickChangeHotKey"] := gSettingGui.Add("Hotkey", "vSettingQuickChangeHotKey x16 y162 w200 h22 -E0x200 Border")
gSettingCtrls["SettingQuickChangeHotKey"].OnEvent("Change", SettingQuickChangeHotKeyChanged)
__SettingGeneralCtrls.Push(gSettingCtrls["SettingQuickChangeHotKey"])
__btnSettingSave := GuiTheme_FlatBtn(gSettingGui, "x278 y226 w88 h40", GuiText.SaveButton(), SettingSave, true)
__SettingGeneralCtrls.Push(__btnSettingSave)

__SettingAboutCtrls.Push(gSettingGui.Add("Text", "x16 y56 w352 h52", GuiText.AboutApp()))
__SettingAboutCtrls.Push(gSettingGui.Add("Text", "x16 y104 w352 h22 +0x200", GuiText.AboutOriginalPost()))
__SettingAboutCtrls.Push(gSettingGui.Add("Link", "x16 y126 w352 h40", "<a href=`"https://bbs.colg.cn/thread-8894989-1-1.html`">https://bbs.colg.cn/thread-8894989-1-1.html</a>"))
__SettingAboutCtrls.Push(gSettingGui.Add("Text", "x16 y174 w352 h22 +0x200", GuiText.AboutReleasePost()))
__SettingAboutCtrls.Push(gSettingGui.Add("Link", "x16 y196 w352 h40", "<a href=`"https://bbs.colg.cn/forum.php?mod=viewthread&tid=9593722`">https://bbs.colg.cn/forum.php?mod=viewthread&tid=9593722</a>"))

for ctrl in __SettingAboutCtrls {
    ctrl.Visible := false
}

SettingShowPage(page) => SettingController.ShowPage(page)

SettingGetCtrl(name) {
    global gSettingCtrls
    return gSettingCtrls.Has(name) ? gSettingCtrls[name] : ""
}

SettingGuiEscape(*) => SettingController.Hide()
SettingGuiClose(*) => SettingController.Hide()
ShowGuiSetting(*) => SettingController.Show()
ShowGuiSettingAbout(*) => SettingController.ShowAbout()
HideGuiSetting() => SettingController.Hide()
SettingSave(*) => SettingController.Save()
SettingLoad() => SettingController.Load()
SettingQuickChangeHotKeyChanged(*) => SettingController.OnQuickChangeHotKeyChanged()
SettingNow() => SettingController.ApplyNow()
SettingBlockWin(*) => SettingController.BlockWin()

global _AutoStart := LoadConfig("SettingAutoStart", false)
global _OnSystemStart := LoadConfig("SettingOnSystemStart", false)
global _BlockWin := LoadConfig("SettingBlockWin", false)

if (_BlockWin) {
    Hotkey("$*LWin", SettingBlockWin, "On")
    Hotkey("$*RWin", SettingBlockWin, "On")
}
