; 始终使用主脚本目录下的 config.ini（勿用裸 "config.ini"，否则 CWD 非脚本目录时读写不一致、列表为空）

class ConfigStore {
    static IniPath => A_ScriptDir "\config.ini"
    static DefaultPresetName := "默认"

    static _ValueInArray(value, arr) {
        if !IsObject(arr) {
            return false
        }
        for v in arr {
            if (v == value) {
                return true
            }
        }
        return false
    }

    static SaveSetting(type, value) {
        IniWrite(value, this.IniPath, "设置", type)
    }

    static LoadSetting(type, default := "") {
        if (default == "") {
            default := A_Space
        }
        return IniRead(this.IniPath, "设置", type, default)
    }

    static DeleteSetting(type) {
        IniDelete(this.IniPath, "设置", type)
    }

    static SavePresetField(presetsName, type, value) {
        presetsName := StrReplace(presetsName, "`|")
        IniWrite(value, this.IniPath, "预设:" presetsName, type)
    }

    static LoadPresetField(presetsName, type, default := "") {
        if (default == "") {
            default := A_Space
        }
        presetsName := StrReplace(presetsName, "`|")
        return IniRead(this.IniPath, "预设:" presetsName, type, default)
    }

    static DeletePresetSection(presetsName) {
        presetsName := StrReplace(presetsName, "`|")
        IniDelete(this.IniPath, "预设:" presetsName)
    }

    static SavePresetKeys(presetsName, keys) {
        keysString := ""
        if !IsObject(keys) {
            this.SavePresetField(presetsName, "keys", keysString)
            return
        }
        try keyCount := keys.Length
        catch {
            keyCount := 0
        }
        loop keyCount {
            try hasItem := keys.Has(A_Index)
            catch {
                hasItem := false
            }
            if !hasItem {
                continue
            }
            item := keys[A_Index]
            if (item != "") {
                keysString := keysString . item . "|"
            }
        }
        if (StrLen(keysString) > 0) {
            keysString := SubStr(keysString, 1, StrLen(keysString) - 1)
        }
        this.SavePresetField(presetsName, "keys", keysString)
    }

    static LoadPresetKeys(presetsName) {
        config := this.LoadPresetField(presetsName, "keys")
        keys := []
        for item in StrSplit(config, "|") {
            if (item != "") {
                keys.Push(item)
            }
        }
        return keys
    }

    static LoadPresetKeyIntervalOverrides(presetName) {
        o := Map()
        raw := this.LoadPresetSafe(presetName, "MainAutoFireKeyIntervals")
        if (raw = "") {
            return o
        }
        for part in StrSplit(raw, "|") {
            part := Trim(part)
            if (part = "") {
                continue
            }
            p := InStr(part, "=")
            if (p < 1) {
                continue
            }
            k := Trim(SubStr(part, 1, p - 1))
            if (k = "") {
                continue
            }
            v := Round(Trim(SubStr(part, p + 1)) + 0)
            if (v < 1) {
                v := 1
            } else if (v > 200) {
                v := 200
            }
            o[k] := v
        }
        return o
    }

    static SavePresetKeyIntervalOverrides(presetName, intervalMap) {
        if !IsObject(intervalMap) {
            this.SavePresetField(presetName, "MainAutoFireKeyIntervals", "")
            return
        }
        s := ""
        for k, v in intervalMap {
            if (k = "") {
                continue
            }
            vn := Round(v + 0)
            if (vn < 1) {
                vn := 1
            } else if (vn > 200) {
                vn := 200
            }
            s .= k "=" vn "|"
        }
        if (StrLen(s) > 0) {
            s := SubStr(s, 1, StrLen(s) - 1)
        }
        this.SavePresetField(presetName, "MainAutoFireKeyIntervals", s)
    }

