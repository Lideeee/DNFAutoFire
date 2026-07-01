; 始终使用主脚本目录下的 config.ini（勿用裸 "config.ini"，否则 CWD 非脚本目录时读写不一致、列表为空）
ConfigIniPath() => A_ScriptDir "\config.ini"

NormalizePresetName(presetName) {
    return Trim(StrReplace(presetName, "`|"))
}

; 保存软件设置
SaveConfig(type, value){
    IniWrite(value, ConfigIniPath(), "设置", type)
}

; 读取软件设置
LoadConfig(type, default := ""){
    if(default == ""){
        default := A_Space
    }
    return IniRead(ConfigIniPath(), "设置", type, default)
}

; 删除软件设置
DeleteConfig(type){
    IniDelete(ConfigIniPath(), "设置", type)
}

; 保存预设
SavePreset(presetsName, type, value){
    presetsName := NormalizePresetName(presetsName)
    IniWrite(value, ConfigIniPath(), "预设:" presetsName, type)
}

; 读取预设
LoadPreset(presetsName, type, default := ""){
    if(default == ""){
        default := A_Space
    }
    presetsName := NormalizePresetName(presetsName)
    return IniRead(ConfigIniPath(), "预设:" presetsName, type, default)
}

; 删除预设
DeletePreset(presetsName){
    presetsName := NormalizePresetName(presetsName)
    path := ConfigIniPath()
    IniDelete(path, "预设:" presetsName)
    ; 连带删除所有一键连招子节
    srcPrefix := "预设:" presetsName ".Combo."
    srcPrefixLen := StrLen(srcPrefix)
    sections := ""
    try sections := IniRead(path)
    catch {
        return
    }
    for sec in StrSplit(sections, "`n", "`r") {
        sec := Trim(sec)
        if (SubStr(sec, 1, srcPrefixLen) != srcPrefix) {
            continue
        }
        tail := SubStr(sec, srcPrefixLen + 1)
        if !RegExMatch(tail, "^[1-9][0-9]*$") {
            continue
        }
        try IniDelete(path, sec)
    }
}

