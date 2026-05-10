#Requires AutoHotkey v2.0

class SettingController {
    static BlockWin(*) {
        return 0
    }

    static ShowPage(page) {
        global __SettingGeneralCtrls, __SettingAboutCtrls
        if (page != 1 && page != 2) {
            page := 1
        }
        for ctrl in __SettingGeneralCtrls {
            ctrl.Visible := (page = 1)
        }
        for ctrl in __SettingAboutCtrls {
            ctrl.Visible := (page = 2)
        }
    }

    static Show(*) {
        this.ShowPageWindow(1)
    }

    static ShowAbout(*) {
        this.ShowPageWindow(2)
    }

    static ShowPageWindow(page) {
        global gMainGui, gSettingGui
        try PresetRecognition_CancelPending()
        DisableGuiMain()
        if IsObject(gMainGui) {
            gSettingGui.Opt("+Owner" gMainGui.Hwnd)
        }
        gSettingGui.Title := GuiText.SettingTitle()
        gSettingGui.Show("w392 h400")
        this.Load()
        this.ShowPage(page)
        GuiTheme_FlatChromeHwnd(SettingGetCtrl("SettingQuickChangeHotKey").Hwnd)
    }

    static Hide() {
        global gSettingGui
        gSettingGui.Hide()
        EnableGuiMain()
    }

    static Save(*) {
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

        QuickChangeHotKey_PersistAndRegister(SettingGetCtrl("SettingQuickChangeHotKey").Value)
        this.ApplyNow()
        this.Hide()
    }

    static Load() {
        global gSettingSuppressQuickKeyChange
        SettingGetCtrl("SettingAutoStart").Value := LoadConfig("SettingAutoStart", false)
        SettingGetCtrl("SettingOnSystemStart").Value := LoadConfig("SettingOnSystemStart", false)
        SettingGetCtrl("SettingBlockWin").Value := LoadConfig("SettingBlockWin", false)
        SettingGetCtrl("SettingAutoPresetSwitch").Value := Trim(LoadConfig("SettingAutoPresetSwitch", "0")) = "1"
        qhk := LoadConfig("QuickChangeHotKey")
        if (qhk = "") {
            qhk := "!``"
        }
        gSettingSuppressQuickKeyChange := true
        SettingGetCtrl("SettingQuickChangeHotKey").Value := qhk
        gSettingSuppressQuickKeyChange := false
    }

    static OnQuickChangeHotKeyChanged(*) {
        global gSettingSuppressQuickKeyChange
        if (gSettingSuppressQuickKeyChange) {
            return
        }
        QuickChangeHotKey_PersistAndRegister(SettingGetCtrl("SettingQuickChangeHotKey").Value)
    }

    static ApplyNow() {
        global _OnSystemStart, _BlockWin
        startupLink := A_Startup "\DAF AutoFire.lnk"
        if (_OnSystemStart) {
            FileCreateShortcut(A_ScriptFullPath, startupLink)
        } else {
            try FileDelete(startupLink)
        }
        if (_BlockWin) {
            Hotkey("$*LWin", SettingBlockWin, "On")
            Hotkey("$*RWin", SettingBlockWin, "On")
        } else {
            try Hotkey("$*LWin", "Off")
            try Hotkey("$*RWin", "Off")
        }
        PresetRecognition_UpdateHotkeys()
    }
}
