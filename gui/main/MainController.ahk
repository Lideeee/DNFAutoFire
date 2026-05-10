#Requires AutoHotkey v2.0

class MainController {
    static Show(*) {
        global gMainGui
        try PresetRecognition_CancelPending()
        gMainGui.Title := MainWindowText.Title()
        gMainGui.Show("w" . MainLayout.GuiWidth() . " h" . MainLayout.GuiHeight())
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
        gMainGui.Show("w" . MainLayout.GuiWidth() . " h" . MainLayout.GuiHeightRunning())
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

    static CheckUpdate(*) {
        postUrl := "https://bbs.colg.cn/forum.php?mod=viewthread&tid=9593722"
        try Run(postUrl)
        catch {
            MsgBox(MainWindowText.OpenLinkFailed(postUrl),, "Icon!")
        }
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
    }

    static LoadMainViewState() {
        state := PresetManager.LoadMainViewState(GetNowSelectPreset())
        for featureName, enabled in state.featureStates {
            MainGetCtrl(featureName).Value := enabled
        }
        MainGetCtrl("MainAutoFireInterval").Text := state.autoFireInterval
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