; 保存预设的连发按键
SavePresetKeys(presetsName, keys){
    keysString := ""
    if !IsObject(keys) {
        SavePreset(presetsName, "keys", keysString)
        return
    }
    try keyCount := keys.Length
    catch {
        keyCount := 0
    }
    loop keyCount
    {
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
    SavePreset(presetsName, "keys", keysString)
}

; 读取预设的连发按键
LoadPresetKeys(presetsName){
    config := LoadPreset(presetsName, "keys")
    keys := []
    for item in StrSplit(config, "|")
    {
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}

; 单键毫秒表：`键名:毫秒|键名:毫秒`（键名与主界面键帽 Name 一致）
StrToMsMap(s) {
    m := Map()
    s := Trim(String(s))
    if (s = "") {
        return m
    }
    for part in StrSplit(s, "|") {
        part := Trim(part)
        if (part = "") {
            continue
        }
        c := InStr(part, ":")
        if (!c) {
            continue
        }
        kn := Trim(SubStr(part, 1, c - 1))
        if (kn = "" || kn = "Esc" || kn = "Win") {
            continue
        }
        ms := Round(Trim(SubStr(part, c + 1)) + 0)
        if (ms < 0) {
            ms := 0
        }
        m[kn] := ms
    }
    return m
}

MsMapToStr(m) {
    if !IsObject(m) {
        return ""
    }
    parts := []
    for kn, ms in m {
        kn := Trim(String(kn))
        if (kn = "") {
            continue
        }
        ms := Round(ms + 0)
        if (ms < 0) {
            ms := 0
        }
        parts.Push(kn ":" ms)
    }
    if (parts.Length = 0) {
        return ""
    }
    out := parts[1]
    loop parts.Length - 1 {
        out .= "|" parts[A_Index + 1]
    }
    return out
}

; 按 [设置] 中 PresetOrder（| 分隔）与当前 INI 节合并排序；缺省顺序为节扫描顺序
ApplyPresetOrder(presetList) {
    ordered := []
    used := Map()
    orderRaw := ""
    try {
        orderRaw := Trim(IniRead(ConfigIniPath(), "设置", "PresetOrder", ""))
    } catch {
        orderRaw := ""
    }
    if (orderRaw != "") {
        for item in StrSplit(orderRaw, "|") {
            item := Trim(item)
            if (item = "" || used.Has(item)) {
                continue
            }
            for _, p in presetList {
                if (p = item) {
                    ordered.Push(item)
                    used[item] := true
                    break
                }
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

; 将当前预设名顺序写入 config.ini（与参考项目 DNFAutoFire 一致，供列表拖动排序）
SavePresetOrder(presetList) {
    orderRaw := ""
    if IsObject(presetList) {
        loop presetList.Length {
            if !presetList.Has(A_Index) {
                continue
            }
            name := Trim(String(presetList[A_Index]))
            if (name = "") {
                continue
            }
            orderRaw .= name "|"
        }
    }
    if (StrLen(orderRaw) > 0) {
        orderRaw := SubStr(orderRaw, 1, StrLen(orderRaw) - 1)
    }
    SaveConfig("PresetOrder", orderRaw)
}

; 读取所有预设（INI 节名形如 [预设:默认]，不能按裸字符串比较）
LoadAllPreset(){
    presetList := []
    if !FileExist(ConfigIniPath()) {
        return presetList
    }
    ; v2：IniRead(file) 返回“节名列表”（每行一个），不是整个文件文本
    sections := IniRead(ConfigIniPath())
    for sec in StrSplit(sections, "`n", "`r") {
        sec := Trim(sec)
        if (sec = "")
            continue
        if (SubStr(sec, 1, 3) != "预设:") {
            continue
        }
        ; 一键连招子节形如 [预设:职业名.Combo.N]，不计入预设列表
        if InStr(sec, ".Combo.") {
            continue
        }
        presetList.Push(SubStr(sec, 4))
    }
    return ApplyPresetOrder(presetList)
}

; 首次运行：无 config.ini 或无任何预设节时，写入默认预设与基础设置
DEFAULT_PRESET_NAME := "默认"

EnsureConfigInitialized() {
    path := ConfigIniPath()
    if !FileExist(path) {
        _CreateDefaultConfigIni()
        return
    }
    if (LoadAllPreset().Length = 0) {
        SavePreset(DEFAULT_PRESET_NAME, "keys", "")
        SaveLastPreset(DEFAULT_PRESET_NAME)
    }
}

_CreateDefaultConfigIni() {
    SaveConfig("SettingAutoStart", false)
    SaveConfig("SettingOnSystemStart", false)
    SaveConfig("SettingBlockWin", false)
    SaveConfig("SettingSubprocessErrorLog", false)
    SaveConfig("SettingCloseToTray", false)
    SaveLastPreset(DEFAULT_PRESET_NAME)
    CreateBlankPreset(DEFAULT_PRESET_NAME)
}

; 以字符的方式读取所有预设
LoadAllPresetString(){
    presetList := LoadAllPreset()
    if (presetList.Length = 0) {
        return ""
    }
    presetListStr := ""
    for i, value in presetList {
        presetListStr := presetListStr . value . "|"
    }
    presetListStr := SubStr(presetListStr, 1, StrLen(presetListStr) - 1)
    return presetListStr
}

; 保存上次的预设
SaveLastPreset(presetName){
    SaveConfig("LastPreset", presetName)
}

; 读取上次的预设
LoadLastPreset(){
    return LoadConfig("LastPreset")
}

PresetExists(presetName) {
    presetName := NormalizePresetName(presetName)
    if (presetName = "") {
        return false
    }
    for _, item in LoadAllPreset() {
        if (item = presetName) {
            return true
        }
    }
    return false
}

GetFirstPresetName() {
    presetList := LoadAllPreset()
    return presetList.Length > 0 ? presetList[1] : ""
}

ClonePreset(sourcePresetName, targetPresetName) {
    sourcePresetName := NormalizePresetName(sourcePresetName)
    targetPresetName := NormalizePresetName(targetPresetName)
    path := ConfigIniPath()
    ; 复制主节
    config := IniRead(path, "预设:" sourcePresetName)
    IniWrite(config, path, "预设:" targetPresetName)
    ; 连带复制所有一键连招子节 [预设:源.Combo.N] → [预设:目标.Combo.N]
    srcPrefix := "预设:" sourcePresetName ".Combo."
    srcPrefixLen := StrLen(srcPrefix)
    sections := IniRead(path)
    for sec in StrSplit(sections, "`n", "`r") {
        sec := Trim(sec)
        if (SubStr(sec, 1, srcPrefixLen) != srcPrefix) {
            continue
        }
        tail := SubStr(sec, srcPrefixLen + 1)
        if !RegExMatch(tail, "^[1-9][0-9]*$") {
            continue
        }
        body := IniRead(path, sec)
        IniWrite(body, path, "预设:" targetPresetName ".Combo." tail)
    }
}

CreateBlankPreset(presetName) {
    presetName := NormalizePresetName(presetName)
    SavePreset(presetName, "keys", "")
    SavePreset(presetName, "LvRenState", false)
    SavePreset(presetName, "GuanYuState", false)
    SavePreset(presetName, "PetSkillState", false)
    SavePreset(presetName, "ZhanFaState", false)
    SavePreset(presetName, "JianZongState", false)
    SavePreset(presetName, "XiuLuoState", false)
    SavePreset(presetName, "AutoRunState", false)
    SavePreset(presetName, "ComboState", false)
    SavePreset(presetName, "XiuLuoTriggerKey", "")
    SavePreset(presetName, "XiuLuoXKey", "X")
    SavePreset(presetName, "XiuLuoWaveKey1", "1")
    SavePreset(presetName, "XiuLuoWaveKey2", "2")
    SavePreset(presetName, "XiuLuoWaveKey3", "3")
    SavePreset(presetName, "AutoRunLeftKey", "Left")
    SavePreset(presetName, "AutoRunRightKey", "Right")
    SavePreset(presetName, "AutoRunDelay", 30)
    SavePreset(presetName, "AutoRunPauseKey", "")
    SavePreset(presetName, "AutoFireKeyIntervals", "")
    SavePreset(presetName, "AutoFireKeyDelays", "")
}

RenamePreset(oldPresetName, newPresetName) {
    oldPresetName := NormalizePresetName(oldPresetName)
    newPresetName := NormalizePresetName(newPresetName)
    if (oldPresetName = "" || newPresetName = "") {
        return false
    }
    path := ConfigIniPath()
    ; 主节改名
    config := IniRead(path, "预设:" oldPresetName)
    IniWrite(config, path, "预设:" newPresetName)
    IniDelete(path, "预设:" oldPresetName)
    ; 连带重命名所有一键连招子节
    srcPrefix := "预设:" oldPresetName ".Combo."
    srcPrefixLen := StrLen(srcPrefix)
    sections := IniRead(path)
    for sec in StrSplit(sections, "`n", "`r") {
        sec := Trim(sec)
        if (SubStr(sec, 1, srcPrefixLen) != srcPrefix) {
            continue
        }
        tail := SubStr(sec, srcPrefixLen + 1)
        if !RegExMatch(tail, "^[1-9][0-9]*$") {
            continue
        }
        body := IniRead(path, sec)
        IniWrite(body, path, "预设:" newPresetName ".Combo." tail)
        IniDelete(path, sec)
    }
    return true
}
