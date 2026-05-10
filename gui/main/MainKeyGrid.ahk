#Requires AutoHotkey v2.0

class MainKeyGrid {
    static NormalizeKeyName(name) {
        if (name = "") {
            return ""
        }
        return RegExReplace(name, "_Hit$")
    }

    static IsGrayOnlyKey(name) {
        name := this.NormalizeKeyName(name)
        static gray := Map(
            "Esc", true
        )
        return gray.Has(name)
    }

    static IsInteractiveKeyName(name) {
        name := this.NormalizeKeyName(name)
        if (name = "" || this.IsGrayOnlyKey(name)) {
            return false
        }
        return IsValueInArray(name, GetAllKeys())
    }

    static SetKeyState(keyName, isEnabled, overrideMap := 0) {
        keyCap := MainGetKeyCap(keyName)
        if !IsObject(keyCap) {
            return
        }
        if this.IsGrayOnlyKey(keyName) {
            keyCap.SetVisualState("locked", false)
            return
        }
        hasOverride := false
        if IsObject(overrideMap) {
            hasOverride := overrideMap.Has(keyName)
        } else {
            currentOverrides := LoadPresetKeyIntervalOverrides(GetNowSelectPreset())
            hasOverride := currentOverrides.Has(keyName)
        }
        if !isEnabled {
            visualState := "off"
        } else {
            visualState := "on"
        }
        keyCap.SetVisualState(visualState, hasOverride)
    }

    static RefreshAllKeyAppearances() {
        presetName := GetNowSelectPreset()
        if (presetName = "") {
            return
        }
        overrideMap := LoadPresetKeyIntervalOverrides(presetName)
        allKeys := GetAllKeys()
        try keyCount := allKeys.Length
        catch {
            keyCount := 0
        }
        loop keyCount {
            if !allKeys.Has(A_Index) {
                continue
            }
            keyName := allKeys[A_Index]
            if this.IsGrayOnlyKey(keyName) {
                continue
            }
            this.SetKeyState(keyName, AutoFireController.IsKeyAutoFire(keyName), overrideMap)
        }
    }

    static OnKeyClick(ctrl, *) {
        keyName := this.NormalizeKeyName(ctrl.Name)
        AutoFireController.ChangeKeyAutoFireState(keyName)
        MainSaveCurrentPreset()
    }
}

class MainKeyCap {
    static _all := []
    static _timerOn := false

    __New(gui, name, pos, label, locked := false) {
        GdiPlusSession.EnsureStarted()
        this.gui := gui
        this.name := name
        this.label := label
        this.displayLabel := this._displayLabel(label)
        this.locked := !!locked
        this.visualState := this.locked ? "locked" : "off"
        this.overrideHint := false
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
        if !this.locked {
            GuiTheme_RegisterHandCursor(this.ctrl)
            this.ctrl.OnEvent("Click", MainKeyClick)
        }
    }

    _createLabelCtrl() {
        if (this.displayLabel = "") {
            return
        }
        color := this._labelColor()
        fontSize := GuiTheme_MainKeyLabelFontSize(this.name)
        this.gui.SetFont(fontSize " c" color " norm", this._labelFontFace())
        this.labelCtrl := this.gui.Add("Text", this._labelOpts(), this.displayLabel)
        if !this.locked {
            this.labelCtrl.OnEvent("Click", MainKeyClick)
            GuiTheme_RegisterHandCursor(this.labelCtrl)
        }
        this._createAuxLabelCtrl()
    }

    _renderBitmap() {
        return GdipUiHelpers.RenderKeycapBitmap(this.w, this.h, this.displayLabel, this.visualState, this.renderState, this._fontPx(), false, this.name, this.overrideHint)
    }

    _fontPx() {
        size := GuiTheme_MainKeyLabelFontSize(this.name)
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
            fontSize := GuiTheme_MainKeyLabelFontSize(this.name)
            this.labelCtrl.SetFont(fontSize " c" this._labelColor() " norm", this._labelFontFace())
        }
        if IsObject(this.auxLabelCtrl) {
            this.auxLabelCtrl.SetFont("s10 c" this._labelColor() " norm", "Segoe Fluent Icons")
        }
    }

    _displayLabel(label) {
        switch this.name {
            case "Enter":
                return Chr(0xE751) ; ReturnKey
            case "NumEnter":
                return Chr(0xE751) ; ReturnKey
            case "LShift", "RShift":
                return "Shift"
            case "Up", "Down", "Left", "Right":
                return ""
            case "Win":
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
        if !this.locked {
            this.auxLabelCtrl.OnEvent("Click", MainKeyClick)
            GuiTheme_RegisterHandCursor(this.auxLabelCtrl)
        }
    }

    _labelFontFace() {
        return this._usesFluentIcon() ? "Segoe Fluent Icons" : UiTheme.KeyFace
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
        switch this.visualState {
            case "on":
                return UiTheme.KeyOn
            case "override":
                return UiTheme.KeyOv
            case "locked":
                return UiTheme.KeyCapLockedText
            default:
                return UiTheme.KeyOff
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

    static _EnsureTimer() {
        if MainKeyCap._timerOn {
            return
        }
        MainKeyCap._timerOn := true
        SetTimer(ObjBindMethod(MainKeyCap, "_Tick"), 80)
    }

    static _Tick(*) {
        for keyCap in MainKeyCap._all {
            keyCap._pollState()
        }
    }

    _pollState() {
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
        MouseGetPos(, , &under)
        over := (under = hw)
        lb := GetKeyState("LButton", "P")
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

MainKeyUiGrayOnly(name) => MainKeyGrid.IsGrayOnlyKey(name)
MainIsInteractiveKeyName(name) => MainKeyGrid.IsInteractiveKeyName(name)
MainNormalizeKeyName(name) => MainKeyGrid.NormalizeKeyName(name)
MainSetKeyState(keyName, isEnabled, overrideMap := 0) => MainKeyGrid.SetKeyState(keyName, isEnabled, overrideMap)
MainRefreshAllKeyAppearances() => MainKeyGrid.RefreshAllKeyAppearances()
MainKeyClick(ctrl, *) => MainKeyGrid.OnKeyClick(ctrl)
MainCreateKeyCap(gui, name, pos, label, locked := false) => MainKeyCap(gui, name, pos, label, locked)
MainRegisterKeyCap(keyCap) {
    global gMainKeyCaps
    gMainKeyCaps[keyCap.name] := keyCap
}
MainGetKeyCap(name) {
    global gMainKeyCaps
    return gMainKeyCaps.Has(name) ? gMainKeyCaps[name] : ""
}
