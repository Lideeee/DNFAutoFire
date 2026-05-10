#Requires AutoHotkey v2.0

#Include ./PresetAutoCtrl.ahk

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

PresetSkillOpenSkillRegionPick(*) => PresetAutoCtrl.OpenSkillRegionPick()

gPresetAutoCtrls["CalPreview"] := gPresetAutoGui.Add("Picture", "x16 y16 w224 h126", "")
gPresetAutoCtrls["CalHint"] := gPresetAutoGui.Add("Text", "x16 y146 w224 h44", "")
GuiTheme_FlatBtn(gPresetAutoGui, "x16 y194 w224 h28", GuiText.PresetAutoPickSkillRegion(), PresetSkillOpenSkillRegionPick, false)
GuiTheme_FlatBtn(gPresetAutoGui, "x16 y226 w224 h28", GuiText.PresetAutoPickCalibrateRegion(), (*) => PresetRegionPickOpen("calibrate"), false)
GuiTheme_FlatBtn(gPresetAutoGui, "x16 y258 w108 h28", GuiText.PresetAutoUpdateCalibrate(), PresetAutoUpdateCalibrateIcon, false)
GuiTheme_FlatBtn(gPresetAutoGui, "x132 y258 w108 h28", GuiText.PresetAutoDeleteCalibrate(), PresetAutoDoDeleteCalibrateIcon, false)
GuiTheme_FlatBtn(gPresetAutoGui, "x16 y290 w224 h32", GuiText.SaveButton(), PresetAutoSaveClose, true)

PresetAutoGetCtrl(name) {
    global gPresetAutoCtrls
    return gPresetAutoCtrls.Has(name) ? gPresetAutoCtrls[name] : ""
}

PresetAutoLockCalPreviewFrame(pic) {
    global gPresetAutoPvW, gPresetAutoPvH
    if IsObject(pic) {
        pic.Move(16, 16, gPresetAutoPvW, gPresetAutoPvH)
    }
}

ShowGuiPresetAutoSwitch(*) => PresetAutoCtrl.Show()
HideGuiPresetAutoSwitch() => PresetAutoCtrl.Hide()
PresetAutoGuiEscape(*) => PresetAutoCtrl.Hide()
PresetAutoGuiClose(*) => PresetAutoCtrl.Hide()
PresetAutoSaveClose(*) => PresetAutoCtrl.SaveAndClose()
PresetAutoDoDeleteCalibrateIcon(*) => PresetAutoCtrl.DeleteCalibrateIcon()
PresetAutoRefreshCalibratePreview() => PresetAutoCtrl.RefreshCalibratePreview()
PresetAutoRefreshCalibratePreviewIfVisible() => PresetAutoCtrl.RefreshCalibratePreviewIfVisible()
PresetAutoUpdateCalibrateIcon(*) => PresetAutoCtrl.UpdateCalibrateIcon()

#Include ./PresetRegionPicker.ahk
