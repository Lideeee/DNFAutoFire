#Requires AutoHotkey v2.0

class MainKeyLayoutData {
    static BaseX() => 16
    static TopRowY() => 30
    static MainRowY() => this.TopRowY() + this.Height() + this.Gap()
    static Unit() => 40
    static Gap() => 4
    static Height() => this.Unit() - 2

    static KeyWidth(units := 1) {
        return Round(units * this.Pitch() - this.Gap())
    }

    static Pitch() {
        return this.Unit() + this.Gap()
    }

    static RowY(index) {
        return this.MainRowY() + (index - 1) * (this.Height() + this.Gap())
    }

    static Rect(x, y, wUnits := 1, h := unset) {
        return "x" x " y" y " w" this.KeyWidth(wUnits) " h" (IsSet(h) ? h : this.Height())
    }

    static AddKey(rows, name, x, y, wUnits := 1, label := unset, h := unset) {
        item := [name, IsSet(h) ? this.Rect(x, y, wUnits, h) : this.Rect(x, y, wUnits)]
        if IsSet(label) {
            item.Push(label)
        }
        rows.Push(item)
    }

    static AlphaBlockRight() {
        x := this.BaseX()
        x += this.KeyWidth(1.75) + this.Gap() ; Caps
        x += 9 * this.Pitch()                ; A..L
        x += 2 * this.Pitch()                ; ; '
        x += this.KeyWidth(2.25)             ; Enter
        return x
    }

    static MainBlockRight() {
        return this.AlphaBlockRight()
    }

    static NumpadX() {
        return this.MainBlockRight() + this.Gap()
    }

    static WinRect() {
        x := this.BaseX() + this.KeyWidth(1.25) + this.Gap()
        return "x" x " y" this.RowY(5) " w" this.KeyWidth(1.25) " h" this.Height()
    }

    static VersionWidth() {
        return this.KeyWidth(1) * 3 + this.Gap() * 2
    }

    static MainRow1BackspaceX() {
        return this.BaseX() + 13 * this.Pitch()
    }

    static MainRow1BackspaceRight() {
        return this.MainRow1BackspaceX() + this.KeyWidth(2)
    }

    static TopRowF12X() {
        return this.MainRow1BackspaceRight() - this.KeyWidth(1)
    }

    static TopRowFKeyX(index) {
        gaps := this.TopRowGroupGaps()
        x := this.TopRowEscX() + this.KeyWidth(1) + gaps[1]
        if (index <= 4) {
            return x + (index - 1) * this.Pitch()
        }
        x += 4 * this.KeyWidth(1) + 3 * this.Gap() + gaps[2]
        if (index <= 8) {
            return x + (index - 5) * this.Pitch()
        }
        x += 4 * this.KeyWidth(1) + 3 * this.Gap() + gaps[3]
        return x + (index - 9) * this.Pitch()
    }

    static TopRowEscX() {
        return this.BaseX()
    }

    static TopRowClearX() {
        return this.NumpadX() + this.Pitch() * 3
    }

    static TopRowGroupGaps() {
        total := this.TopRowF12X() + this.KeyWidth(1) - this.TopRowEscX()
        keyCount := 13 ; Esc + F1..F12
        normalGapCount := 9 ; 组内普通间隔
        remain := total - keyCount * this.KeyWidth(1) - normalGapCount * this.Gap()
        baseGap := Floor(remain / 3)
        extra := Mod(remain, 3)
        g1 := baseGap + (extra >= 1 ? 1 : 0)
        g2 := baseGap + (extra >= 2 ? 1 : 0)
        g3 := baseGap
        return [g1, g2, g3]
    }

    static TopRowVersionX() {
        return this.TopRowClearX() - this.VersionWidth() - this.Gap()
    }

    static TopRowVersionY() {
        return this.TopRowY()
    }

    static TopRowVersionHeight() {
        return this.Height()
    }

