#Requires AutoHotkey v2.0

class MainKeyCap {
    static _all := []
    static _timerOn := false
    ctrl := 0
    labelCtrl := 0
    auxLabelCtrl := 0

    __New(gui, name, pos, label, locked := false, onClick := "") {
        GdiPlusSession.EnsureStarted()
        this.gui := gui
        this.name := name
        this.label := label
        this.displayLabel := this._displayLabel(label)
        this.locked := !!locked
        this.onClick := onClick
        this.visualState := this.locked ? "locked" : "off"
        this.overrideHint := false
        this.intervalBarHint := false
        this.renderState := "normal"
        this._parseRect(pos)
        this._createCtrl()
        MainRegisterKeyCap(this)
        MainKeyCap._all.Push(this)
        MainKeyCap._EnsureTimer()
    }

    _parseRect(pos) {
        this.x := 0, this.y := 0, this.w := 40, this.h := 32
        if RegExMatch(pos, "x(\d+)", &mx) {
            this.x := Integer(mx[1])
        }
        if RegExMatch(pos, "y(\d+)", &my) {
            this.y := Integer(my[1])
        }
        if RegExMatch(pos, "w(\d+)", &mw) {
            this.w := Integer(mw[1])
        }
        if RegExMatch(pos, "h(\d+)", &mh) {
            this.h := Integer(mh[1])
        }
    }

    _createCtrl() {
        bmp := this._renderBitmap()
        try {
            this.ctrl := this.gui.Add("Picture", "v" this.name " x" this.x " y" this.y " w" this.w " h" this.h " +0x120 0xE BackgroundTrans", bmp ? ("HBITMAP:*" bmp) : "")
            if bmp {
                DllCall("gdi32\DeleteObject", "ptr", bmp)
            }
        }
        this._createLabelCtrl()
        this._bindClickEvent(this.ctrl)
    }

    _createLabelCtrl() {
        if (this.displayLabel = "") {
            return
        }
        color := this._labelColor()
        fontSize := UiMainKeyLabelFontSize(this.name)
        this.gui.SetFont(fontSize " c" color " norm", this._labelFontFace())
        this.labelCtrl := this.gui.Add("Text", this._labelOpts(), this.displayLabel)
        this._bindClickEvent(this.labelCtrl)
        this._createAuxLabelCtrl()
    }

    _bindClickEvent(ctrl) {
        if !IsObject(ctrl) || this.locked || this.onClick = "" {
            return
        }
        ctrl.OnEvent("Click", ObjBindMethod(this, "_handleClick"))
    }

    _handleClick(*) {
        if !IsObject(this.ctrl) || this.onClick = "" {
            return
        }
        this.onClick.Call(this.ctrl)
    }

    _renderBitmap() {
        return GdipUiHelpers.RenderKeycapBitmap(this.w, this.h, this.displayLabel, this.visualState, this.renderState, this._fontPx(), false, this.name, this.overrideHint || this.intervalBarHint)
    }

    _fontPx() {
        size := UiMainKeyLabelFontSize(this.name)
        if SubStr(size, 1, 1) = "s" {
            return Integer(SubStr(size, 2))
        }
        return 12
    }

    _redraw() {
        if !IsObject(this.ctrl) {
            return
        }
        bmp := this._renderBitmap()
        try this.ctrl.Value := bmp ? ("HBITMAP:*" bmp) : ""
        if bmp {
            DllCall("gdi32\DeleteObject", "ptr", bmp)
        }
        if IsObject(this.labelCtrl) {
            fontSize := UiMainKeyLabelFontSize(this.name)
            this.labelCtrl.SetFont(fontSize " c" this._labelColor() " norm", this._labelFontFace())
        }
        if IsObject(this.auxLabelCtrl) {
            this.auxLabelCtrl.SetFont("s10 c" this._labelColor() " norm", "Segoe Fluent Icons")
        }
    }

    _displayLabel(label) {
        switch this.name {
            case "Enter", "NumEnter":
                return Chr(0xE751)
            case "LShift", "RShift":
                return "Shift"
            case "Up", "Down", "Left", "Right", "Win":
                return ""
            default:
                return label
        }
    }

