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

gSettingCtrls["NavGeneral"] := GuiTheme_FlatBtn(gSettingGui, "x16 y14 w118 h28", GuiText.SettingNavGeneral(), (*) => SettingShowPage(1), false)
gSettingCtrls["NavAbout"] := GuiTheme_FlatBtn(gSettingGui, "x142 y14 w118 h28", GuiText.SettingNavAbout(), (*) => SettingShowPage(2), false)

gSettingCtrls["SettingAutoStart"] := gSettingGui.Add("CheckBox", "vSettingAutoStart x16 y52 h22", GuiText.SettingAutoStart())
__SettingGeneralCtrls.Push(gSettingCtrls["SettingAutoStart"])
gSettingCtrls["SettingOnSystemStart"] := gSettingGui.Add("CheckBox", "vSettingOnSystemStart x16 y80 h22", GuiText.SettingOnSystemStart())
__SettingGeneralCtrls.Push(gSettingCtrls["SettingOnSystemStart"])
gSettingCtrls["SettingBlockWin"] := gSettingGui.Add("CheckBox", "vSettingBlockWin x16 y108 h22", GuiText.SettingBlockWin())
__SettingGeneralCtrls.Push(gSettingCtrls["SettingBlockWin"])
__SettingGeneralCtrls.Push(gSettingGui.Add("Text", "x16 y136 w200 h20 +0x200", GuiText.SettingQuickSwitchLabel()))
gSettingCtrls["SettingQuickChangeHotKey"] := gSettingGui.Add("Hotkey", "vSettingQuickChangeHotKey x16 y158 w200 h22 -E0x200 Border")
gSettingCtrls["SettingQuickChangeHotKey"].OnEvent("Change", SettingQuickChangeHotKeyChanged)
__SettingGeneralCtrls.Push(gSettingCtrls["SettingQuickChangeHotKey"])
gSettingCtrls["SettingAutoPresetSwitch"] := gSettingGui.Add("CheckBox", "vSettingAutoPresetSwitch x16 y186 h22 Checked0", GuiText.SettingAutoPresetSwitch())
__SettingGeneralCtrls.Push(gSettingCtrls["SettingAutoPresetSwitch"])
__btnSettingPreset := GuiTheme_FlatBtn(gSettingGui, "x16 y214 w200 h30", GuiText.SettingAutoPresetButton(), ShowGuiPresetAutoSwitch, false)
__SettingGeneralCtrls.Push(__btnSettingPreset)
__SettingGeneralCtrls.Push(gSettingGui.Add("Text", "x16 y252 w352 h78", GuiText.SettingAutoPresetHelp()))
__btnSettingSave := GuiTheme_FlatBtn(gSettingGui, "x278 y336 w88 h40", GuiText.SaveButton(), SettingSave, true)
__SettingGeneralCtrls.Push(__btnSettingSave)

__SettingAboutCtrls.Push(gSettingGui.Add("Text", "x16 y52 w352 h52", GuiText.AboutApp()))
__SettingAboutCtrls.Push(gSettingGui.Add("Text", "x16 y100 w352 h22 +0x200", GuiText.AboutOriginalPost()))
__SettingAboutCtrls.Push(gSettingGui.Add("Link", "x16 y122 w352 h40", "<a href=`"https://bbs.colg.cn/thread-8894989-1-1.html`">https://bbs.colg.cn/thread-8894989-1-1.html</a>"))
__SettingAboutCtrls.Push(gSettingGui.Add("Text", "x16 y170 w352 h22 +0x200", GuiText.AboutReleasePost()))
__SettingAboutCtrls.Push(gSettingGui.Add("Link", "x16 y192 w352 h40", "<a href=`"https://bbs.colg.cn/forum.php?mod=viewthread&tid=9593722`">https://bbs.colg.cn/forum.php?mod=viewthread&tid=9593722</a>"))

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
