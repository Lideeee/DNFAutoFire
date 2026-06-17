#Requires AutoHotkey v2.0

; 一键连招：多方案序列的读写与解析（主进程与子进程共用，勿依赖仅主进程才有的 GUI）

ComboPreset_LoadField(presetName, key, default := "") {
    presetName := NormalizePresetName(presetName)
    if (presetName = "") {
        return ""
    }
    return Trim(StrReplace(String(LoadPreset(presetName, key, default)), "`r", ""))
}

ComboCanonMainKey(raw) {
    s := Trim(String(raw))
    if (s = "") {
        return ""
    }
    all := GetAllKeys()
    for k in all {
        if (k = s) {
            return k
        }
    }
    sl := StrLower(s)
    for k in all {
        if (StrLower(k) = sl) {
            return k
        }
    }
    static alias := Map(
        "escape", "Esc",
        "esc", "Esc",
        "return", "Enter",
        "enter", "Enter",
        "bs", "Backspace",
        "backspace", "Backspace",
        "capslock", "Caps",
        "caps", "Caps",
        "control", "LCtrl",
        "ctrl", "LCtrl",
        "lcontrol", "LCtrl",
        "lctrl", "LCtrl",
        "rcontrol", "RCtrl",
        "rctrl", "RCtrl",
        "shift", "LShift",
        "lshift", "LShift",
        "rshift", "RShift",
        "alt", "LAlt",
        "lalt", "LAlt",
        "ralt", "RAlt",
        "scrolllock", "ScrLk",
        "printscreen", "PrtSc",
        "insert", "Ins",
        "delete", "Del",
        "pgup", "PgUp",
        "pgdn", "PgDn",
        "appskey", "AppsKey"
    )
    if alias.Has(sl) {
        t := alias[sl]
        for k in all {
            if (k = t) {
                return k
            }
        }
    }
    return ""
}

ComboNormalizeDelay(raw) {
    delay := Round((Trim(String(raw)) = "" ? 20 : raw) + 0)
    return delay
}

ComboNormalizeLeadDelay(raw) {
    delay := Round((Trim(String(raw)) = "" ? 0 : raw) + 0)
    if (delay < 0) {
        delay := 0
    }
    return delay
}

ComboProfileRecordSeparator() {
    static rs := Chr(30)
    return rs
}

ComboProfileUnitSeparator() {
    static us := Chr(31)
    return us
}

ComboExportFileSection() {
    return "DNFAutoFireComboExport"
}

ComboBlankProfileMarker() {
    return "blank"
}

ComboBlankProfile() {
    return { trigger: "", loop: false, blockOriginal: false, leadDelay: 0, skills: [] }
}

ComboNormalizeStoredKey(raw) {
    if (Type(raw) != "String" && Trim(String(raw)) = "0") {
        return ""
    }
    return ComboCanonMainKey(raw)
}

ComboIsBlankProfile(p) {
    if !IsObject(p) {
        return false
    }
    trigger := HasProp(p, "trigger") ? ComboNormalizeStoredKey(p.trigger) : ""
    loopOn := HasProp(p, "loop") && p.loop
    blockOriginal := HasProp(p, "blockOriginal") && p.blockOriginal
    leadDelay := HasProp(p, "leadDelay") ? ComboNormalizeLeadDelay(p.leadDelay) : 0
    skills := (HasProp(p, "skills") && IsObject(p.skills)) ? p.skills : []
    return trigger = "" && !loopOn && !blockOriginal && leadDelay = 0 && ComboSerializeSkills(skills) = ""
}

ComboWriteExportFile(filePath, profiles) {
    filePath := Trim(String(filePath))
    if (filePath = "") {
        throw Error("EMPTY_PATH")
    }
    section := ComboExportFileSection()
    IniWrite(ComboSerializeProfiles(profiles), filePath, section, "Profiles")
}

ComboReadExportFile(filePath) {
    filePath := Trim(String(filePath))
    if (filePath = "" || !FileExist(filePath)) {
        throw Error("MISSING_FILE")
    }
    section := ComboExportFileSection()
    raw := IniRead(filePath, section, "Profiles", "")
    if (Trim(String(raw)) = "") {
        throw Error("MISSING_SECTION")
    }
    profiles := ComboParseProfiles(raw)
    if (profiles.Length = 0) {
        throw Error("EMPTY_PROFILES")
    }
    return profiles
}

