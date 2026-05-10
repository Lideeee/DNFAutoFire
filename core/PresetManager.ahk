#Requires AutoHotkey v2.0

class PresetManager {
    static FeatureFieldMap := Map(
        "LvRen", "LvRenState",
        "GuanYu", "GuanYuState",
        "PetSkill", "PetSkillState",
        "JianZong", "JianZongState",
        "AutoRun", "AutoRunState",
        "Combo", "ComboState",
        "ZhanFa", "ZhanFaState"
    )

    static DefaultAutoFireInterval := 20

    static DefaultPresetFields() {
        return Map(
            "keys", "",
            "LvRenState", false,
            "GuanYuState", false,
            "PetSkillState", false,
            "ZhanFaState", false,
            "JianZongState", false,
            "AutoRunState", false,
            "ComboState", false,
            "MainAutoFireInterval", this.DefaultAutoFireInterval,
            "ComboTriggerKey", "",
            "ComboLoopMode", false,
            "ComboSkills", "",
            "ComboProfiles", "",
            "MainAutoFireKeyIntervals", ""
        )
    }

    static List() {
        return LoadAllPreset()
    }

    static ListPipe() {
        return LoadAllPresetString()
    }

    static Exists(name) {
        name := Trim(name "")
        if (name = "") {
            return false
        }
        return IsValueInArray(name, this.List())
    }

    static Select(name, saveLast := false) {
        name := Trim(name "")
        if (name = "") {
            return
        }
        SessionState.SetCurrentPreset(name)
        if saveLast {
            SaveLastPreset(name)
        }
    }

    static NormalizeInterval(value, defaultValue := unset) {
        if !IsSet(defaultValue) {
            defaultValue := this.DefaultAutoFireInterval
        }
        raw := Trim(value "")
        n := Round((raw = "" ? defaultValue : raw) + 0)
        if (n < 1) {
            n := 1
        } else if (n > 200) {
            n := 200
        }
        return n
    }

    static LoadMainViewState(presetName := unset) {
        if !IsSet(presetName) {
            presetName := SessionState.GetCurrentPreset()
        }
        featureStates := Map()
        for featureName, fieldName in this.FeatureFieldMap {
            featureStates[featureName] := LoadPresetBool01(presetName, fieldName, false)
        }
        return {
            featureStates: featureStates,
            autoFireInterval: this.NormalizeInterval(LoadPreset(presetName, "MainAutoFireInterval", this.DefaultAutoFireInterval)),
            keyIntervalOverrides: LoadPresetKeyIntervalOverrides(presetName),
            autoFireKeys: LoadPresetKeys(presetName)
        }
    }

    static SaveFeatureStates(presetName, featureStates) {
        if !IsObject(featureStates) {
            return
        }
        for featureName, fieldName in this.FeatureFieldMap {
            if featureStates.Has(featureName) {
                SavePreset(presetName, fieldName, featureStates[featureName] ? 1 : 0)
            }
        }
    }

    static LoadFeatureState(featureName, presetName := unset) {
        if !IsSet(presetName) {
            presetName := SessionState.GetCurrentPreset()
        }
        if !this.FeatureFieldMap.Has(featureName) {
            return 0
        }
        return LoadPresetBool01(presetName, this.FeatureFieldMap[featureName], false)
    }

    static SaveAutoFireInterval(presetName, value) {
        SavePreset(presetName, "MainAutoFireInterval", this.NormalizeInterval(value))
    }

    static LoadKeyIntervalOverrides(presetName := unset) {
        if !IsSet(presetName) {
            presetName := SessionState.GetCurrentPreset()
        }
        return LoadPresetKeyIntervalOverrides(presetName)
    }

    static SaveKeyIntervalOverrides(presetName, intervalMap) {
        SavePresetKeyIntervalOverrides(presetName, intervalMap)
    }

    static PruneObsoleteKeyIntervalOverrides(presetName, validKeys := unset) {
        m := this.LoadKeyIntervalOverrides(presetName)
        if !IsSet(validKeys) {
            validKeys := GetAllKeys()
        }
        del := []
        for k, v in m {
            if !IsValueInArray(k, validKeys) {
                del.Push(k)
            }
        }
        for k in del {
            m.Delete(k)
        }
        if del.Length {
            this.SaveKeyIntervalOverrides(presetName, m)
        }
        return m
    }

    static SaveEnabledKeys(presetName, keys) {
        SavePresetKeys(presetName, keys)
    }

    static Initialize(name) {
        for fieldName, value in this.DefaultPresetFields() {
            SavePreset(name, fieldName, value)
        }
    }

    static Create(name) {
        if this.Exists(name) {
            return false
        }
        this.Initialize(name)
        presetList := this.List()
        if !IsValueInArray(name, presetList) {
            presetList.Push(name)
        }
        SavePresetOrder(presetList)
        this.Select(name)
        return true
    }

    static CloneAs(oldName, newName) {
        if (oldName = "" || newName = "" || this.Exists(newName)) {
            return false
        }
        config := IniRead(ConfigIniPath(), "预设:" oldName)
        IniWrite(config, ConfigIniPath(), "预设:" newName)
        presetList := this.List()
        if !IsValueInArray(newName, presetList) {
            presetList.Push(newName)
        }
        SavePresetOrder(presetList)
        this.Select(newName)
        return true
    }

    static Rename(oldName, newName) {
        if (oldName = "" || newName = "" || oldName = newName || this.Exists(newName)) {
            return false
        }
        config := IniRead(ConfigIniPath(), "预设:" oldName)
        IniWrite(config, ConfigIniPath(), "预设:" newName)
        DeletePreset(oldName)
        presetList := this.List()
        loop presetList.Length {
            if !presetList.Has(A_Index) {
                continue
            }
            if (presetList[A_Index] = oldName) {
                presetList[A_Index] := newName
                break
            }
        }
        SavePresetOrder(presetList)
        this.Select(newName)
        return true
    }

    static Delete(name) {
        if (name = "") {
            return ""
        }
        DeletePreset(name)
        presetList := this.List()
        DeleteValueInArray(name, presetList)
        SavePresetOrder(presetList)
        fallbackName := presetList.Length ? presetList[1] : ""
        if (fallbackName != "") {
            this.Select(fallbackName)
        }
        return fallbackName
    }
}
