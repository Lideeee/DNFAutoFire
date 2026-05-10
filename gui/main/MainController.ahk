#Requires AutoHotkey v2.0

class MainController {
    static _persisting := false

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
        if !this.SaveCurrentPreset() {
            return
        }
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

    static FlushPendingTimingCommits() {
        return this.CommitCurrentPresetUi(false)
    }

    static CollectFeatureStates() {
        featureStates := Map()
        for featureName, fieldName in PresetManager.FeatureFieldMap {
            featureStates[featureName] := MainGetCtrl(featureName).Value
        }
        return featureStates
    }

    static CommitCurrentPresetUi(saveAll := false, presetName := unset) {
        Critical("On")
        if this._persisting {
            Critical("Off")
            return false
        }
        if !IsSet(presetName) {
            presetName := GetNowSelectPreset()
        }
        if (presetName = "") {
            Critical("Off")
            return false
        }
        this._persisting := true
        try {
            if !this.PersistMainTimingFromUi(presetName) {
                return false
            }
            if saveAll {
                this.PruneObsoleteKeyIntervals(presetName)
                PresetManager.SaveEnabledKeys(presetName, SessionState.AutoFireEnableKeys)
                PresetManager.SaveFeatureStates(presetName, this.CollectFeatureStates())
            }
            return true
        } finally {
            this._persisting := false
            Critical("Off")
        }
    }

    static PersistMainTimingFromUi(presetName := unset) {
        if !IsSet(presetName) {
            presetName := GetNowSelectPreset()
        }
        if (presetName = "") {
            return false
        }
        intervalVal := this.NormalizeAutoFireInterval()
        pressDurationVal := this.NormalizeAutoFirePressDuration()
        PresetManager.SaveAutoFireInterval(presetName, intervalVal)
        PresetManager.SaveAutoFirePressDuration(presetName, pressDurationVal)
        return true
    }

    static SaveAutoFireInterval(*) {
        return
    }

    static CommitAutoFireInterval(*) {
        return this.CommitCurrentPresetUi(false)
    }

    static NormalizeAutoFirePressDuration() {
        ctrl := MainGetCtrl("MainAutoFirePressDuration")
        n := PresetManager.NormalizePressDuration(ctrl.Text)
        ctrl.Text := n
        return n
    }

    static SaveAutoFirePressDuration(*) {
        return
    }

    static CommitAutoFirePressDuration(*) {
        return this.CommitCurrentPresetUi(false)
    }

    static SaveExToggle(*) {
        this.SaveCurrentPreset()
    }

    static PruneObsoleteKeyIntervals(presetName) {
        PresetManager.PruneObsoleteKeyIntervalOverrides(presetName, GetAllKeys())
    }

    static SaveCurrentPreset() {
        return this.CommitCurrentPresetUi(true)
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

