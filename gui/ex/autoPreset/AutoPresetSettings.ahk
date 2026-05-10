#Requires AutoHotkey v2.0

#Include ./AutoPresetSettingsCtrl.ahk

global gAutoPresetSettingsMargin := 16
global gAutoPresetSettingsListW := 150
global gAutoPresetSettingsListH := 170
global gAutoPresetSettingsColumnGap := 22
global gAutoPresetSettingsRightW := 150
global gAutoPresetSettingsRightX := gAutoPresetSettingsMargin + gAutoPresetSettingsListW + gAutoPresetSettingsColumnGap
global gAutoPresetSettingsBottomY := 280

global gAutoPresetSettingsGui := Gui("-MinimizeBox -MaximizeBox -Theme", GuiText.AutoPresetSettingsTitle())
global gAutoPresetSettingsCtrls := Map()
global gAutoPresetSelectedPreset := ""

GuiTheme_Apply(gAutoPresetSettingsGui)

gAutoPresetSettingsGui.OnEvent("Escape", AutoPresetSettingsGuiEscape)
gAutoPresetSettingsGui.OnEvent("Close", AutoPresetSettingsGuiClose)

gAutoPresetSettingsGui.Add("Text", "x" gAutoPresetSettingsMargin " y16 w140 h20 +0x200", GuiText.AutoPresetPresetListLabel())
gAutoPresetSettingsCtrls["PresetList"] := GuiTheme_AddListBox(gAutoPresetSettingsGui, "AutoPresetPresetList", gAutoPresetSettingsMargin, 40, gAutoPresetSettingsListW, gAutoPresetSettingsListH)
gAutoPresetSettingsCtrls["PresetList"].OnEvent("Change", AutoPresetSettingsPresetChanged)

gAutoPresetSettingsCtrls["SettingAutoPresetSwitch"] := gAutoPresetSettingsGui.Add("CheckBox", "vSettingAutoPresetSwitch x" gAutoPresetSettingsRightX " y16 h22", GuiText.SettingAutoPresetSwitch())
gAutoPresetSettingsCtrls["SettingAutoPresetSwitch"].OnEvent("Click", AutoPresetSettingsToggleEnabled)
gAutoPresetSettingsGui.Add("Text", "x" gAutoPresetSettingsRightX " y44 w120 h20 +0x200", GuiText.PresetAutoHotkeyLabel())
gAutoPresetSettingsCtrls["AutoPresetHotkey"] := gAutoPresetSettingsGui.Add("Edit", "vAutoPresetHotkey x" gAutoPresetSettingsRightX " y64 w" gAutoPresetSettingsRightW " h22 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gAutoPresetSettingsCtrls["AutoPresetHotkey"], AutoPresetSettingsHotkeyAfterCapture)
gAutoPresetSettingsGui.Add("Text", "x" gAutoPresetSettingsRightX " y96 w120 h20 +0x200", GuiText.AutoPresetSelectedPresetLabel())
gAutoPresetSettingsCtrls["SelectedPresetName"] := gAutoPresetSettingsGui.Add("Edit", "vAutoPresetSelectedPresetName x" gAutoPresetSettingsRightX " y116 w" gAutoPresetSettingsRightW " h22 +ReadOnly -E0x200 Border")
gAutoPresetSettingsCtrls["OpenPresetSkill"] := GuiTheme_FlatBtn(gAutoPresetSettingsGui, "x" gAutoPresetSettingsRightX " y148 w" gAutoPresetSettingsRightW " h34", MainWindowText.PresetSkillButton(), AutoPresetSettingsOpenPresetSkill, false)
gAutoPresetSettingsCtrls["OpenDetail"] := GuiTheme_FlatBtn(gAutoPresetSettingsGui, "x" gAutoPresetSettingsRightX " y190 w" gAutoPresetSettingsRightW " h34", GuiText.SettingAutoPresetButton(), AutoPresetSettingsOpenDetail, false)
gAutoPresetSettingsGui.Add("Text", "x" gAutoPresetSettingsMargin " y232 w322", GuiText.SettingAutoPresetHelp())

AutoPresetSettingsGetCtrl(name) {
    global gAutoPresetSettingsCtrls
    return gAutoPresetSettingsCtrls.Has(name) ? gAutoPresetSettingsCtrls[name] : ""
}

ShowGuiAutoPresetSettings(*) => AutoPresetSettingsCtrl.Show()
HideGuiAutoPresetSettings(*) => AutoPresetSettingsCtrl.Hide()
AutoPresetSettingsGuiEscape(*) => AutoPresetSettingsCtrl.Hide()
AutoPresetSettingsGuiClose(*) => AutoPresetSettingsCtrl.Hide()
AutoPresetSettingsToggleEnabled(*) => AutoPresetSettingsCtrl.ToggleEnabled()
AutoPresetSettingsPresetChanged(*) => AutoPresetSettingsCtrl.OnPresetSelectionChange()
AutoPresetSettingsHotkeyAfterCapture(key) => AutoPresetSettingsCtrl.AfterHotkeyCapture(key)
AutoPresetSettingsOpenDetail(*) => AutoPresetSettingsCtrl.OpenDetailSettings()
AutoPresetSettingsOpenPresetSkill(*) => AutoPresetSettingsCtrl.OpenPresetSkillSettings()
AutoPresetSettingsSyncPresetList(*) => AutoPresetSettingsCtrl.SyncPresetList()
AutoPresetSettingsGetSelectedPreset() => AutoPresetSettingsCtrl.GetSelectedPreset()
