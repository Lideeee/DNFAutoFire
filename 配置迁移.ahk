#Requires AutoHotkey v2.0

; 一键连招配置迁移：把旧的单串 ComboProfiles 格式升级为多 section 布局。
; 旧格式：[预设:职业名] 下 ComboProfiles=方案1\x1f1\x1f0\x1fSkills|...\x1e方案2...
;         方案间分隔 Chr(30)，字段间分隔 Chr(31)，blank 标记空方案
; 新格式：[预设:职业名.Combo.1]、[预设:职业名.Combo.2]... 每个 section 独立保存
;         Trigger / Loop / BlockOriginal / Skills 四个 key
; 迁移完成后删除主节下的 ComboProfiles key。

ConfigPathFromArgs() {
    path := A_ScriptDir "\config.ini"
    for arg in A_Args {
        if (SubStr(arg, 1, 1) != "/") {
            path := arg
            break
        }
    }
    return path
}

IsDryRun() {
    for arg in A_Args {
        if (StrLower(arg) = "/dryrun") {
            return true
        }
    }
    return false
}

LegacyProfileRecordSeparator() {
    static rs := Chr(30)
    return rs
}

LegacyProfileUnitSeparator() {
    static us := Chr(31)
    return us
}

LegacySkillRecordSeparator() {
    return "|"
}

LegacySkillUnitSeparator() {
    return ":"
}

LegacyBlankProfileMarker() {
    return "blank"
}

NormalizeDelay(raw) {
    return Round((Trim(String(raw)) = "" ? 20 : raw) + 0)
}

; 旧版技能串可能用 `,` 分隔键和延迟（更早的格式），统一转成 `:` 分隔
ConvertLegacySkills(raw) {
    raw := Trim(String(raw))
    if (raw = "") {
        return ""
    }
    if InStr(raw, LegacySkillUnitSeparator()) {
        return raw
    }
    out := ""
    rs := LegacySkillRecordSeparator()
    us := LegacySkillUnitSeparator()
    for unit in StrSplit(raw, "|") {
        unit := Trim(unit)
        if (unit = "") {
            continue
        }
        commaPos := InStr(unit, ",")
        if commaPos {
            key := Trim(SubStr(unit, 1, commaPos - 1))
            delay := NormalizeDelay(SubStr(unit, commaPos + 1))
        } else {
            key := Trim(unit)
            delay := 20
        }
        if (key = "") {
            continue
        }
        if (out != "") {
            out .= rs
        }
        out .= key us delay
    }
    return out
}

; 解析旧单串格式，返回方案数组（每个方案是 {trigger, loop, blockOriginal, skillsRaw}）
ParseLegacyProfiles(raw) {
    profiles := []
    raw := Trim(String(raw))
    if (raw = "") {
        return profiles
    }
    rs := LegacyProfileRecordSeparator()
    us := LegacyProfileUnitSeparator()
    for rec in StrSplit(raw, rs) {
        rec := Trim(rec)
        if (rec = "") {
            continue
        }
        if (StrLower(rec) = LegacyBlankProfileMarker()) {
            profiles.Push({ trigger: "", loop: false, blockOriginal: false, skillsRaw: "" })
            continue
        }
        parts := StrSplit(rec, us,, 5)
        ; 旧版可能 5 段（trigger, loop, blockOriginal, 出手延迟, skills），出手延迟已废弃
        if (parts.Length >= 5) {
            trigger := parts[1]
            loopOn := Trim(parts[2]) = "1"
            blockOriginal := parts.Length >= 3 && Trim(parts[3]) = "1"
            skillsRaw := ConvertLegacySkills(parts[5])
        } else if (parts.Length >= 4) {
            trigger := parts[1]
            loopOn := Trim(parts[2]) = "1"
            blockOriginal := Trim(parts[3]) = "1"
            skillsRaw := ConvertLegacySkills(parts[4])
        } else if (parts.Length >= 2) {
            trigger := parts[1]
            loopOn := Trim(parts[2]) = "1"
            blockOriginal := false
            skillsRaw := parts.Length >= 3 ? ConvertLegacySkills(parts[3]) : ""
        } else {
            continue
        }
        profiles.Push({ trigger: trigger, loop: loopOn, blockOriginal: blockOriginal, skillsRaw: skillsRaw })
    }
    return profiles
}

MigrateConfig(path, dryRun) {
    if !FileExist(path) {
        MsgBox("找不到配置文件：" path, "一键连招配置迁移", "Icon!")
        return
    }
    changed := []
    sections := IniRead(path)
    for sec in StrSplit(sections, "`n", "`r") {
        sec := Trim(sec)
        if (SubStr(sec, 1, 3) != "预设:") {
            continue
        }
        if InStr(sec, ".Combo.") {
            continue
        }
        raw := ""
        try raw := IniRead(path, sec, "ComboProfiles", "")
        if (Trim(String(raw)) = "") {
            continue
        }
        profiles := ParseLegacyProfiles(raw)
        presetName := SubStr(sec, 4)
        changed.Push(sec "（" profiles.Length " 套方案）")
        if dryRun {
            continue
        }
        ; 写入新格式子节
        loop profiles.Length {
            p := profiles[A_Index]
            section := "预设:" presetName ".Combo." A_Index
            loopOn := p.loop ? "1" : "0"
            blockOriginal := p.blockOriginal ? "1" : "0"
            IniWrite(p.trigger, path, section, "Trigger")
            IniWrite(loopOn, path, section, "Loop")
            IniWrite(blockOriginal, path, section, "BlockOriginal")
            IniWrite(p.skillsRaw, path, section, "Skills")
        }
        ; 删除主节下的旧 ComboProfiles key
        IniDelete(path, sec, "ComboProfiles")
    }
    if (changed.Length = 0) {
        MsgBox("没有需要迁移的一键连招配置。", "一键连招配置迁移", "Iconi")
        return
    }
    msg := dryRun ? "以下配置需要迁移：" : "已迁移以下配置："
    for line in changed {
        msg .= "`n" line
    }
    MsgBox(msg, "一键连招配置迁移", "Iconi")
}

MigrateConfig(ConfigPathFromArgs(), IsDryRun())
