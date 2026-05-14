class SendIPRuntime {
    static _downStates := Map()
    static _sendLocks := Map()

    static NormalizePressDuration(pressDurationMs, defaultMs := 8) {
        return PresetManager.NormalizePressDuration(pressDurationMs, defaultMs)
    }

    static Tap(keyCode, pressDurationMs := 8) {
        keyCode := Trim(keyCode "")
        if (keyCode = "") {
            return false
        }
        pressDurationMs := this.NormalizePressDuration(pressDurationMs)
        Critical("On")
        try {
            SetKeyDelay(-1, -1)
            SendEvent("{Blind}{" keyCode " Down}")
            if (pressDurationMs > 0) {
                Sleep(pressDurationMs)
            }
            SendEvent("{Blind}{" keyCode " Up}")
            this._downStates[keyCode] := false
            return true
        } finally {
            Critical("Off")
        }
    }

    static PulseHeld(keyCode, holdMs := 8) {
        keyCode := Trim(keyCode "")
        if (keyCode = "") {
            return false
        }
        if this._sendLocks.Get(keyCode, false) {
            return false
        }
        holdMs := this.NormalizePressDuration(holdMs)
        this._sendLocks[keyCode] := true
        Critical("On")
        try {
            SetKeyDelay(-1, -1)
            SendEvent("{Blind}{" keyCode " Up}")
            this._downStates[keyCode] := false
            if (holdMs > 0) {
                Sleep(holdMs)
            }
            SendEvent("{Blind}{" keyCode " Down}")
            this._downStates[keyCode] := true
            return true
        } finally {
            this._sendLocks[keyCode] := false
            Critical("Off")
        }
    }

    static Release(keyCode) {
        keyCode := Trim(keyCode "")
        if (keyCode = "") {
            return
        }
        Critical("On")
        try {
            SetKeyDelay(-1, -1)
            SendEvent("{Blind}{" keyCode " Up}")
            this._downStates[keyCode] := false
        } finally {
            Critical("Off")
        }
    }

    static ReleaseMany(tokens) {
        seen := Map()
        if !IsObject(tokens) {
            return
        }
        for token in tokens {
            token := Trim(token "")
            if (token = "" || seen.Has(token)) {
                continue
            }
            seen[token] := true
            this.Release(token)
        }
    }

    static ReleaseAll() {
        tokens := []
        for token, isDown in this._downStates {
            if isDown {
                tokens.Push(token)
            }
        }
        this.ReleaseMany(tokens)
    }
}

SendIP_Tap(keyCode, pressDurationMs := 8) {
    return SendIPRuntime.Tap(keyCode, pressDurationMs)
}

SendIP_PulseHeld(keyCode, holdMs := 8) {
    return SendIPRuntime.PulseHeld(keyCode, holdMs)
}

SendIP_Release(keyCode) {
    SendIPRuntime.Release(keyCode)
}

SendIP_ReleaseMany(tokens) {
    SendIPRuntime.ReleaseMany(tokens)
}

SendIP_ReleaseAll() {
    SendIPRuntime.ReleaseAll()
}

CollectSyntheticReleaseTokens(presetName := unset) {
    tokens := []
    seen := Map()
    if IsSet(presetName) {
        presetName := Trim(presetName "")
    } else {
        try {
            presetName := Trim(SessionState.GetCurrentPreset() "")
        } catch {
            presetName := ""
        }
    }
    try for keyName in SessionState.AutoFireEnableKeys {
        SendIP_CollectToken(tokens, seen, GetKeycode.ToSendToken(GetKeycode.CanonMainKey(keyName)))
    }
    if (presetName = "") {
        return tokens
    }
    if PresetExFeatures.IsOn("LvRen", presetName) {
        SendIP_CollectToken(tokens, seen, GetKeycode.ToSendToken(GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "LvRenShotKey"))))
    }
    if PresetExFeatures.IsOn("GuanYu", presetName) {
        SendIP_CollectToken(tokens, seen, GetKeycode.ToSendToken(GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "GuanYuShotKey"))))
    }
    if PresetExFeatures.IsOn("PetSkill", presetName) {
        SendIP_CollectToken(tokens, seen, GetKeycode.ToSendToken(GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "PetSkillShotKey"))))
    }
    if PresetExFeatures.IsOn("ZhanFa", presetName) {
        SendIP_CollectToken(tokens, seen, GetKeycode.ToSendToken(GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "ZhanFaShotKey"))))
    }
    if PresetExFeatures.IsOn("JianZong", presetName) {
        SendIP_CollectToken(tokens, seen, GetKeycode.ToSendToken(GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "JianZongSkillKey"))))
    }
    if PresetExFeatures.IsOn("AutoRun", presetName) {
        SendIP_CollectToken(tokens, seen, GetKeycode.ToSendToken(GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "AutoRunLeftKey"))))
        SendIP_CollectToken(tokens, seen, GetKeycode.ToSendToken(GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "AutoRunRightKey"))))
    }
    if PresetExFeatures.IsOn("Combo", presetName) {
        for profile in ComboLoadProfilesFromPreset(presetName) {
            if !IsObject(profile) || !IsObject(profile.skills) {
                continue
            }
            for item in profile.skills {
                if !IsObject(item) {
                    continue
                }
                SendIP_CollectToken(tokens, seen, GetKeycode.ToSendToken(GetKeycode.CanonMainKey(item.key)))
            }
        }
    }
    return tokens
}

SendIP_CollectToken(tokens, seen, token) {
    token := Trim(token "")
    if (token = "" || seen.Has(token)) {
        return
    }
    seen[token] := true
    tokens.Push(token)
}
