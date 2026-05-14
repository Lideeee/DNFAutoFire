; 自动奔跑：子进程内注册方向键热键，持续按住满 30ms 后发送方向脉冲。

class ExAutoRun {
    static _sides := Map()
    static _wasActive := false

    static Run() {
        presetName := LoadLastPresetTrimmed()
        if (presetName = "" || !LoadPreset(presetName, "AutoRunState", false)) {
            return
        }
        leftKey := LoadPresetSafe(presetName, "AutoRunLeftKey")
        rightKey := LoadPresetSafe(presetName, "AutoRunRightKey")
        if (leftKey = "") {
            leftKey := "Left"
        }
        if (rightKey = "") {
            rightKey := "Right"
        }
        lCanon := GetKeycode.CanonMainKey(leftKey)
        if (lCanon = "") {
            lCanon := "Left"
        }
        rCanon := GetKeycode.CanonMainKey(rightKey)
        if (rCanon = "") {
            rCanon := "Right"
        }
        this._sides := Map()
        this._AddSide("R", rCanon)
        this._AddSide("L", lCanon)
        this._wasActive := WinActive("ahk_group DNF") != 0
        OnExit(ObjBindMethod(ExAutoRun, "OnExit"))
        this._EnableHooks()
        Suspend(false)
        loop {
            this._WatchFocusLoss()
            Sleep(50)
        }
    }

    static _AddSide(tag, logicalKey) {
        scID := GetKeycode.ToRouterId(logicalKey)
        sendToken := GetKeycode.ToSendToken(logicalKey)
        probeKey := GetKeycode.ToProbeKey(logicalKey)
        if (scID = "" || sendToken = "" || probeKey = "") {
            return
        }
        this._sides[tag] := {
            scID: scID,
            sendToken: sendToken,
            probeKey: probeKey,
            seq: "{Blind}{" sendToken " Down}{" sendToken " Up}{" sendToken " Down}",
            heldFromEdge: false,
            timerFn: ObjBindMethod(ExAutoRun, "Pulse", tag),
            downFn: ObjBindMethod(ExAutoRun, "Down", tag),
            upFn: ObjBindMethod(ExAutoRun, "Up", tag)
        }
    }

    static _EnableHooks() {
        for _, side in this._sides {
            HotIfWinActive("ahk_group DNF")
            Hotkey("~$" side.scID, side.downFn, "On")
            Hotkey("~$" side.scID " up", side.upFn, "On")
            HotIf()
        }
    }

    static _DisableHooks() {
        for _, side in this._sides {
            try SetTimer(side.timerFn, 0)
            try {
                HotIfWinActive("ahk_group DNF")
                try Hotkey("~$" side.scID, "Off")
                try Hotkey("~$" side.scID " up", "Off")
                HotIf()
            } catch {
                try HotIf()
            }
        }
        this._sides := Map()
    }

    static Down(tag, *) {
        side := this._sides.Get(tag, "")
        if !IsObject(side) {
            return
        }
        if side.heldFromEdge {
            return
        }
        side.heldFromEdge := true
        SetTimer(side.timerFn, -30)
    }

    static Up(tag, *) {
        side := this._sides.Get(tag, "")
        if !IsObject(side) {
            return
        }
        side.heldFromEdge := false
        SetTimer(side.timerFn, 0)
        SendIP_Release(side.sendToken)
    }

    static _WatchFocusLoss() {
        isActive := WinActive("ahk_group DNF") != 0
        if (this._wasActive && !isActive) {
            this._FlushHeldSides()
        }
        this._wasActive := isActive
    }

    static _FlushHeldSides() {
        for _, side in this._sides {
            if !side.heldFromEdge {
                continue
            }
            side.heldFromEdge := false
            try SetTimer(side.timerFn, 0)
            SendIP_Release(side.sendToken)
        }
    }

    static Pulse(tag) {
        side := this._sides.Get(tag, "")
        if !IsObject(side) {
            return
        }
        if !GetKeyState(side.probeKey, "P") || !WinActive("ahk_group DNF") {
            return
        }
        Critical("On")
        try {
            SendEvent(side.seq)
        } finally {
            Critical("Off")
        }
    }

    static OnExit(exitReason, exitCode) {
        this._FlushHeldSides()
        this._DisableHooks()
    }
}