    static KeyboardLeft() {
        return this.BaseX()
    }

    static KeyboardTop() {
        return this.TopRowY()
    }

    static KeyboardRight() {
        return this.TopRowClearX() + this.KeyWidth(1)
    }

    static KeyboardBottom() {
        return this.RowY(5) + this.Height()
    }

    static KeyboardWidth() {
        return this.KeyboardRight() - this.KeyboardLeft()
    }

    static KeyboardHeight() {
        return this.KeyboardBottom() - this.KeyboardTop()
    }

    static GetRows() {
        rows := []
        topY := this.TopRowY()
        this.AddKey(rows, "Esc", this.TopRowEscX(), topY)
        this.AddKey(rows, "F1", this.TopRowFKeyX(1), topY)
        this.AddKey(rows, "F2", this.TopRowFKeyX(2), topY)
        this.AddKey(rows, "F3", this.TopRowFKeyX(3), topY)
        this.AddKey(rows, "F4", this.TopRowFKeyX(4), topY)
        this.AddKey(rows, "F5", this.TopRowFKeyX(5), topY)
        this.AddKey(rows, "F6", this.TopRowFKeyX(6), topY)
        this.AddKey(rows, "F7", this.TopRowFKeyX(7), topY)
        this.AddKey(rows, "F8", this.TopRowFKeyX(8), topY)
        this.AddKey(rows, "F9", this.TopRowFKeyX(9), topY)
        this.AddKey(rows, "F10", this.TopRowFKeyX(10), topY)
        this.AddKey(rows, "F11", this.TopRowFKeyX(11), topY)
        this.AddKey(rows, "F12", this.TopRowFKeyX(12), topY)

        y := this.RowY(1), x := this.BaseX()
        this.AddKey(rows, "Tilde", x, y, 1, "``")
        x += this.Pitch()
        for key in ["1","2","3","4","5","6","7","8","9","0"] {
            this.AddKey(rows, key, x, y)
            x += this.Pitch()
        }
        this.AddKey(rows, "Sub", x, y, 1, "-")
        x += this.Pitch()
        this.AddKey(rows, "Add", x, y, 1, "+")
        x += this.Pitch()
        this.AddKey(rows, "Backspace", x, y, 2, "Back")

        y := this.RowY(2), x := this.BaseX()
        this.AddKey(rows, "Tab", x, y, 1.5, "Tab")
        x += this.KeyWidth(1.5) + this.Gap()
        for key in ["Q","W","E","R","T","Y","U","I","O","P"] {
            this.AddKey(rows, key, x, y)
            x += this.Pitch()
        }
        this.AddKey(rows, "LeftBracket", x, y, 1, "[")
        x += this.Pitch()
        this.AddKey(rows, "RightBracket", x, y, 1, "]")
        x += this.Pitch()
        this.AddKey(rows, "Backslash", x, y, 1.5, Chr(92))

        y := this.RowY(3), x := this.BaseX()
        this.AddKey(rows, "Caps", x, y, 1.75, "Caps")
        x += this.KeyWidth(1.75) + this.Gap()
        for key in ["A","S","D","F","G","H","J","K","L"] {
            this.AddKey(rows, key, x, y)
            x += this.Pitch()
        }
        this.AddKey(rows, "Semicolon", x, y, 1, ";")
        x += this.Pitch()
        this.AddKey(rows, "QuotationMark", x, y, 1, "'")
        x += this.Pitch()
        this.AddKey(rows, "Enter", x, y, 2.25, "Enter")

        numX := this.NumpadX()
        upX := numX - this.Gap() - this.KeyWidth(1)
        y := this.RowY(4), x := this.BaseX()
        this.AddKey(rows, "LShift", x, y, 2.25, "Shift")
        x += this.KeyWidth(2.25) + this.Gap()
        for key in ["Z","X","C","V","B","N","M","Comma","Period","Slash"] {
            if (key = "Comma") {
                this.AddKey(rows, key, x, y, 1, ",")
            } else if (key = "Period") {
                this.AddKey(rows, key, x, y, 1, ".")
            } else if (key = "Slash") {
                this.AddKey(rows, key, x, y, 1, "/")
            } else {
                this.AddKey(rows, key, x, y)
            }
            x += this.Pitch()
        }
        rShiftWidthPx := upX - this.Gap() - x
        rShiftUnits := (rShiftWidthPx + this.Gap()) / this.Pitch()
        this.AddKey(rows, "RShift", x, y, rShiftUnits, "Shift")
        this.AddKey(rows, "Up", upX, y, 1, "↑")

        y := this.RowY(5)
        rightX := numX
        downX := upX
        leftX := downX - this.Pitch()
        rCtrlX := leftX - this.Pitch()
        rAltX := rCtrlX - this.Pitch()
        spaceX := this.BaseX() + this.KeyWidth(1.25) + this.Gap() + this.KeyWidth(1.25) + this.Gap() + this.KeyWidth(1.25) + this.Gap()
        spaceWidthPx := rAltX - this.Gap() - spaceX
        spaceUnits := (spaceWidthPx + this.Gap()) / this.Pitch()
        this.AddKey(rows, "LCtrl", this.BaseX(), y, 1.25, "Ctrl")
        this.AddKey(rows, "LAlt", this.BaseX() + this.KeyWidth(1.25) + this.Gap() + this.KeyWidth(1.25) + this.Gap(), y, 1.25, "Alt")
        this.AddKey(rows, "Space", spaceX, y, spaceUnits)
        this.AddKey(rows, "RAlt", rAltX, y, 1, "Alt")
        this.AddKey(rows, "RCtrl", rCtrlX, y, 1, "Ctrl")
        this.AddKey(rows, "Left", leftX, y, 1, "←")
        this.AddKey(rows, "Down", downX, y, 1, "↓")
        this.AddKey(rows, "Right", rightX, y, 1, "→")

        y1 := this.RowY(1), y2 := this.RowY(2), y3 := this.RowY(3), y4 := this.RowY(4), y5 := this.RowY(5)
        this.AddKey(rows, "NumLk", numX, y1, 1, "Num")
        this.AddKey(rows, "NumSlash", numX + this.Pitch(), y1, 1, "/")
        this.AddKey(rows, "NumStar", numX + this.Pitch() * 2, y1, 1, "*")
        this.AddKey(rows, "NumSub", numX + this.Pitch() * 3, y1, 1, "-")
        this.AddKey(rows, "Num7", numX, y2, 1, "7")
        this.AddKey(rows, "Num8", numX + this.Pitch(), y2, 1, "8")
        this.AddKey(rows, "Num9", numX + this.Pitch() * 2, y2, 1, "9")
        this.AddKey(rows, "NumAdd", numX + this.Pitch() * 3, y2, 1, "+", this.Height() * 2 + this.Gap())
        this.AddKey(rows, "Num4", numX, y3, 1, "4")
        this.AddKey(rows, "Num5", numX + this.Pitch(), y3, 1, "5")
        this.AddKey(rows, "Num6", numX + this.Pitch() * 2, y3, 1, "6")
        this.AddKey(rows, "Num1", numX, y4, 1, "1")
        this.AddKey(rows, "Num2", numX + this.Pitch(), y4, 1, "2")
        this.AddKey(rows, "Num3", numX + this.Pitch() * 2, y4, 1, "3")
        this.AddKey(rows, "NumEnter", numX + this.Pitch() * 3, y4, 1, "Enter", this.Height() * 2 + this.Gap())
        this.AddKey(rows, "Num0", numX + this.Pitch(), y5, 1, "0")
        this.AddKey(rows, "NumPeriod", numX + this.Pitch() * 2, y5, 1, ".")
        return rows
    }
}
