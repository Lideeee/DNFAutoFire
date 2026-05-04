; 始终使用主脚本目录下的 config.ini（勿用裸 "config.ini"，否则 CWD 非脚本目录时读写不一致、列表为空）
ConfigIniPath() => A_ScriptDir "\config.ini"

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
    presetsName := StrReplace(presetsName, "`|")
    IniWrite(value, ConfigIniPath(), "预设:" presetsName, type)
}

; 读取预设
LoadPreset(presetsName, type, default := ""){
    if(default == ""){
        default := A_Space
    }
    presetsName := StrReplace(presetsName, "`|")
    return IniRead(ConfigIniPath(), "预设:" presetsName, type, default)
}

; 字符串型预设项安全读取：Trim 节名与值；缺失/空/仅空白均返回空串，不把空白当成默认值（布尔/数值仍用 LoadPreset）
LoadPresetSafe(presetsName, type) {
    presetsName := Trim(presetsName)
    if (presetsName = "") {
        return ""
    }
    return Trim(LoadPreset(presetsName, type, ""))
}

; 删除预设
DeletePreset(presetsName){
    presetsName := StrReplace(presetsName, "`|")
    IniDelete(ConfigIniPath(), "预设:" presetsName)
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
        if (SubStr(sec, 1, 3) = "预设:") {
            presetList.Push(SubStr(sec, 4))
        }
    }
    return ApplyPresetOrder(presetList)
}

; 将传入的预设列表按保存顺序重排：先取 PresetOrder 中仍存在的项，再补齐未记录的项
ApplyPresetOrder(presetList) {
    ordered := []
    used := Map()
    orderRaw := LoadConfig("PresetOrder", "")
    if (orderRaw != "") {
        for item in StrSplit(orderRaw, "|") {
            item := Trim(item)
            if (item = "" || used.Has(item)) {
                continue
            }
            if IsValueInArray(item, presetList) {
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

SavePresetOrder(presetList) {
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
    SaveConfig("PresetOrder", orderRaw)
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
    SaveLastPreset(DEFAULT_PRESET_NAME)
    SavePreset(DEFAULT_PRESET_NAME, "keys", "")
    SavePreset(DEFAULT_PRESET_NAME, "LvRenState", false)
    SavePreset(DEFAULT_PRESET_NAME, "GuanYuState", false)
    SavePreset(DEFAULT_PRESET_NAME, "PetSkillState", false)
    SavePreset(DEFAULT_PRESET_NAME, "ZhanFaState", false)
    SavePreset(DEFAULT_PRESET_NAME, "JianZongState", false)
    SavePreset(DEFAULT_PRESET_NAME, "AutoRunState", false)
    SavePreset(DEFAULT_PRESET_NAME, "ComboState", false)
    SavePreset(DEFAULT_PRESET_NAME, "MainAutoFireInterval", 20)
    SavePreset(DEFAULT_PRESET_NAME, "AutoRunLeftKey", "Left")
    SavePreset(DEFAULT_PRESET_NAME, "AutoRunRightKey", "Right")
    SavePreset(DEFAULT_PRESET_NAME, "ComboTriggerKey", "")
    SavePreset(DEFAULT_PRESET_NAME, "ComboLoopMode", false)
    SavePreset(DEFAULT_PRESET_NAME, "ComboSkills", "")
}

; 以字符的方式读取所有预设
LoadAllPresetString(){
    presetList := LoadAllPreset()
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

; 保存上次的预设
SaveLastPreset(presetName){
    SaveConfig("LastPreset", presetName)
}

; 读取上次的预设
LoadLastPreset(){
    return LoadConfig("LastPreset")
}

; 读取上次预设名（已 Trim；未配置或占位时可能为空，不宜直接用于节名）
LoadLastPresetTrimmed() {
    return Trim(LoadLastPreset())
}

; 克隆配置
ClonePreset(presetName){
    config := IniRead(ConfigIniPath(), "预设:" presetName)
    IniWrite(config, ConfigIniPath(), "预设:" presetName "-克隆")
}