    _labelOpts() {
        if (this.name = "LShift" || this.name = "RShift") {
            return "x" (this.x + 24) " y" (this.y + 6) " w" (this.w - 28) " h" (this.h - 8) " +0x200 BackgroundTrans E0x20"
        }
        if (this.name = "Space") {
            return "x" this.x " y" this.y " w" this.w " h" this.h " +0x200 +Center BackgroundTrans E0x20"
        }
        if this._usesFluentIcon() {
            return "x" this.x " y" this.y " w" this.w " h" this.h " +0x200 +Center BackgroundTrans E0x20"
        }
        return "x" (this.x + 8) " y" (this.y + 6) " w" (this.w - 10) " h" (this.h - 8) " +0x200 BackgroundTrans E0x20"
    }

    _createAuxLabelCtrl() {
        if (this.name != "LShift" && this.name != "RShift") {
            return
        }
        color := this._labelColor()
        this.gui.SetFont("s10 c" color " norm", "Segoe Fluent Icons")
        this.auxLabelCtrl := this.gui.Add("Text", "x" (this.x + 6) " y" (this.y + 6) " w18 h" (this.h - 8) " +0x200 +Center BackgroundTrans E0x20", Chr(0xE752))
        this._bindClickEvent(this.auxLabelCtrl)
    }

    _labelFontFace() {
        global UiTheme
        return this._usesFluentIcon() ? "Segoe Fluent Icons" : UiTheme["KeyFace"]
    }

    _usesFluentIcon() {
        switch this.name {
            case "Enter", "NumEnter":
                return true
            default:
                return false
        }
    }

    _labelColor() {
        global UiTheme
        switch this.visualState {
            case "on":
                return UiTheme["KeyOn"]
            case "override":
                return UiTheme["KeyOv"]
            case "locked":
                return UiTheme["KeyCapLockedText"]
            default:
                return UiTheme["KeyOff"]
        }
    }

    SetVisualState(visualState, overrideHint := false) {
        if (visualState = "") {
            visualState := this.locked ? "locked" : "off"
        }
        if (this.visualState = visualState && this.overrideHint = !!overrideHint) {
            return
        }
        this.visualState := visualState
        this.overrideHint := !!overrideHint
        this._redraw()
    }

    SetIntervalBarHint(show) {
        show := !!show
        if (this.intervalBarHint = show) {
            return
        }
        this.intervalBarHint := show
        this._redraw()
    }

    static _EnsureTimer() {
        if MainKeyCap._timerOn {
            return
        }
        MainKeyCap._timerOn := true
        SetTimer(ObjBindMethod(MainKeyCap, "_Tick"), 80)
    }

    static _Tick(*) {
        snapshot := UiHoverSnapshot()
        under := snapshot["hwnd"]
        lb := snapshot["leftButtonDown"]
        for keyCap in MainKeyCap._all {
            keyCap._pollState(under, lb)
        }
    }

    _pollState(under, lb) {
        if (this.locked) {
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
        if IsObject(this.labelCtrl) {
            try {
                if (under = this.labelCtrl.Hwnd) {
                    over := true
                }
            } catch {
            }
        }
        if IsObject(this.auxLabelCtrl) {
            try {
                if (under = this.auxLabelCtrl.Hwnd) {
                    over := true
                }
            } catch {
            }
        }
        nextState := "normal"
        if over && lb {
            nextState := "pressed"
        } else if over {
            nextState := "hover"
        }
        if (nextState = this.renderState) {
            return
        }
        this.renderState := nextState
        this._redraw()
    }
}

MainCreateKeyCap(gui, name, pos, label, locked := false, onClick := "") {
    return MainKeyCap(gui, name, pos, label, locked, onClick)
}

MainRegisterKeyCap(keyCap) {
    global gMainKeyCaps, gMainCtrls
    gMainKeyCaps[keyCap.name] := keyCap
    if IsObject(keyCap.ctrl) && keyCap.ctrl.Name != "" {
        gMainCtrls[keyCap.ctrl.Name] := keyCap.ctrl
    }
}

MainGetKeyCap(name) {
    global gMainKeyCaps
    return gMainKeyCaps.Has(name) ? gMainKeyCaps[name] : ""
}