    static LoadAllPresetNames() {
        presetList := []
        if !FileExist(this.IniPath) {
            return presetList
        }
        sections := IniRead(this.IniPath)
        for sec in StrSplit(sections, "`n", "`r") {
            sec := Trim(sec)
            if (sec = "") {
                continue
            }
            if (SubStr(sec, 1, 3) = "预设:") {
                presetList.Push(SubStr(sec, 4))
            }
        }
        return this.ApplyPresetOrder(presetList)
    }

    static ApplyPresetOrder(presetList) {
        ordered := []
        used := Map()
        orderRaw := this.LoadSetting("PresetOrder", "")
        if (orderRaw != "") {
            for item in StrSplit(orderRaw, "|") {
                item := Trim(item)
                if (item = "" || used.Has(item)) {
                    continue
                }
                if this._ValueInArray(item, presetList) {
                    ordered.Push(item)
                    used[item] := true
                }
            }
        }
        loop presetList.Length {
            if !presetList.Has(A_Index) {
                continue
            }
            name := presetList[A_Index]
            if (name = "" || used.Has(name)) {
                continue
            }
            ordered.Push(name)
        }
        return ordered
    }

    static SavePresetOrder(presetList) {
        orderRaw := ""
        if IsObject(presetList) {
            loop presetList.Length {
                if !presetList.Has(A_Index) {
                    continue
                }
                name := Trim(presetList[A_Index])
                if (name = "") {
                    continue
                }
                orderRaw .= name "|"
            }
        }
        if (StrLen(orderRaw) > 0) {
            orderRaw := SubStr(orderRaw, 1, StrLen(orderRaw) - 1)
        }
        this.SaveSetting("PresetOrder", orderRaw)
    }

    static EnsureInitialized() {
        path := this.IniPath
        if !FileExist(path) {
            this._CreateDefaultConfigIni()
            return
        }
        if (this.LoadAllPresetNames().Length = 0) {
            this.SavePresetField(this.DefaultPresetName, "keys", "")
            this.SaveLastPreset(this.DefaultPresetName)
        }
    }

    static _CreateDefaultConfigIni() {
        dn := this.DefaultPresetName
        this.SaveSetting("SettingAutoStart", false)
        this.SaveSetting("SettingOnSystemStart", false)
        this.SaveSetting("SettingBlockWin", false)
        this.SaveSetting("SettingAutoPresetSwitch", 0)
        this.SaveSetting("AutoPresetHotkey", "")
        this.SaveSetting("AutoPresetRegion", "")
        this.SaveSetting("AutoPresetCalibrateRegion", "")
        this.SaveSetting("AutoPresetImageVariation", 80)
        this.SaveLastPreset(dn)
        this.SavePresetField(dn, "keys", "")
        this.SavePresetField(dn, "LvRenState", false)
        this.SavePresetField(dn, "GuanYuState", false)
        this.SavePresetField(dn, "PetSkillState", false)
        this.SavePresetField(dn, "ZhanFaState", false)
        this.SavePresetField(dn, "JianZongState", false)
        this.SavePresetField(dn, "AutoRunState", false)
        this.SavePresetField(dn, "ComboState", false)
        this.SavePresetField(dn, "MainAutoFireInterval", 20)
        this.SavePresetField(dn, "AutoRunLeftKey", "Left")
        this.SavePresetField(dn, "AutoRunRightKey", "Right")
        this.SavePresetField(dn, "ComboTriggerKey", "")
        this.SavePresetField(dn, "ComboLoopMode", false)
        this.SavePresetField(dn, "ComboSkills", "")
        this.SavePresetField(dn, "ComboProfiles", "")
        this.SavePresetField(dn, "MainAutoFireKeyIntervals", "")
    }

    static LoadAllPresetString() {
        presetList := this.LoadAllPresetNames()
        presetListStr := ""
        loop presetList.Length {
            if !presetList.Has(A_Index) {
                continue
            }
            presetListStr := presetListStr . presetList[A_Index] . "|"
        }
        if (StrLen(presetListStr) > 0) {
            presetListStr := SubStr(presetListStr, 1, StrLen(presetListStr) - 1)
        }
        return presetListStr
    }

