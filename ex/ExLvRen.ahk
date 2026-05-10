; 旅人：与战法相同模式——监听键任一按住则以主间隔发发射键（KeyRouter + 主进程）

global _LvRenKeyHeld := Map()
global _LvRenActiveCount := 0
global _LvRenShotKeyCode := ""
global _LvRenShotIntervalMs := 20
global _LvRenHotkeySubs := []

LvRenUnregisterHotkeys() {
    global _LvRenKeyHeld, _LvRenActiveCount, _LvRenHotkeySubs
    SetTimer(LvRenShotTick, 0)
    _LvRenKeyHeld := Map()
    _LvRenActiveCount := 0
    for sub in _LvRenHotkeySubs {
        KeyRouter.UnsubscribeDown(sub.id, sub.downFn)
        KeyRouter.UnsubscribeUp(sub.id, sub.upFn)
    }
    _LvRenHotkeySubs := []
}

LvRenRegisterHotkeys() {
    global _LvRenShotKeyCode, _LvRenShotIntervalMs
    LvRenUnregisterHotkeys()
    if !PresetExFeatures.IsOn("LvRen") {
        return
    }
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    if !LoadPreset(presetName, "LvRenState", false) {
        return
    }
    shotKey := GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "LvRenShotKey"))
    if (shotKey = "") {
        return
    }
    skillKeys := []
    for sk in LvRenLoadKeys(presetName) {
        c := GetKeycode.CanonMainKey(sk)
        if (c != "") {
            skillKeys.Push(c)
        }
    }
    skillKeys := LvRenUniqueSkillKeysByPressKey(skillKeys)
    if (skillKeys.Length = 0) {
        return
    }
    intervalMs := Round(LoadPreset(presetName, "MainAutoFireInterval", 20) + 0)
    if (intervalMs < 1) {
        intervalMs := 1
    } else if (intervalMs > 200) {
        intervalMs := 200
    }
    _LvRenShotKeyCode := GetKeycode.ToSendToken(shotKey)
    if (_LvRenShotKeyCode = "") {
        return
    }
    _LvRenShotIntervalMs := intervalMs

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
        downFn := LvRenSkillDown.Bind(pressKey)
        upFn := LvRenSkillUp.Bind(pressKey)
        if !KeyRouter.SubscribeDown(id, downFn) {
            continue
        }
        if !KeyRouter.SubscribeUp(id, upFn) {
            KeyRouter.UnsubscribeDown(id, downFn)
            continue
        }
        _LvRenHotkeySubs.Push({ id: id, downFn: downFn, upFn: upFn })
    }
}

LvRenUniqueSkillKeysByPressKey(skillKeys) {
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
        if (pk = "") || seen.Has(pk) {
            continue
        }
        seen[pk] := true
        out.Push(sk)
    }
    return out
}

LvRenSkillDown(pressKey, *) {
    global _LvRenKeyHeld, _LvRenActiveCount, _LvRenShotIntervalMs
    if _LvRenKeyHeld.Get(pressKey, false) {
        return
    }
    _LvRenKeyHeld[pressKey] := true
    _LvRenActiveCount += 1
    if (_LvRenActiveCount = 1) {
        LvRenShotTick()
        SetTimer(LvRenShotTick, _LvRenShotIntervalMs)
    }
}

LvRenSkillUp(pressKey, *) {
    global _LvRenKeyHeld, _LvRenActiveCount
    if !_LvRenKeyHeld.Get(pressKey, false) {
        return
    }
    _LvRenKeyHeld[pressKey] := false
    _LvRenActiveCount -= 1
    if (_LvRenActiveCount <= 0) {
        _LvRenActiveCount := 0
        SetTimer(LvRenShotTick, 0)
    }
}

LvRenShotTick() {
    global _LvRenShotKeyCode
    if !GameContext.IsActiveNow() {
        return
    }
    static busy := false
    if busy {
        return
    }
    busy := true
    try {
        SendIP(_LvRenShotKeyCode)
    } finally {
        busy := false
    }
}

LvRenLoadKeys(presetName) {
    skillKeysConfig := LoadPresetSafe(presetName, "LvRenSkillKeys")
    keys := []
    for item in StrSplit(skillKeysConfig, "|") {
        item := Trim(item)
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}
