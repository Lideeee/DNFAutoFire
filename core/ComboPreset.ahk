#Requires AutoHotkey v2.0

; 一键连招：多方案序列的读写与解析（主进程与子进程共用，勿依赖仅主进程才有的 GUI）
; 数据布局：每个方案一个独立 INI 节，节名形如 `预设:职业名.Combo.编号`，从 1 起按方案顺序紧凑编号。
; 方案内字段：Trigger / Loop / BlockOriginal / Skills；Skills 用 `|` 分隔技能，`:` 分隔技能键、间隔与按下保持时间。

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
    return s
}

; 空技能占位符：UI 中清空技能键时使用，序列化/解析/克隆层不需特殊处理
ComboEmptySkillKey() {
    return "<NONE>"
}

ComboIsEmptySkillKey(key) {
    return Trim(String(key)) = ComboEmptySkillKey()
}

ComboNormalizeDelay(raw) {
    delay := Round((Trim(String(raw)) = "" ? 20 : raw) + 0)
    return delay
}

ComboSkillHoldDefault() {
    return 12
}

ComboNormalizeHold(raw) {
    s := Trim(String(raw))
    if (s = "") {
        return ComboSkillHoldDefault()
    }
    hold := Round(s + 0)
    if (hold < 0) {
        hold := 0
    }
    return hold
}

ComboSkillRecordSeparator() {
    return "|"
}

ComboSkillUnitSeparator() {
    return ":"
}

ComboNormalizeStoredKey(raw) {
    if (Type(raw) != "String" && Trim(String(raw)) = "0") {
        return ""
    }
    return ComboCanonMainKey(raw)
}

ComboProfileChildPrefix(presetName) {
    return "预设:" NormalizePresetName(presetName) ".Combo."
}

ComboProfileChildSection(presetName, idx) {
    return ComboProfileChildPrefix(presetName) idx
}

; 枚举某预设下的所有一键连招方案编号，按数字升序返回
ComboListProfileIndices(presetName) {
    indices := []
    path := ConfigIniPath()
    if !FileExist(path) {
        return indices
    }
    prefix := ComboProfileChildPrefix(presetName)
    prefixLen := StrLen(prefix)
    sections := ""
    try {
        sections := IniRead(path)
    } catch {
        return indices
    }
    for sec in StrSplit(sections, "`n", "`r") {
        sec := Trim(sec)
        if (SubStr(sec, 1, prefixLen) != prefix) {
            continue
        }
        tail := SubStr(sec, prefixLen + 1)
        if !RegExMatch(tail, "^[1-9][0-9]*$") {
            continue
        }
        indices.Push(Number(tail))
    }
    ; 插入排序：方案数通常很少
    loop indices.Length - 1 {
        i := A_Index + 1
        key := indices[i]
        j := i - 1
        while (j >= 1 && indices[j] > key) {
            indices[j + 1] := indices[j]
            j -= 1
        }
        indices[j + 1] := key
    }
    return indices
}

ComboReadProfileSection(path, section) {
    p := { trigger: "", loop: false, blockOriginal: false, skills: [] }
    if !FileExist(path) {
        return p
    }
    trigger := ""
    loopOn := "0"
    blockOriginal := "0"
    skillsRaw := ""
    try trigger := IniRead(path, section, "Trigger", "")
    try loopOn := IniRead(path, section, "Loop", "0")
    try blockOriginal := IniRead(path, section, "BlockOriginal", "0")
    try skillsRaw := IniRead(path, section, "Skills", "")
    p.trigger := ComboCanonMainKey(trigger)
    p.loop := (Trim(loopOn) = "1")
    p.blockOriginal := (Trim(blockOriginal) = "1")
    p.skills := ComboParseSkills(skillsRaw)
    return p
}

ComboLoadProfilesFromPreset(presetName) {
    profiles := []
    presetName := NormalizePresetName(presetName)
    if (presetName = "") {
        return profiles
    }
    path := ConfigIniPath()
    indices := ComboListProfileIndices(presetName)
    for idx in indices {
        section := ComboProfileChildSection(presetName, idx)
        profiles.Push(ComboReadProfileSection(path, section))
    }
    return profiles
}