    static SaveLastPreset(presetName) {
        this.SaveSetting("LastPreset", presetName)
    }

    static LoadLastPreset() {
        return this.LoadSetting("LastPreset")
    }

    static LoadLastPresetTrimmed() {
        return Trim(this.LoadLastPreset())
    }

    static ClonePreset(presetName) {
        config := IniRead(this.IniPath, "预设:" presetName)
        IniWrite(config, this.IniPath, "预设:" presetName "-克隆")
    }

    ; 预设里 0/1 开关
    static LoadPresetBool01(presetName, key, default := 0) {
        defStr := default ? "1" : "0"
        raw := this.LoadPresetField(presetName, key, defStr)
        s := Trim(String(raw))
        if (s = "") {
            return default ? 1 : 0
        }
        if RegExMatch(s, "^-?[0-9]+$") {
            return Integer(s) != 0 ? 1 : 0
        }
        sl := StrLower(s)
        if (SubStr(sl, 1, 4) = "true" || sl = "yes" || sl = "on") {
            return 1
        }
        return 0
    }

    static LoadPresetSafe(presetsName, type) {
        presetsName := Trim(presetsName)
        if (presetsName = "") {
            return ""
        }
        return Trim(this.LoadPresetField(presetsName, type, ""))
    }
}

ConfigIniPath() => ConfigStore.IniPath

SaveConfig(type, value) {
    ConfigStore.SaveSetting(type, value)
}

LoadConfig(type, default := "") {
    return ConfigStore.LoadSetting(type, default)
}

DeleteConfig(type) {
    ConfigStore.DeleteSetting(type)
}

SavePreset(presetsName, type, value) {
    ConfigStore.SavePresetField(presetsName, type, value)
}

LoadPreset(presetsName, type, default := "") {
    return ConfigStore.LoadPresetField(presetsName, type, default)
}

LoadPresetBool01(presetName, key, default := 0) {
    return ConfigStore.LoadPresetBool01(presetName, key, default)
}

LoadPresetSafe(presetsName, type) {
    return ConfigStore.LoadPresetSafe(presetsName, type)
}

DeletePreset(presetsName) {
    ConfigStore.DeletePresetSection(presetsName)
}

SavePresetKeys(presetsName, keys) {
    ConfigStore.SavePresetKeys(presetsName, keys)
}

LoadPresetKeys(presetsName) {
    return ConfigStore.LoadPresetKeys(presetsName)
}

LoadPresetKeyIntervalOverrides(presetName) {
    return ConfigStore.LoadPresetKeyIntervalOverrides(presetName)
}

SavePresetKeyIntervalOverrides(presetName, intervalMap) {
    ConfigStore.SavePresetKeyIntervalOverrides(presetName, intervalMap)
}

LoadAllPreset() {
    return ConfigStore.LoadAllPresetNames()
}

ApplyPresetOrder(presetList) {
    return ConfigStore.ApplyPresetOrder(presetList)
}

SavePresetOrder(presetList) {
    ConfigStore.SavePresetOrder(presetList)
}

EnsureConfigInitialized() {
    ConfigStore.EnsureInitialized()
}

LoadAllPresetString() {
    return ConfigStore.LoadAllPresetString()
}

SaveLastPreset(presetName) {
    ConfigStore.SaveLastPreset(presetName)
}

LoadLastPreset() {
    return ConfigStore.LoadLastPreset()
}

LoadLastPresetTrimmed() {
    return ConfigStore.LoadLastPresetTrimmed()
}

ClonePreset(presetName) {
    ConfigStore.ClonePreset(presetName)
}

_CreateDefaultConfigIni() {
    ConfigStore._CreateDefaultConfigIni()
}
