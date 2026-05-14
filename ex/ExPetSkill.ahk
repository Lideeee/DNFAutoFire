; 宠物技能：纯按下边沿触发；每个监听键按下只发一次。

class ExPetSkill {
    static _ctx := 0

    static Run() {
        presetName := LoadLastPresetTrimmed()
        if (presetName = "" || !LoadPreset(presetName, "PetSkillState", false)) {
            return
        }
        shotKey := GetKeycode.CanonMainKey(LoadPresetSafe(presetName, "PetSkillShotKey"))
        if (shotKey = "") {
            return
        }
        triggerKeys := PetSkillUniqueSkillKeysByPressKey(PetSkillLoadKeys(presetName))
        if (triggerKeys.Length = 0) {
            return
        }
        sendToken := GetKeycode.ToSendToken(shotKey)
        if (sendToken = "") {
            return
        }
        entries := Map()
        for keyName in triggerKeys {
            canon := GetKeycode.CanonMainKey(keyName)
            scID := GetKeycode.ToRouterId(canon)
            if (scID = "") {
                continue
            }
            entries[scID] := {
                scID: scID,
                isHeld: false,
                downFn: ObjBindMethod(ExPetSkill, "Down", scID),
                upFn: ObjBindMethod(ExPetSkill, "Up", scID)
            }
        }
        if (entries.Count = 0) {
            return
        }
        this._ctx := {
            sendToken: sendToken,
            triggerEntries: entries
        }
        OnExit(ObjBindMethod(ExPetSkill, "OnExit"))
        this._EnableHooks()
        Suspend(false)
        loop {
            Sleep(100)
        }
    }

    static _EnableHooks() {
        for _, entry in this._ctx.triggerEntries {
            HotIfWinActive("ahk_group DNF")
            Hotkey("~$" entry.scID, entry.downFn, "On")
            Hotkey("~$" entry.scID " up", entry.upFn, "On")
            HotIf()
        }
    }

    static _DisableHooks() {
        ctx := this._ctx
        if !IsObject(ctx) {
            return
        }
        for _, entry in ctx.triggerEntries {
            try {
                HotIfWinActive("ahk_group DNF")
                try Hotkey("~$" entry.scID, "Off")
                try Hotkey("~$" entry.scID " up", "Off")
                HotIf()
            } catch {
                try HotIf()
            }
        }
    }

    static Down(scID, *) {
        ctx := this._ctx
        entry := ctx.triggerEntries.Get(scID, "")
        if !IsObject(entry) || entry.isHeld {
            return
        }
        entry.isHeld := true
        SendIP_Tap(ctx.sendToken)
    }

    static Up(scID, *) {
        entry := this._ctx.triggerEntries.Get(scID, "")
        if IsObject(entry) {
            entry.isHeld := false
        }
    }

    static OnExit(exitReason, exitCode) {
        this._DisableHooks()
    }
}

ExPetSkill_Run() {
    ExPetSkill.Run()
}

PetSkillUniqueSkillKeysByPressKey(skillKeys) {
    seen := Map()
    out := []
    if !IsObject(skillKeys) {
        return out
    }
    for sk in skillKeys {
        canon := GetKeycode.CanonMainKey(sk)
        if (canon = "") {
            continue
        }
        probeKey := GetKeycode.ToProbeKey(canon)
        if (probeKey = "" || seen.Has(probeKey)) {
            continue
        }
        seen[probeKey] := true
        out.Push(canon)
    }
    return out
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
