; 宠物技能：监听键边沿发一发发射键；KeyRouter + 主进程

global _PetSkillShotKeyCode := ""
global _PetSkillHotkeySubs := []

PetSkillUnregisterHotkeys() {
    global _PetSkillHotkeySubs
    for sub in _PetSkillHotkeySubs {
        KeyRouter.UnsubscribeDown(sub.id, sub.downFn)
    }
    _PetSkillHotkeySubs := []
}

PetSkillRegisterHotkeys() {
    global _PetSkillShotKeyCode, _PetSkillHotkeySubs
    PetSkillUnregisterHotkeys()
    if !PresetExFeatures.IsOn("PetSkill") {
        return
    }
    presetName := GetNowSelectPreset()
    if (presetName = "") {
        return
    }
    if !LoadPreset(presetName, "PetSkillState", false) {
        return
    }
    shotKey := GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "PetSkillShotKey"))
    if (shotKey = "") {
        return
    }
    skillKeys := []
    for sk in PetSkillLoadKeys(presetName) {
        c := GetKeycode.CanonMainKey(sk)
        if (c != "") {
            skillKeys.Push(c)
        }
    }
    skillKeys := PetSkillUniqueSkillKeysByPressKey(skillKeys)
    if (skillKeys.Length = 0) {
        return
    }
    _PetSkillShotKeyCode := GetKeycode.ToSendToken(shotKey)
    if (_PetSkillShotKeyCode = "") {
        return
    }

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
        downFn := PetSkillOnDown.Bind(pressKey)
        if !KeyRouter.SubscribeDown(id, downFn) {
            continue
        }
        _PetSkillHotkeySubs.Push({ id: id, downFn: downFn })
    }
}

PetSkillUniqueSkillKeysByPressKey(skillKeys) {
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

PetSkillOnDown(pressKey, *) {
    global _PetSkillShotKeyCode, _PetSkillHotkeySubs
    if !GameContext.IsActiveNow() {
        return
    }
    try {
        SendIP(_PetSkillShotKeyCode)
    } catch {
    }
}

PetSkillLoadKeys(presetName) {
    skillKeysConfig := LoadPresetSafe(presetName, "PetSkillSkillKeys")
    keys := []
    for item in StrSplit(skillKeysConfig, "|") {
        item := Trim(item)
        if (item != "") {
            keys.Push(item)
        }
    }
    return keys
}
