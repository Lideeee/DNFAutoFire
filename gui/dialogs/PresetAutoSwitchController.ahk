#Requires AutoHotkey v2.0

class PresetAutoSwitchController {
    static OpenSkillRegionPick(*) {
        PresetRegionPickOpen("skill")
    }

    static Show(*) {
        global gMainGui, gSettingGui, gPresetAutoGui
        if IsObject(gSettingGui) && WinExist("ahk_id " gSettingGui.Hwnd) {
            gPresetAutoGui.Opt("+Owner" gSettingGui.Hwnd)
        } else if IsObject(gMainGui) {
            gPresetAutoGui.Opt("+Owner" gMainGui.Hwnd)
        }
        gPresetAutoGui.Title := GuiText.PresetAutoTitle()
        PresetAutoGetCtrl("AutoPresetHotkey").Text := Trim(LoadConfig("AutoPresetHotkey", ""))
        this.RefreshCalibratePreview()
        gPresetAutoGui.Show("w240 h368")
    }

    static Hide() {
        global gPresetAutoGui
        PresetRegionPickCancelIfOpen()
        gPresetAutoGui.Hide()
    }

    static SaveAndClose(*) {
        PresetRegionPickCommitIfOpen()
        this.Hide()
    }

    static AfterHotkeyCapture(key) {
        hk := Trim(key)
        SaveConfig("AutoPresetHotkey", hk)
        PresetRecognition_UpdateHotkeys()
    }

    static DeleteCalibrateIcon(*) {
        path := PresetCalibrateIconGlobalPath()
        if !FileExist(path) {
            return
        }
        try FileDelete(path)
        this.RefreshCalibratePreview()
    }

    static RefreshCalibratePreview() {
        global gPresetAutoPvW, gPresetAutoPvH
        pic := PresetAutoGetCtrl("CalPreview")
        if !IsObject(pic) {
            return
        }
        hint := PresetAutoGetCtrl("CalHint")
        cpath := PresetCalibrateIconGlobalPath()
        pic.Value := ""
        PresetAutoLockCalPreviewFrame(pic)
        if IsObject(hint) {
            hint.Text := GuiText.PresetAutoPreviewHint()
        }
        if FileExist(cpath) {
            tmp := A_Temp "\DAF_cal_fit_preview.png"
            if PresetSkillIcon_RenderFitPreviewToFile(cpath, gPresetAutoPvW, gPresetAutoPvH, tmp) && FileExist(tmp) {
                pic.Value := tmp
            } else {
                pic.Value := cpath
            }
            PresetAutoLockCalPreviewFrame(pic)
        }
    }

    static RefreshCalibratePreviewIfVisible() {
        global gPresetAutoGui
        if IsObject(gPresetAutoGui) && WinExist("ahk_id " gPresetAutoGui.Hwnd) {
            this.RefreshCalibratePreview()
        }
    }

    static UpdateCalibrateIcon(*) {
        PresetRegionPickCommitCalibrateRegionIfOpen()
        try {
            PresetCalibrateIcon_UpdateCurrent()
            this.RefreshCalibratePreview()
        } catch Error as e {
            MsgBox(e.Message,, "Icon!")
        }
    }
}
