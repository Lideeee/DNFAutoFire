; 关羽：按下监听键边沿后延迟一发发射键；KeyRouter + 主进程

global _GuanYuShotKeyCode := ""
global _GuanYuDelayMs := 300
global _GuanYuPendingTimerByPressKey := Map()
global _GuanYuHotkeySubs := []

GuanYuUnregisterHotkeys() {
    global _GuanYuPendingTimerByPressKey, _GuanYuHotkeySubs
    for pressKey, fn in _GuanYuPendingTimerByPressKey {
        try SetTimer(fn, 0)
    }
    _GuanYuPendingTimerByPressKey := Map()
    for sub in _GuanYuHotkeySubs {
        KeyRouter.UnsubscribeDown(sub.id, sub.downFn)
        KeyRouter.UnsubscribeUp(sub.id, sub.upFn)
    }
    _GuanYuHotkeySubs := []
}

GuanYuRegisterHotkeys() {
    global _GuanYuShotKeyCode, _GuanYuDelayMs, _GuanYuHotkeySubs
    GuanYuUnregisterHotkeys()
    if !PresetExFeatures.IsOn("GuanYu") {
        return
    }
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    if !LoadPreset(presetName, "GuanYuState", false) {
        return
    }
    shotKey := GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "GuanYuShotKey"))
    if (shotKey = "") {
        return
    }
    skillKeys := []
    for sk in GuanYuLoadKeys(presetName) {
        c := GetKeycode.CanonMainKey(sk)
        if (c != "") {
            skillKeys.Push(c)
        }
    }
    skillKeys := GuanYuUniqueSkillKeysByPressKey(skillKeys)
    if (skillKeys.Length = 0) {
        return
    }
    delayMs := Round(LoadPreset(presetName, "GuanYuDelay", 300) + 0)
    if (delayMs < 20) {
        delayMs := 20
    } else if (delayMs > 500) {
        delayMs := 500
    }
    _GuanYuShotKeyCode := GetKeycode.ToSendToken(shotKey)
    if (_GuanYuShotKeyCode = "") {
        return
    }
    _GuanYuDelayMs := delayMs

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
        downFn := GuanYuOnSkillDown.Bind(pressKey)
        upFn := GuanYuOnSkillUp.Bind(pressKey)
        if !KeyRouter.SubscribeDown(id, downFn) {
            continue
        }
        if !KeyRouter.SubscribeUp(id, upFn) {
            KeyRouter.UnsubscribeDown(id, downFn)
            continue
        }
        _GuanYuHotkeySubs.Push({ id: id, downFn: downFn, upFn: upFn })
    }
}

GuanYuUniqueSkillKeysByPressKey(skillKeys) {
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

GuanYuOnSkillDown(pressKey, *) {
    global _GuanYuDelayMs, _GuanYuPendingTimerByPressKey
    fn := GuanYuExecuteDelayed.Bind(pressKey)
    _GuanYuPendingTimerByPressKey[pressKey] := fn
    SetTimer(fn, -_GuanYuDelayMs)
}

GuanYuOnSkillUp(pressKey, *) {
    global _GuanYuPendingTimerByPressKey
    if _GuanYuPendingTimerByPressKey.Has(pressKey) {
        try SetTimer(_GuanYuPendingTimerByPressKey[pressKey], 0)
        _GuanYuPendingTimerByPressKey.Delete(pressKey)
    }
}

GuanYuExecuteDelayed(pressKey, *) {
    global _GuanYuShotKeyCode, _GuanYuPendingTimerByPressKey
    if _GuanYuPendingTimerByPressKey.Has(pressKey) {
        _GuanYuPendingTimerByPressKey.Delete(pressKey)
    }
    if !GameContext.IsActiveNow() {
        return
    }
    try {
        SendIP(_GuanYuShotKeyCode)
    } catch {
    }
}

GuanYuLoadKeys(presetName) {
    skillKeysConfig := LoadPresetSafe(presetName, "GuanYuSkillKeys")
    keys := []
    for item in StrSplit(skillKeysConfig, "|") {
        item := Trim(item)
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}
