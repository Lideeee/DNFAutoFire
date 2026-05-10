#Requires AutoHotkey v2.0

class MainKeyGrid {
    static IsGrayOnlyKey(name) {
        static gray := Map(
            "Esc", true
        )
        return gray.Has(name)
    }

    static IsInteractiveKeyName(name) {
        if (name = "" || this.IsGrayOnlyKey(name)) {
            return false
        }
        return IsValueInArray(name, GetAllKeys())
    }

    static SetKeyState(keyName, isEnabled, overrideMap := 0) {
        if this.IsGrayOnlyKey(keyName) {
            return
        }
        ctrl := MainGetCtrl(keyName)
        if !IsObject(ctrl) {
            return
        }
        size := GuiTheme_MainKeyLabelFontSize(keyName)
        if !isEnabled {
            color := "c" GuiTheme_KeyOff
            weight := "Norm"
        } else {
            hasOverride := false
            if IsObject(overrideMap) {
                hasOverride := overrideMap.Has(keyName)
            } else {
                currentOverrides := LoadPresetKeyIntervalOverrides(GetNowSelectPreset())
                hasOverride := currentOverrides.Has(keyName)
            }
            if hasOverride {
                color := "c" GuiTheme_KeyOv
                weight := "Bold"
            } else {
                color := "c" GuiTheme_KeyOn
                weight := "Bold"
            }
        }
        ctrl.SetFont(size " " color " " weight, GuiTheme_Face)
    }

    static RefreshAllKeyAppearances() {
        presetName := GetNowSelectPreset()
        if (presetName = "") {
            return
        }
        overrideMap := LoadPresetKeyIntervalOverrides(presetName)
        allKeys := GetAllKeys()
        try keyCount := allKeys.Length
        catch {
            keyCount := 0
        }
        loop keyCount {
            if !allKeys.Has(A_Index) {
                continue
            }
            keyName := allKeys[A_Index]
            if this.IsGrayOnlyKey(keyName) {
                continue
            }
            this.SetKeyState(keyName, AutoFireController.IsKeyAutoFire(keyName), overrideMap)
        }
    }

    static OnKeyClick(ctrl, *) {
        AutoFireController.ChangeKeyAutoFireState(ctrl.Name)
        MainSaveCurrentPreset()
    }
}

MainKeyUiGrayOnly(name) => MainKeyGrid.IsGrayOnlyKey(name)
MainIsInteractiveKeyName(name) => MainKeyGrid.IsInteractiveKeyName(name)
MainSetKeyState(keyName, isEnabled, overrideMap := 0) => MainKeyGrid.SetKeyState(keyName, isEnabled, overrideMap)
MainRefreshAllKeyAppearances() => MainKeyGrid.RefreshAllKeyAppearances()
MainKeyClick(ctrl, *) => MainKeyGrid.OnKeyClick(ctrl)