ComboSaveProfilesToPreset(presetName, profiles) {
    presetName := NormalizePresetName(presetName)
    path := ConfigIniPath()
    ; 先清除该预设下所有旧方案节，再按数组顺序从 1 起紧凑写入
    for idx in ComboListProfileIndices(presetName) {
        try IniDelete(path, ComboProfileChildSection(presetName, idx))
    }
    if !IsObject(profiles) {
        return
    }
    loop profiles.Length {
        if !profiles.Has(A_Index) {
            continue
        }
        p := profiles[A_Index]
        if !IsObject(p) {
            continue
        }
        section := ComboProfileChildSection(presetName, A_Index)
        trig := HasProp(p, "trigger") ? ComboNormalizeStoredKey(p.trigger) : ""
        loopOn := (HasProp(p, "loop") && p.loop) ? "1" : "0"
        blockOriginal := (HasProp(p, "blockOriginal") && p.blockOriginal) ? "1" : "0"
        skills := (HasProp(p, "skills") && IsObject(p.skills)) ? p.skills : []
        IniWrite(trig, path, section, "Trigger")
        IniWrite(loopOn, path, section, "Loop")
        IniWrite(blockOriginal, path, section, "BlockOriginal")
        IniWrite(ComboSerializeSkills(skills), path, section, "Skills")
    }
}

ComboSerializeSkills(items) {
    data := ""
    if !IsObject(items) {
        return data
    }
    rs := ComboSkillRecordSeparator()
    us := ComboSkillUnitSeparator()
    defaultHold := ComboSkillHoldDefault()
    loop items.Length {
        if !items.Has(A_Index) {
            continue
        }
        item := items[A_Index]
        if !IsObject(item) {
            continue
        }
        key := HasProp(item, "key") ? ComboNormalizeStoredKey(item.key) : ""
        delay := HasProp(item, "delay") ? ComboNormalizeDelay(item.delay) : 20
        hold := HasProp(item, "hold") ? ComboNormalizeHold(item.hold) : defaultHold
        if (data != "") {
            data .= rs
        }
        ; hold 等于默认值时省略第三段，旧版本仍能正常读取 key 与 delay
        if (hold = defaultHold) {
            data .= key us delay
        } else {
            data .= key us delay us hold
        }
    }
    return data
}

ComboParseSkills(raw) {
    items := []
    rs := ComboSkillRecordSeparator()
    us := ComboSkillUnitSeparator()
    for unit in StrSplit(raw, rs) {
        unit := Trim(unit)
        if (unit = "") {
            continue
        }
        parts := StrSplit(unit, us,, 3)
        key := ComboCanonMainKey(Trim(parts[1]))
        delayRaw := parts.Length >= 2 ? parts[2] : 20
        holdRaw := parts.Length >= 3 ? parts[3] : ""
        items.Push({ key: key, delay: ComboNormalizeDelay(delayRaw), hold: ComboNormalizeHold(holdRaw) })
    }
    return items
}

; 导出文件节命名：Combo.编号，避免与主程序的 `预设:` 前缀混淆
ComboExportProfilePrefix() {
    return "Combo."
}

ComboExportProfileSection(idx) {
    return ComboExportProfilePrefix() idx
}

ComboWriteExportFile(filePath, profiles) {
    filePath := Trim(String(filePath))
    if (filePath = "") {
        throw Error("EMPTY_PATH")
    }
    if FileExist(filePath) {
        FileDelete(filePath)
    }
    if !IsObject(profiles) {
        IniWrite("0", filePath, "DNFAutoFireComboExport", "Count")
        return
    }
    IniWrite(String(profiles.Length), filePath, "DNFAutoFireComboExport", "Count")
    loop profiles.Length {
        if !profiles.Has(A_Index) {
            continue
        }
        p := profiles[A_Index]
        if !IsObject(p) {
            continue
        }
        section := ComboExportProfileSection(A_Index)
        trig := HasProp(p, "trigger") ? ComboNormalizeStoredKey(p.trigger) : ""
        loopOn := (HasProp(p, "loop") && p.loop) ? "1" : "0"
        blockOriginal := (HasProp(p, "blockOriginal") && p.blockOriginal) ? "1" : "0"
        skills := (HasProp(p, "skills") && IsObject(p.skills)) ? p.skills : []
        IniWrite(trig, filePath, section, "Trigger")
        IniWrite(loopOn, filePath, section, "Loop")
        IniWrite(blockOriginal, filePath, section, "BlockOriginal")
        IniWrite(ComboSerializeSkills(skills), filePath, section, "Skills")
    }
}

ComboReadExportFile(filePath) {
    filePath := Trim(String(filePath))
    if (filePath = "" || !FileExist(filePath)) {
        throw Error("MISSING_FILE")
    }
    countRaw := ""
    try countRaw := IniRead(filePath, "DNFAutoFireComboExport", "Count", "")
    if (Trim(String(countRaw)) = "") {
        throw Error("MISSING_SECTION")
    }
    count := Round(countRaw + 0)
    if (count <= 0) {
        throw Error("EMPTY_PROFILES")
    }
    profiles := []
    loop count {
        section := ComboExportProfileSection(A_Index)
        ; 缺失的节视为空方案，不抛错
        profiles.Push(ComboReadProfileSection(filePath, section))
    }
    if (profiles.Length = 0) {
        throw Error("EMPTY_PROFILES")
    }
    return profiles
}
