; 战法自动炫纹：主进程事件驱动。任意「技能监听键」在 DNF 前台按下则启动发射定时器，全松则停；与子进程版轮询逻辑等价。

global _ZhanFaKeyHeld := Map()
global _ZhanFaActiveCount := 0
global _ZhanFaShotKeyCode := ""
global _ZhanFaShotIntervalMs := 20

ZhanFaUnregisterHotkeys() {
    global _ZhanFaKeyHeld, _ZhanFaActiveCount
    SetTimer(ZhanFaShotTick, 0)
    _ZhanFaKeyHeld := Map()
    _ZhanFaActiveCount := 0
}

ZhanFaRegisterHotkeys() {
    global _ZhanFaShotKeyCode, _ZhanFaShotIntervalMs
    ZhanFaUnregisterHotkeys()
    if !PresetExFeatures.IsOn("ZhanFa") {
        return
    }
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    if !LoadPreset(presetName, "ZhanFaState", false) {
        return
    }
    shotKey := GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "ZhanFaShotKey"))
    if (shotKey = "") {
        return
    }
    skillKeys := []
    for sk in ZhanFaLoadKeys(presetName) {
        c := GetKeycode.CanonMainKey(sk)
        if (c != "") {
            skillKeys.Push(c)
        }
    }
    skillKeys := ZhanFaUniqueSkillKeysByPressKey(skillKeys)
    if (skillKeys.Length = 0) {
        return
    }
    intervalMs := Round(LoadPreset(presetName, "MainAutoFireInterval", 20) + 0)
    if (intervalMs < 1) {
        intervalMs := 1
    } else if (intervalMs > 200) {
        intervalMs := 200
    }
    _ZhanFaShotKeyCode := GetKeycode.ToSendToken(shotKey)
    if (_ZhanFaShotKeyCode = "") {
        return
    }
    _ZhanFaShotIntervalMs := intervalMs

    loop skillKeys.Length {
        if !skillKeys.Has(A_Index) {
            continue
        }
        sk := skillKeys[A_Index]
        if (sk = "") {
            continue
        }
        pressKey := GetKeycode.ToProbeKey(sk)
        if (pressKey = "") {
            continue
        }
        id := GetKeycode.ToRouterId(sk)
        downFn := ZhanFaSkillDown.Bind(pressKey)
        upFn := ZhanFaSkillUp.Bind(pressKey)
        KeyRouter.SubscribeDown(id, downFn)
        KeyRouter.SubscribeUp(id, upFn)
    }
}

ZhanFaUniqueSkillKeysByPressKey(skillKeys) {
    seen := Map()
    out := []
    if !IsObject(skillKeys) {
        return out
    }
    n := skillKeys is Array ? skillKeys.Length : 0
    loop n {
        if !skillKeys.Has(A_Index) {
            continue
        }
        sk := skillKeys[A_Index]
        if (sk = "") {
            continue
        }
        pk := GetKeycode.ToProbeKey(sk)
        if (pk = "") {
            continue
        }
        if seen.Has(pk) {
            continue
        }
        seen[pk] := true
        out.Push(sk)
    }
    return out
}

ZhanFaSkillDown(pressKey, *) {
    global _ZhanFaKeyHeld, _ZhanFaActiveCount, _ZhanFaShotIntervalMs
    if _ZhanFaKeyHeld.Get(pressKey, false) {
        return
    }
    _ZhanFaKeyHeld[pressKey] := true
    _ZhanFaActiveCount += 1
    if (_ZhanFaActiveCount = 1) {
        ZhanFaShotTick()
        SetTimer(ZhanFaShotTick, _ZhanFaShotIntervalMs)
    }
}

ZhanFaSkillUp(pressKey, *) {
    global _ZhanFaKeyHeld, _ZhanFaActiveCount
    if !_ZhanFaKeyHeld.Get(pressKey, false) {
        return
    }
    _ZhanFaKeyHeld[pressKey] := false
    _ZhanFaActiveCount -= 1
    if (_ZhanFaActiveCount <= 0) {
        _ZhanFaActiveCount := 0
        SetTimer(ZhanFaShotTick, 0)
    }
}

ZhanFaShotTick() {
    global _ZhanFaShotKeyCode
    if !GameContext.IsActiveNow() {
        return
    }
    static busy := false
    if busy {
        return
    }
    busy := true
    try {
        SendIP(_ZhanFaShotKeyCode)
    } finally {
        busy := false
    }
}

; 读取预设的战法监听键列表（GUI 与注册共用）
ZhanFaLoadKeys(presetName) {
    skillKeysConfig := LoadPresetSafe(presetName, "ZhanFaSkillKeys")
    keys := []
    for item in StrSplit(skillKeysConfig, "|") {
        item := Trim(item)
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}
