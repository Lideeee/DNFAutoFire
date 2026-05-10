#Requires AutoHotkey v2.0

#Include ./PresetAutoSwitchController.ahk

global gPresetAutoGui := Gui("-MinimizeBox -MaximizeBox -Theme", GuiText.PresetAutoTitle())
global gPresetAutoCtrls := Map()
global gPresetAutoPvW := 224
global gPresetAutoPvH := 126
global gRegionPickGui := false
global gRegionPickKeyHook := false
global gRegionPickNCHook := false
global gRegionPickNCCalcHook := false
global gRegionPickKind := "skill"

GuiTheme_Apply(gPresetAutoGui)

gPresetAutoGui.OnEvent("Escape", PresetAutoGuiEscape)
gPresetAutoGui.OnEvent("Close", PresetAutoGuiClose)

PresetSkillOpenSkillRegionPick(*) => PresetAutoSwitchController.OpenSkillRegionPick()

gPresetAutoGui.Add("Text", "x8 y8 w224 h14 +0x200", GuiText.PresetAutoHotkeyLabel())
gPresetAutoCtrls["AutoPresetHotkey"] := gPresetAutoGui.Add("Edit", "vAutoPresetHotkey x8 y24 w224 h22 +ReadOnly -WantCtrlA -E0x200 Border")
RegisterEditPressKeyCapture(gPresetAutoCtrls["AutoPresetHotkey"], PresetAutoHotkeyAfterCapture)
gPresetAutoCtrls["CalPreview"] := gPresetAutoGui.Add("Picture", "x8 y52 w224 h126", "")
gPresetAutoCtrls["CalHint"] := gPresetAutoGui.Add("Text", "x8 y182 w224 h44", "")
GuiTheme_FlatBtn(gPresetAutoGui, "x8 y230 w224 h28", GuiText.PresetAutoPickSkillRegion(), PresetSkillOpenSkillRegionPick, false)
GuiTheme_FlatBtn(gPresetAutoGui, "x8 y262 w224 h28", GuiText.PresetAutoPickCalibrateRegion(), (*) => PresetRegionPickOpen("calibrate"), false)
GuiTheme_FlatBtn(gPresetAutoGui, "x8 y294 w108 h28", GuiText.PresetAutoUpdateCalibrate(), PresetAutoUpdateCalibrateIcon, false)
GuiTheme_FlatBtn(gPresetAutoGui, "x124 y294 w108 h28", GuiText.PresetAutoDeleteCalibrate(), PresetAutoDoDeleteCalibrateIcon, false)
GuiTheme_FlatBtn(gPresetAutoGui, "x8 y326 w224 h32", GuiText.SaveButton(), PresetAutoSaveClose, true)

PresetAutoGetCtrl(name) {
    global gPresetAutoCtrls
    return gPresetAutoCtrls.Has(name) ? gPresetAutoCtrls[name] : ""
}

PresetAutoLockCalPreviewFrame(pic) {
    global gPresetAutoPvW, gPresetAutoPvH
    if IsObject(pic) {
        pic.Move(8, 52, gPresetAutoPvW, gPresetAutoPvH)
    }
}

ShowGuiPresetAutoSwitch(*) => PresetAutoSwitchController.Show()
HideGuiPresetAutoSwitch() => PresetAutoSwitchController.Hide()
PresetAutoGuiEscape(*) => PresetAutoSwitchController.Hide()
PresetAutoGuiClose(*) => PresetAutoSwitchController.Hide()
PresetAutoSaveClose(*) => PresetAutoSwitchController.SaveAndClose()
PresetAutoHotkeyAfterCapture(key) => PresetAutoSwitchController.AfterHotkeyCapture(key)
PresetAutoDoDeleteCalibrateIcon(*) => PresetAutoSwitchController.DeleteCalibrateIcon()
PresetAutoRefreshCalibratePreview() => PresetAutoSwitchController.RefreshCalibratePreview()
PresetAutoRefreshCalibratePreviewIfVisible() => PresetAutoSwitchController.RefreshCalibratePreviewIfVisible()
PresetAutoUpdateCalibrateIcon(*) => PresetAutoSwitchController.UpdateCalibrateIcon()

#Include ./PresetRegionPicker.ahk
