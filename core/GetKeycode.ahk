#Requires AutoHotkey v2.0

; 主连发与扩展模块共用的按键规范转换工具。
class GetKeycode {
    static __aliases := Map()
    static __aliasesBuilt := false

    static IsMainKey(name) {
        s := Trim(name "")
        if (s = "") {
            return false
        }
        for k in GetAllKeys() {
            if (k = s) {
                return true
            }
        }
        return false
    }

    static _BuildAliases() {
        if this.__aliasesBuilt {
            return
        }
        m := this.__aliases
        for k in GetAllKeys() {
            m[StrLower(k)] := k
        }
        ex := Map(
            "escape", "Esc",
            "esc", "Esc",
            "return", "Enter",
            "enter", "Enter",
            "numpad0", "Num0",
            "numpad1", "Num1",
            "numpad2", "Num2",
            "numpad3", "Num3",
            "numpad4", "Num4",
            "numpad5", "Num5",
            "numpad6", "Num6",
            "numpad7", "Num7",
            "numpad8", "Num8",
            "numpad9", "Num9",
            "numpaddot", "NumPeriod",
            "numpaddec", "NumPeriod",
            "numpadenter", "NumEnter",
            "numpadadd", "NumAdd",
            "numpadsub", "NumSub",
            "numpadmult", "NumStar",
            "numpaddiv", "NumSlash",
            "numlock", "NumLk",
            "subtract", "Sub",
            "minus", "Sub",
            "equal", "Add",
            "equals", "Add",
            "plus", "NumAdd",
            "grave", "Tilde",
            "backquote", "Tilde",
            "lbracket", "LeftBracket",
            "rbracket", "RightBracket",
            "backslash", "Backslash",
            "semicolon", "Semicolon",
            "apostrophe", "QuotationMark",
            "comma", "Comma",
            "period", "Period",
            "slash", "Slash",
            "capslock", "Caps",
            "lcontrol", "LCtrl",
            "rcontrol", "RCtrl",
            "lctrl", "LCtrl",
            "rctrl", "RCtrl",
            "lshift", "LShift",
            "rshift", "RShift",
            "lalt", "LAlt",
            "ralt", "RAlt",
            "lmenu", "LAlt",
            "rmenu", "RAlt",
            "bspace", "Backspace",
            "bs", "Backspace"
        )
        for lk, canon in ex {
            m[lk] := canon
        }
        m["["] := "LeftBracket"
        m["]"] := "RightBracket"
        m[Chr(92)] := "Backslash"
        m[";"] := "Semicolon"
        m["'"] := "QuotationMark"
        m[","] := "Comma"
        m["."] := "Period"
        m["/"] := "Slash"
        m["-"] := "Sub"
        m["="] := "Add"
        m["``"] := "Tilde"
        this.__aliasesBuilt := true
    }

    static CanonMainKey(raw) {
        s := Trim(raw "")
        if (s = "") {
            return ""
        }
        if this.IsMainKey(s) {
            return s
        }
        this._BuildAliases()
        sl := StrLower(s)
        if this.__aliases.Has(sl) {
            return this.__aliases[sl]
        }
        if (StrLen(s) = 1) {
            u := StrUpper(s)
            if this.IsMainKey(u) {
                return u
            }
        }
        return ""
    }

    static RequireMainKey(raw) {
        return this.CanonMainKey(raw)
    }

    static AfterCaptureEdit(edit, raw := "", *) {
        ; BoundFunc from GetKeycode.AfterCaptureEdit.Bind(editCtrl) may bind the
        ; first visible parameter directly, so do not rely on `this` here.
        c := GetKeycode.CanonMainKey(raw)
        if (c = "") {
            MsgBox(GuiText.InvalidMainKey(),, "Icon!")
            edit.Text := ""
            return
        }
        edit.Text := c
    }

    static _AhkKey(mainKey) {
        switch mainKey {
            Case "Sub":
                return "-"
            Case "Add":
                return "="
            Case "Tilde":
                return "``"
            Case "LeftBracket":
                return "["
            Case "RightBracket":
                return "]"
            Case "Backslash":
                return "\"
            Case "Semicolon":
                return ";"
            Case "Caps":
                return "CapsLock"
            Case "QuotationMark":
                return "'"
            Case "Comma":
                return ","
            Case "Period":
                return "."
            Case "Slash":
                return "/"
            Case "Num1":
                return "Numpad1"
            Case "Num2":
                return "Numpad2"
            Case "Num3":
                return "Numpad3"
            Case "Num4":
                return "Numpad4"
            Case "Num5":
                return "Numpad5"
            Case "Num6":
                return "Numpad6"
            Case "Num7":
                return "Numpad7"
            Case "Num8":
                return "Numpad8"
            Case "Num9":
                return "Numpad9"
            Case "Num0":
                return "Numpad0"
            Case "NumPeriod":
                return "NumpadDot"
            Case "NumLk":
                return "NumLock"
            Case "NumEnter":
                return "NumpadEnter"
            Case "NumAdd":
                return "NumpadAdd"
            Case "NumSub":
                return "NumpadSub"
            Case "NumStar":
                return "NumpadMult"
            Case "NumSlash":
                return "NumpadDiv"
            Default:
                return mainKey
        }
    }

    static _ScTokenFromAhk(ahkKey) {
        sc := GetKeySC(ahkKey)
        return Format("sc{:02X}", sc)
    }

    ; 转成 SendIP / SendEvent 使用的 vkFFscXX 令牌。
    static ToSendToken(mainKey) {
        if !this.IsMainKey(mainKey) {
            return ""
        }
        ahk := this._AhkKey(mainKey)
        sc := GetKeySC(ahk)
        return Format("vkFFsc{:02X}", sc)
    }

    ; 转成 KeyRouter / Hotkey 使用的稳定 id。
    static ToRouterId(mainKey) {
        if !this.IsMainKey(mainKey) {
            return ""
        }
        ahk := this._AhkKey(mainKey)
        try {
            sc := GetKeySC(ahk)
            if (sc != "") {
                return this._ScTokenFromAhk(ahk)
            }
        } catch {
        }
        return ahk
    }

    ; 转成 GetKeyState(..., "P") 使用的名称。
    static ToProbeKey(mainKey) {
        if !this.IsMainKey(mainKey) {
            return ""
        }
        ahk := this._AhkKey(mainKey)
        switch ahk {
            case "LAlt", "RAlt", "LCtrl", "RCtrl", "LShift", "RShift", "Tab":
                return ahk
        }
        newKey := this._ScTokenFromAhk(ahk)
        if (InStr(ahk, "Num")) {
            newKey := ahk
        }
        return newKey
    }
}
