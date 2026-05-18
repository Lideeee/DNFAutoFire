#Requires AutoHotkey v2.0

class ToggleGdip {
    static _all := []
    static _timerOn := false

    __New(gui, x, y, tw, th) {
        GdiPlusSession.EnsureStarted()
        this.gui := gui
        this.x := x
        this.y := y
        this.tw := tw
        this.th := th
        this._on := false
        this._animProgress := 0.0
        this._renderState := "normal"
        this._assignBitmap(this._renderBitmap())
        ToggleGdip._all.Push(this)
        ToggleGdip._EnsureTimer()
    }

    _assignBitmap(hbm) {
        optStr := "x" this.x " y" this.y " w" this.tw " h" this.th " +0x120 0xE BackgroundTrans"
        if this.HasOwnProp("ctrl") && IsObject(this.ctrl) {
            try this.ctrl.Value := hbm ? ("HBITMAP:*" hbm) : ""
        } else {
            this.ctrl := this.gui.Add("Picture", optStr, hbm ? ("HBITMAP:*" hbm) : "")
        }
        if hbm {
            try DllCall("gdi32\DeleteObject", "ptr", hbm)
        }
    }

    _renderBitmap() {
        return GdipUiHelpers.RenderToggleBitmap(this.tw, this.th, this._animProgress, this._renderState)
    }

    _redraw() {
        this._assignBitmap(this._renderBitmap())
    }

    Draw(on) {
        on := !!on
        if (this._on = on && Abs(this._animProgress - (on ? 1.0 : 0.0)) < 0.001) {
            return
        }
        this._on := on
        this._redraw()
    }

    OnClick(handler) {
        this.ctrl.OnEvent("Click", handler)
    }

    static _EnsureTimer() {
        if ToggleGdip._timerOn {
            return
        }
        ToggleGdip._timerOn := true
        SetTimer(ObjBindMethod(ToggleGdip, "_Tick"), 16)
    }

    static _Tick(*) {
        snapshot := UiHoverSnapshot()
        under := snapshot["hwnd"]
        lb := snapshot["leftButtonDown"]
        for toggle in ToggleGdip._all {
            toggle._pollState(under, lb)
        }
    }

    _pollState(under, lb) {
        if !IsObject(this.ctrl) {
            return
        }
        try hw := this.ctrl.Hwnd
        catch {
            return
        }
        if !hw {
            return
        }
        over := (under = hw)
        nextState := "normal"
        if over && lb {
            nextState := "pressed"
        } else if over {
            nextState := "hover"
        }

        target := this._on ? 1.0 : 0.0
        delta := target - this._animProgress
        if Abs(delta) > 0.001 {
            step := 0.22
            if Abs(delta) <= step {
                this._animProgress := target
            } else {
                this._animProgress += delta > 0 ? step : -step
            }
        }

        needsRedraw := false
        if (nextState != this._renderState) {
            this._renderState := nextState
            needsRedraw := true
        }
        if Abs(delta) > 0.001 {
            needsRedraw := true
        }
        if needsRedraw {
            this._redraw()
        }
    }
}
