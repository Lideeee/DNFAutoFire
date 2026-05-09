#Requires AutoHotkey v2.0

class FlatButtonGdip {
    static _all := []
    static _timerOn := false

    __New(gui, opts, text, handler, primary := false) {
        GdiPlusSession.EnsureStarted()
        this.gui := gui
        this.text := text
        this.handler := handler
        this.primary := primary
        this.enabled := true
        this._state := "normal"
        this._parseOpts(opts)
        this._assignBitmap(GdipUiHelpers.RenderButtonBitmap(this.w, this.h, this.text, this._state, this.primary))
        this.ctrl.OnEvent("Click", this._OnClick.Bind(this))
        FlatButtonGdip._all.Push(this)
        FlatButtonGdip._EnsureTimer()
    }

    _parseOpts(opts) {
        this.vName := ""
        if RegExMatch(opts, "v(\w+)", &m) {
            this.vName := m[1]
        }
        this.x := 0, this.y := 0, this.w := 80, this.h := 28
        if RegExMatch(opts, "x(\d+)", &mx) {
            this.x := Integer(mx[1])
        }
        if RegExMatch(opts, "y(\d+)", &my) {
            this.y := Integer(my[1])
        }
        if RegExMatch(opts, "w(\d+)", &mw) {
            this.w := Integer(mw[1])
        }
        if RegExMatch(opts, "h(\d+)", &mh) {
            this.h := Integer(mh[1])
        }
    }

    _assignBitmap(hbm) {
        optStr := "x" this.x " y" this.y " w" this.w " h" this.h " +0x120 0xE BackgroundTrans"
        if (this.vName != "") {
            optStr := "v" this.vName " " optStr
        }
        if this.HasOwnProp("ctrl") && IsObject(this.ctrl) {
            try this.ctrl.Value := hbm ? ("HBITMAP:*" hbm) : ""
        } else {
            this.ctrl := this.gui.Add("Picture", optStr, hbm ? ("HBITMAP:*" hbm) : "")
        }
        if hbm {
            try DllCall("gdi32\DeleteObject", "ptr", hbm)
        }
    }

    static _EnsureTimer() {
        if FlatButtonGdip._timerOn {
            return
        }
        FlatButtonGdip._timerOn := true
        ; SetTimer 需要 Func；直接传静态方法引用在部分环境下会报 Invalid callback function
        SetTimer(ObjBindMethod(FlatButtonGdip, "_Tick"), 80)
    }

    static _Tick(*) {
        for b in FlatButtonGdip._all {
            b._pollState()
        }
    }

    _pollState() {
        if !this.enabled {
            if (this._state != "disabled") {
                this._state := "disabled"
                this._redraw()
            }
            return
        }
        try hw := this.ctrl.Hwnd
        catch {
            return
        }
        if !hw {
            return
        }
        MouseGetPos(, , &under)
        over := (under = hw)
        lb := GetKeyState("LButton", "P")
        ns := "normal"
        if over && lb {
            ns := "pressed"
        } else if over {
            ns := "hover"
        } else {
            ns := "normal"
        }
        if (ns != this._state) {
            this._state := ns
            this._redraw()
        }
    }

    _redraw() {
        st := this.enabled ? this._state : "disabled"
        this._assignBitmap(GdipUiHelpers.RenderButtonBitmap(this.w, this.h, this.text, st, this.primary))
    }

    _OnClick(*) {
        if !this.enabled {
            return
        }
        if this.handler {
            this.handler()
        }
    }

    SetEnabled(on) {
        this.enabled := !!on
        this._state := this.enabled ? "normal" : "disabled"
        this._redraw()
    }
}