ComboSerializeSkills(items) {
    data := ""
    if !IsObject(items) {
        return data
    }
    loop items.Length {
        if !items.Has(A_Index) {
            continue
        }
        item := items[A_Index]
        if !IsObject(item) {
            continue
        }
        key := HasProp(item, "key") ? ComboNormalizeStoredKey(item.key) : ""
        if (key = "") {
            continue
        }
        delay := HasProp(item, "delay") ? ComboNormalizeDelay(item.delay) : 20
        data .= key "," delay "|"
    }
    if (StrLen(data) > 0) {
        data := SubStr(data, 1, StrLen(data) - 1)
    }
    return data
}

ComboParseSkills(raw) {
    items := []
    for unit in StrSplit(raw, "|") {
        unit := Trim(unit)
        if (unit = "") {
            continue
        }
        parts := StrSplit(unit, ",")
        if (parts.Length < 1) {
            continue
        }
        key := ComboCanonMainKey(Trim(parts[1]))
        if (key = "") {
            continue
        }
        delayRaw := parts.Length >= 2 ? parts[2] : 20
        items.Push({ key: key, delay: ComboNormalizeDelay(delayRaw) })
    }
    return items
}

ComboSerializeProfiles(profiles) {
    out := ""
    if !IsObject(profiles) {
        return out
    }
    rs := ComboProfileRecordSeparator()
    us := ComboProfileUnitSeparator()
    loop profiles.Length {
        if !profiles.Has(A_Index) {
            continue
        }
        p := profiles[A_Index]
        if !IsObject(p) {
            continue
        }
        if ComboIsBlankProfile(p) {
            rec := ComboBlankProfileMarker()
            if (out != "") {
                out .= rs
            }
            out .= rec
            continue
        }
        trig := HasProp(p, "trigger") ? ComboNormalizeStoredKey(p.trigger) : ""
        loopOn := (HasProp(p, "loop") && p.loop) ? "1" : "0"
        blockOriginal := (HasProp(p, "blockOriginal") && p.blockOriginal) ? "1" : "0"
        leadDelay := HasProp(p, "leadDelay") ? ComboNormalizeLeadDelay(p.leadDelay) : 0
        skills := (HasProp(p, "skills") && IsObject(p.skills)) ? p.skills : []
        skillsStr := ComboSerializeSkills(skills)
        rec := trig us loopOn us blockOriginal us leadDelay us skillsStr
        if (out != "") {
            out .= rs
        }
        out .= rec
    }
    return out
}

ComboParseProfiles(raw) {
    out := []
    raw := Trim(String(raw))
    if (raw = "") {
        return out
    }
    rs := ComboProfileRecordSeparator()
    us := ComboProfileUnitSeparator()
    for rec in StrSplit(raw, rs) {
        rec := Trim(rec)
        if (rec = "") {
            continue
        }
        if (StrLower(rec) = ComboBlankProfileMarker()) {
            out.Push(ComboBlankProfile())
            continue
        }
        parts := StrSplit(rec, us,, 5)
        if (parts.Length < 2) {
            continue
        }
        trigger := ComboCanonMainKey(Trim(parts[1]))
        loopOn := (parts.Length >= 2 && Trim(parts[2]) = "1")
        blockOriginal := false
        leadDelay := 0
        skillsRaw := ""
        if (parts.Length >= 5) {
            blockOriginal := Trim(parts[3]) = "1"
            leadDelay := ComboNormalizeLeadDelay(parts[4])
            skillsRaw := parts[5]
        } else if (parts.Length >= 4) {
            blockOriginal := Trim(parts[3]) = "1"
            skillsRaw := parts[4]
        } else {
            skillsRaw := parts.Length >= 3 ? parts[3] : ""
        }
        out.Push({ trigger: trigger, loop: loopOn, blockOriginal: blockOriginal, leadDelay: leadDelay, skills: ComboParseSkills(skillsRaw) })
    }
    return out
}

ComboLoadProfilesFromPreset(presetName) {
    raw := ComboPreset_LoadField(presetName, "ComboProfiles")
    return ComboParseProfiles(raw)
}
