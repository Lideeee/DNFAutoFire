#Requires AutoHotkey v2.0

class MainController {
    static Show(*) {
        global gMainGui
        try PresetRecognition_CancelPending()
        gMainGui.Title := MainWindowText.Title()
        GuiTheme_ShowFit(gMainGui, "", MainLayout.StandardMargin(), MainLayout.StandardMargin(), MainLayout.GuiWidth(), MainLayout.GuiHeight())
        MainLoadAllPreset()
        this.SyncQuickSwitchFromConfig()
        SetTimer(MainMutedLinkPoll, 100)
    }

    static Hide(*) {
        global gMainGui
        try PresetRecognition_CancelPending()
        SetTimer(MainMutedLinkPoll, 0)
        gMainGui.Hide()
    }

    static Disable() {
        global gMainGui
        gMainGui.Opt("+Disabled")
    }

    static Enable() {
        global gMainGui
        gMainGui.Opt("-Disabled")
        gMainGui.Title := MainWindowText.TitleWithVersion(__Version)
        GuiTheme_ShowFit(gMainGui, "", MainLayout.StandardMargin(), MainLayout.StandardMargin() + 8, MainLayout.GuiWidth(), MainLayout.GuiHeightRunning())
        MainExSwitchPaintAll()
        SetTimer(MainMutedLinkPoll, 100)
    }

    static Start(*) {
        this.Hide()
        AutoFireController.Start()
        try PresetRecognition_StartSequenceFromMainStart()
    }

    static Clear(*) {
        AutoFireController.SetAllKeysDisable()
        this.SaveCurrentPreset()
    }

    static OpenSetting(*) {
        ShowGuiSetting()
    }

    static OpenSettingAbout(*) {
        ShowGuiSettingAbout()
    }

    static OpenAutoPreset(*) {
        ShowGuiAutoPresetSettings()
    }

    static SaveMainViewState() {
        presetName := GetNowSelectPreset()
        if (presetName = "") {
            return
        }
        featureStates := Map()
        for featureName, fieldName in PresetManager.FeatureFieldMap {
            featureStates[featureName] := MainGetCtrl(featureName).Value
        }
        PresetManager.SaveFeatureStates(presetName, featureStates)
        PresetManager.SaveAutoFireInterval(presetName, this.NormalizeAutoFireInterval())
        PresetManager.SaveAutoFirePressDuration(presetName, this.NormalizeAutoFirePressDuration())
    }

    static LoadMainViewState() {
        state := PresetManager.LoadMainViewState(GetNowSelectPreset())
        for featureName, enabled in state.featureStates {
            MainGetCtrl(featureName).Value := enabled
        }
        MainGetCtrl("MainAutoFireInterval").Text := state.autoFireInterval
        MainGetCtrl("MainAutoFirePressDuration").Text := state.autoFirePressDuration
        MainRefreshAllKeyAppearances()
        MainExSwitchPaintAll()
    }

    static NormalizeAutoFireInterval() {
        ctrl := MainGetCtrl("MainAutoFireInterval")
        n := PresetManager.NormalizeInterval(ctrl.Text)
        ctrl.Text := n
        return n
    }

    static SaveAutoFireInterval(*) {
        presetName := GetNowSelectPreset()
        if (presetName = "") {
            return
        }
        ctrl := MainGetCtrl("MainAutoFireInterval")
        raw := Trim(ctrl.Text)
        if (raw = "") {
            return
        }
        PresetManager.SaveAutoFireInterval(presetName, raw)
    }

    static CommitAutoFireInterval(*) {
        presetName := GetNowSelectPreset()
        if (presetName = "") {
            return
        }
        PresetManager.SaveAutoFireInterval(presetName, this.NormalizeAutoFireInterval())
    }

    static NormalizeAutoFirePressDuration() {
        ctrl := MainGetCtrl("MainAutoFirePressDuration")
        n := PresetManager.NormalizePressDuration(ctrl.Text)
        ctrl.Text := n
        return n
    }

    static SaveAutoFirePressDuration(*) {
        presetName := GetNowSelectPreset()
        if (presetName = "") {
            return
        }
        ctrl := MainGetCtrl("MainAutoFirePressDuration")
        raw := Trim(ctrl.Text)
        if (raw = "") {
            return
        }
        PresetManager.SaveAutoFirePressDuration(presetName, raw)
    }

    static CommitAutoFirePressDuration(*) {
        presetName := GetNowSelectPreset()
        if (presetName = "") {
            return
        }
        PresetManager.SaveAutoFirePressDuration(presetName, this.NormalizeAutoFirePressDuration())
    }

    static SaveExToggle(*) {
        this.SaveMainViewState()
    }

    static PruneObsoleteKeyIntervals(presetName) {
        PresetManager.PruneObsoleteKeyIntervalOverrides(presetName, GetAllKeys())
    }

    static SaveCurrentPreset() {
        presetName := GetNowSelectPreset()
        if (presetName = "") {
            return
        }
        this.PruneObsoleteKeyIntervals(presetName)
        PresetManager.SaveEnabledKeys(presetName, SessionState.AutoFireEnableKeys)
        this.SaveMainViewState()
    }

    static RegisterQuickSwitchOnly(keyWithoutTildeDollar) {
        global __QuickSwitchHotkey
        if (keyWithoutTildeDollar = "") {
            keyWithoutTildeDollar := "!``"
        }
        newHk := "~$" keyWithoutTildeDollar
        try {
            if (__QuickSwitchHotkey != "") {
                Hotkey(__QuickSwitchHotkey, "Off")
            }
        } catch {
        }
        __QuickSwitchHotkey := newHk
        Hotkey(__QuickSwitchHotkey, ShowGuiQuickSwitch, "On")
    }

    static PersistAndRegisterQuickSwitch(newKey) {
        SaveConfig("QuickChangeHotKey", newKey)
        reg := (newKey = "") ? "!``" : newKey
        this.RegisterQuickSwitchOnly(reg)
    }

    static SyncQuickSwitchFromConfig() {
        v := LoadConfig("QuickChangeHotKey")
        reg := (v = "") ? "!``" : v
        this.RegisterQuickSwitchOnly(reg)
    }
}

