; 剑宗：按住技能键超过延迟后高频发该键（与原 while 内每 1ms 可 Send 等价）；KeyRouter + 主进程

global _JianZongShotKeyCode := ""
global _JianZongPressKey := ""
global _JianZongDelayMs := 200
global _JianZongHoldStartTick := 0
global _JianZongHotkeySub := 0

JianZongUnregisterHotkeys() {
    SetTimer(JianZongTick, 0)
    global _JianZongPressKey, _JianZongHoldStartTick, _JianZongHotkeySub
    if IsObject(_JianZongHotkeySub) {
        KeyRouter.UnsubscribeDown(_JianZongHotkeySub.id, _JianZongHotkeySub.downFn)
        KeyRouter.UnsubscribeUp(_JianZongHotkeySub.id, _JianZongHotkeySub.upFn)
    }
    _JianZongHotkeySub := 0
    _JianZongPressKey := ""
    _JianZongHoldStartTick := 0
}

JianZongRegisterHotkeys() {
    global _JianZongShotKeyCode, _JianZongPressKey, _JianZongDelayMs
    JianZongUnregisterHotkeys()
    if !PresetExFeatures.IsOn("JianZong") {
        return
    }
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    if !LoadPreset(presetName, "JianZongState", false) {
        return
    }
    skillKey := GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "JianZongSkillKey"))
    if (skillKey = "") {
        return
    }
    delay := Round(LoadPreset(presetName, "JianZongDelay", 200) + 0)
    if (delay < 20) {
        delay := 20
    } else if (delay > 3000) {
        delay := 3000
    }
    _JianZongShotKeyCode := GetKeycode.ToSendToken(skillKey)
    if (_JianZongShotKeyCode = "") {
        return
    }
    _JianZongPressKey := GetKeycode.ToProbeKey(skillKey)
    _JianZongDelayMs := delay

    id := GetKeycode.ToRouterId(skillKey)
    if (id = "") {
        return
    }
    if !KeyRouter.SubscribeDown(id, JianZongOnDown) {
        return
    }
    if !KeyRouter.SubscribeUp(id, JianZongOnUp) {
        KeyRouter.UnsubscribeDown(id, JianZongOnDown)
        return
    }
    _JianZongHotkeySub := { id: id, downFn: JianZongOnDown, upFn: JianZongOnUp }
}

JianZongOnDown(*) {
    global _JianZongHoldStartTick
    _JianZongHoldStartTick := A_TickCount
    SetTimer(JianZongTick, 1)
}

JianZongOnUp(*) {
    SetTimer(JianZongTick, 0)
    global _JianZongHoldStartTick
    _JianZongHoldStartTick := 0
}

JianZongTickShouldStop() {
    global _JianZongPressKey
    if !GameContext.IsActiveNow()
        return true
    if (_JianZongPressKey = "" || !GetKeyState(_JianZongPressKey, "P"))
        return true
    return false
}

JianZongTick() {
    global _JianZongShotKeyCode, _JianZongDelayMs, _JianZongHoldStartTick
    if JianZongTickShouldStop() {
        SetTimer(JianZongTick, 0)
        return
    }
    if (A_TickCount - _JianZongHoldStartTick <= _JianZongDelayMs) {
        return
    }
    static busy := false
    if busy {
        return
    }
    busy := true
    try {
        SendIP(_JianZongShotKeyCode)
    } finally {
        busy := false
    }
}
