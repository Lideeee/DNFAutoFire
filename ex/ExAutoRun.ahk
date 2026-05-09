; 自动奔跑：须持续按住满 30ms 才 SendEvent 一串 Down-Up-Down（未满则抬起取消）；Critical 包裹发送。

class ExAutoRun {
    static _sides := Map()
    static _registered := false

    static RegisterHotkeys() {
        this.UnregisterHotkeys()
        if !PresetExFeatures.IsOn("AutoRun") {
            return
        }
        presetName := GetNowSelectPreset()
        if (presetName = "") {
            return
        }
        leftKey := LoadPresetSafe(presetName, "AutoRunLeftKey")
        rightKey := LoadPresetSafe(presetName, "AutoRunRightKey")
        if (leftKey = "")
            leftKey := "Left"
        if (rightKey = "")
            rightKey := "Right"
        lCanon := GetKeycode.CanonMainKey(leftKey)
        if (lCanon = "")
            lCanon := "Left"
        rCanon := GetKeycode.CanonMainKey(rightKey)
        if (rCanon = "")
            rCanon := "Right"

        sides := Map()
        this._addSide(sides, "R", rCanon)
        this._addSide(sides, "L", lCanon)

        subscribed := []
        for _, s in sides {
            if !KeyRouter.SubscribeDown(s.scID, s.downFn) {
                ExAutoRun._rollbackSubs(subscribed)
                return
            }
            if !KeyRouter.SubscribeUp(s.scID, s.upFn) {
                KeyRouter.UnsubscribeDown(s.scID, s.downFn)
                ExAutoRun._rollbackSubs(subscribed)
                return
            }
            subscribed.Push(s)
        }
        this._sides := sides
        this._registered := true
    }

    static _rollbackSubs(subscribed) {
        for s in subscribed {
            KeyRouter.UnsubscribeDown(s.scID, s.downFn)
            KeyRouter.UnsubscribeUp(s.scID, s.upFn)
        }
    }

    static _addSide(sides, tag, logicalKey) {
        scID := GetKeycode.ToRouterId(logicalKey)
        kc := GetKeycode.ToSendToken(logicalKey)
        seq := "{Blind}{" kc " Down}{" kc " Up}{" kc " Down}"
        sides[tag] := {
            scID: scID,
            seq: seq,
            held: false,
            timerFn: ObjBindMethod(ExAutoRun, "Pulse", tag),
            downFn: ObjBindMethod(ExAutoRun, "Down", tag),
            upFn: ObjBindMethod(ExAutoRun, "Up", tag),
        }
    }

    static UnregisterHotkeys() {
        for _, s in this._sides {
            SetTimer(s.timerFn, 0)
            if IsObject(s) {
                KeyRouter.UnsubscribeDown(s.scID, s.downFn)
                KeyRouter.UnsubscribeUp(s.scID, s.upFn)
            }
        }
        this._sides := Map()
        this._registered := false
    }

    static Down(tag, *) {
        s := ExAutoRun._sides.Get(tag, "")
        if !IsObject(s) {
            return
        }
        s.held := true
        SetTimer(s.timerFn, -30)
    }

    static Up(tag, *) {
        s := ExAutoRun._sides.Get(tag, "")
        if !IsObject(s) {
            return
        }
        s.held := false
        SetTimer(s.timerFn, 0)
    }

    static Pulse(tag) {
        s := ExAutoRun._sides.Get(tag, "")
        if !IsObject(s) || !s.held {
            return
        }
        if !GameContext.IsActiveNow() {
            return
        }
        Critical("On")
        try {
            SendEvent(s.seq)
        } finally {
            Critical("Off")
        }
    }
}
