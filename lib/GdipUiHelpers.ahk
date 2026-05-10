#Requires AutoHotkey v2.0

class GdipUiHelpers {
    static PixelFormat32bppARGB := 0x26200A

    static HexRgbToARGB(hex6, alpha := 0xFF) {
        s := StrReplace(hex6, "#", "")
        if (StrLen(s) != 6) {
            return 0xFF000000
        }
        r := Integer("0x" SubStr(s, 1, 2))
        g := Integer("0x" SubStr(s, 3, 2))
        b := Integer("0x" SubStr(s, 5, 2))
        return (alpha << 24) | (r << 16) | (g << 8) | b
    }

    static AddPathRoundedRect(path, x, y, w, h, r) {
        r := Min(r, w / 2, h / 2)
        if (r < 0.5) {
            DllCall("gdiplus\GdipAddPathRectangle", "ptr", path, "float", x, "float", y, "float", w, "float", h)
            return
        }
        DllCall("gdiplus\GdipStartPathFigure", "ptr", path)
        DllCall("gdiplus\GdipAddPathArc", "ptr", path, "float", x, "float", y, "float", 2 * r, "float", 2 * r, "float", 180, "float", 90)
        DllCall("gdiplus\GdipAddPathArc", "ptr", path, "float", x + w - 2 * r, "float", y, "float", 2 * r, "float", 2 * r, "float", 270, "float", 90)
        DllCall("gdiplus\GdipAddPathArc", "ptr", path, "float", x + w - 2 * r, "float", y + h - 2 * r, "float", 2 * r, "float", 2 * r, "float", 0, "float", 90)
        DllCall("gdiplus\GdipAddPathArc", "ptr", path, "float", x, "float", y + h - 2 * r, "float", 2 * r, "float", 2 * r, "float", 90, "float", 90)
        DllCall("gdiplus\GdipClosePathFigure", "ptr", path)
    }

    static FillRoundRect(gr, argb, x, y, w, h, r) {
        pPath := 0
        if DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &pPath := 0) != 0 || !pPath {
            return
        }
        try {
            this.AddPathRoundedRect(pPath, x, y, w, h, r)
            pBrush := 0
            if DllCall("gdiplus\GdipCreateSolidFill", "uint", argb, "ptr*", &pBrush := 0) != 0 || !pBrush {
                return
            }
            try {
                DllCall("gdiplus\GdipFillPath", "ptr", gr, "ptr", pBrush, "ptr", pPath)
            } finally {
                DllCall("gdiplus\GdipDeleteBrush", "ptr", pBrush)
            }
        } finally {
            DllCall("gdiplus\GdipDeletePath", "ptr", pPath)
        }
    }

    static StrokeRoundRect(gr, argb, x, y, w, h, r, penW := 1.0) {
        pPath := 0
        if DllCall("gdiplus\GdipCreatePath", "int", 0, "ptr*", &pPath := 0) != 0 || !pPath {
            return
        }
        try {
            this.AddPathRoundedRect(pPath, x, y, w, h, r)
            pPen := 0
            if DllCall("gdiplus\GdipCreatePen1", "uint", argb, "float", penW, "int", 2, "ptr*", &pPen := 0) != 0 || !pPen {
                return
            }
            try {
                DllCall("gdiplus\GdipDrawPath", "ptr", gr, "ptr", pPen, "ptr", pPath)
            } finally {
                DllCall("gdiplus\GdipDeletePen", "ptr", pPen)
            }
        } finally {
            DllCall("gdiplus\GdipDeletePath", "ptr", pPath)
        }
    }

    static DrawStringCentered(gr, text, face, sizePx, argb, x, y, w, h, fontStyle := 0) {
        if (text = "") {
            return
        }
        try DllCall("gdiplus\GdipSetTextRenderingHint", "ptr", gr, "int", 3) ; AntiAlias
        try DllCall("gdiplus\GdipSetPixelOffsetMode", "ptr", gr, "int", 0) ; Default
        ff := 0
        st := DllCall("gdiplus\GdipCreateFontFamilyFromName", "wstr", face, "ptr", 0, "ptr*", &ff := 0)
        if (st != 0 || !ff) {
            return
        }
        try {
            pFont := 0
            if DllCall("gdiplus\GdipCreateFont", "ptr", ff, "float", sizePx, "int", fontStyle, "int", 0, "ptr*", &pFont := 0) != 0 || !pFont {
                return
            }
            try {
                pBrush := 0
                if DllCall("gdiplus\GdipCreateSolidFill", "uint", argb, "ptr*", &pBrush := 0) != 0 || !pBrush {
                    return
                }
                try {
                    pFmt := 0
                    if DllCall("gdiplus\GdipStringFormatGetGenericDefault", "ptr*", &pFmt := 0) != 0 || !pFmt {
                        return
                    }
                    try {
                        DllCall("gdiplus\GdipSetStringFormatAlign", "ptr", pFmt, "int", 1) ; Center
                        DllCall("gdiplus\GdipSetStringFormatLineAlign", "ptr", pFmt, "int", 1) ; Center
                        rf := Buffer(16, 0)
                        NumPut("float", x, rf, 0)
                        NumPut("float", y, rf, 4)
                        NumPut("float", w, rf, 8)
                        NumPut("float", h, rf, 12)
                        DllCall("gdiplus\GdipDrawString", "ptr", gr, "wstr", text, "int", -1, "ptr", pFont, "ptr", rf.Ptr, "ptr", pFmt, "ptr", pBrush)
                    } finally {
                        DllCall("gdiplus\GdipDeleteStringFormat", "ptr", pFmt)
                    }
                } finally {
                    DllCall("gdiplus\GdipDeleteBrush", "ptr", pBrush)
                }
            } finally {
                DllCall("gdiplus\GdipDeleteFont", "ptr", pFont)
            }
        } finally {
            DllCall("gdiplus\GdipDeleteFontFamily", "ptr", ff)
        }
    }

    static BitmapToHBITMAP(pBitmap) {
        hbm := 0
        if DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", pBitmap, "ptr*", &hbm := 0, "uint", 0) != 0 || !hbm {
            return 0
        }
        return hbm
    }

    static RenderButtonBitmap(w, h, text, state, primary) {
        GdiPlusSession.EnsureStarted()
        pBitmap := 0
        stride := ((w * 4 + 3) // 4) * 4
        if DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", w, "int", h, "int", stride, "int", this.PixelFormat32bppARGB, "ptr", 0, "ptr*", &pBitmap := 0) != 0 || !pBitmap {
            return 0
        }
        try {
            gr := 0
            if DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", pBitmap, "ptr*", &gr := 0) != 0 || !gr {
                return 0
            }
            try {
                DllCall("gdiplus\GdipSetSmoothingMode", "ptr", gr, "int", 4)
                DllCall("gdiplus\GdipGraphicsClear", "ptr", gr, "uint", 0)
                pad := 1.0
                rr := Min(UiTheme.RadiusMd, w / 2 - 1, h / 2 - 1)
                if primary {
                    bg := this.HexRgbToARGB(UiTheme.BtnPrimaryBg)
                    fg := this.HexRgbToARGB(UiTheme.BtnPrimaryText)
                } else {
                    bg := this.HexRgbToARGB(UiTheme.KeyCellBg)
                    fg := this.HexRgbToARGB(UiTheme.BtnText)
                }
                if (state = "disabled") {
                    bg := (bg & 0xFFFFFF) | 0x99000000
                    fg := (fg & 0xFFFFFF) | 0x99000000
                } else if (state = "hover") {
                    bg := this._DarkenArgb(bg, 0.94)
                } else if (state = "pressed") {
                    bg := this._DarkenArgb(bg, 0.86)
                }
                this.FillRoundRect(gr, bg, pad, pad, w - 2 * pad, h - 2 * pad, rr)
                this.StrokeRoundRect(gr, 0x33000000, pad, pad, w - 2 * pad, h - 2 * pad, rr, 1)
            } finally {
                DllCall("gdiplus\GdipDeleteGraphics", "ptr", gr)
            }
            return this.BitmapToHBITMAP(pBitmap)
        } finally {
            DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
        }
    }

    static FillPolygon(gr, argb, points) {
        if !IsObject(points) || points.Length < 3 {
            return
        }
        pBrush := 0
        if DllCall("gdiplus\GdipCreateSolidFill", "uint", argb, "ptr*", &pBrush := 0) != 0 || !pBrush {
            return
        }
        try {
            buf := Buffer(points.Length * 8, 0)
            offset := 0
            for pt in points {
                NumPut("float", pt[1], buf, offset)
                NumPut("float", pt[2], buf, offset + 4)
                offset += 8
            }
            DllCall("gdiplus\GdipFillPolygon", "ptr", gr, "ptr", pBrush, "ptr", buf.Ptr, "int", points.Length, "int", 0)
        } finally {
            DllCall("gdiplus\GdipDeleteBrush", "ptr", pBrush)
        }
    }

    static RenderKeycapBitmap(w, h, text, visualState, renderState, textSizePx, bold := false, keyName := "", showHint := false) {
        GdiPlusSession.EnsureStarted()
        pBitmap := 0
        stride := ((w * 4 + 3) // 4) * 4
        if DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", w, "int", h, "int", stride, "int", this.PixelFormat32bppARGB, "ptr", 0, "ptr*", &pBitmap := 0) != 0 || !pBitmap {
            return 0
        }
        try {
            gr := 0
            if DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", pBitmap, "ptr*", &gr := 0) != 0 || !gr {
                return 0
            }
            try {
                DllCall("gdiplus\GdipSetSmoothingMode", "ptr", gr, "int", 4)
                DllCall("gdiplus\GdipGraphicsClear", "ptr", gr, "uint", 0)
                this._PaintKeycap(gr, w, h, visualState, renderState, keyName, showHint)
            } finally {
                DllCall("gdiplus\GdipDeleteGraphics", "ptr", gr)
            }
            return this.BitmapToHBITMAP(pBitmap)
        } finally {
            DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
        }
    }

    static _PaintKeycap(gr, w, h, visualState, renderState, keyName := "", showHint := false) {
        pad := 1.0
        rr := 0
        palette := this._KeycapPalette(visualState)
        bg := this.HexRgbToARGB(palette.bg)
        border := this.HexRgbToARGB(palette.border)
        hint := this.HexRgbToARGB(palette.hint)
        if (renderState = "hover") {
            bg := this._LightenArgb(bg, 0.02)
            border := this._DarkenArgb(border, 0.98)
        } else if (renderState = "pressed") {
            bg := this._DarkenArgb(bg, 0.98)
            border := this._DarkenArgb(border, 0.9)
        }
        this.FillRoundRect(gr, bg, pad, pad, w - 2 * pad, h - 2 * pad, rr)
        this.StrokeRoundRect(gr, border, pad, pad, w - 2 * pad, h - 2 * pad, rr, 1)
        this._DrawKeycapHint(gr, showHint, hint, w, h, pad)
        if (keyName = "Win") {
            this._DrawWindowsGlyph(gr, palette.text, w, h)
        } else if (keyName = "Up" || keyName = "Down" || keyName = "Left" || keyName = "Right") {
            this._DrawArrowGlyph(gr, palette.text, w, h, keyName)
        }
    }

    static _DrawKeycapHint(gr, showHint, hintArgb, w, h, pad) {
        if !showHint {
            return
        }
        lineW := 8
        lineH := 2
        inset := 4
        x := w - pad - inset - lineW
        y := pad + inset
        this.FillRoundRect(gr, hintArgb, x, y, lineW, lineH, 0)
    }

    static _DrawWindowsGlyph(gr, colorHex, w, h) {
        argb := this.HexRgbToARGB(colorHex)
        glyphW := 16
        glyphH := 16
        gap := 2
        paneW := Floor((glyphW - gap) / 2)
        paneH := Floor((glyphH - gap) / 2)
        startX := Floor((w - glyphW) / 2)
        startY := Floor((h - glyphH) / 2)
        this.FillRoundRect(gr, argb, startX, startY, paneW, paneH, 0)
        this.FillRoundRect(gr, argb, startX + paneW + gap, startY, paneW, paneH, 0)
        this.FillRoundRect(gr, argb, startX, startY + paneH + gap, paneW, paneH, 0)
        this.FillRoundRect(gr, argb, startX + paneW + gap, startY + paneH + gap, paneW, paneH, 0)
    }

    static _DrawArrowGlyph(gr, colorHex, w, h, direction) {
        argb := this.HexRgbToARGB(colorHex)
        cx := w / 2.0 - 4
        cy := h / 2.0 - 2
        head := 3
        shaftW := 1
        shaftLen := 9
        switch direction {
            case "Up":
                this.FillRoundRect(gr, argb, cx - shaftW / 2, cy - 1, shaftW, shaftLen, 0)
                pts := [[cx, cy - head - 2], [cx + head, cy + 1], [cx - head, cy + 1]]
            case "Down":
                this.FillRoundRect(gr, argb, cx - shaftW / 2, cy - shaftLen + 1, shaftW, shaftLen, 0)
                pts := [[cx - head, cy - 1], [cx + head, cy - 1], [cx, cy + head + 2]]
            case "Left":
                this.FillRoundRect(gr, argb, cx - 1, cy - shaftW / 2, shaftLen, shaftW, 0)
                pts := [[cx - head - 2, cy], [cx + 1, cy - head], [cx + 1, cy + head]]
            default:
                this.FillRoundRect(gr, argb, cx - shaftLen + 1, cy - shaftW / 2, shaftLen, shaftW, 0)
                pts := [[cx - 1, cy - head], [cx + head + 2, cy], [cx - 1, cy + head]]
        }
        this.FillPolygon(gr, argb, pts)
    }

    static _KeycapPalette(visualState) {
        switch visualState {
            case "on":
                return { bg: UiTheme.KeyCapOnBg, border: UiTheme.KeyCapOnBorder, text: UiTheme.KeyOn, hint: UiTheme.KeyCapHintOn }
            case "override":
                return { bg: UiTheme.KeyCapOvBg, border: UiTheme.KeyCapOvBorder, text: UiTheme.KeyOv, hint: UiTheme.KeyCapHintOv }
            case "locked":
                return { bg: UiTheme.KeyCapLockedBg, border: UiTheme.KeyCapLockedBorder, text: UiTheme.KeyCapLockedText, hint: UiTheme.KeyCapHintLocked }
            default:
                return { bg: UiTheme.KeyCapOffBg, border: UiTheme.KeyCapOffBorder, text: UiTheme.KeyOff, hint: UiTheme.KeyCapOffBorder }
        }
    }

    static _DarkenArgb(argb, factor) {
        a := (argb >> 24) & 0xFF
        r := Max(0, Round(((argb >> 16) & 0xFF) * factor))
        g := Max(0, Round(((argb >> 8) & 0xFF) * factor))
        b := Max(0, Round((argb & 0xFF) * factor))
        return (a << 24) | (r << 16) | (g << 8) | b
    }

    static _LightenArgb(argb, amount) {
        a := (argb >> 24) & 0xFF
        r0 := (argb >> 16) & 0xFF
        g0 := (argb >> 8) & 0xFF
        b0 := argb & 0xFF
        r := Min(255, Round(r0 + (255 - r0) * amount))
        g := Min(255, Round(g0 + (255 - g0) * amount))
        b := Min(255, Round(b0 + (255 - b0) * amount))
        return (a << 24) | (r << 16) | (g << 8) | b
    }

    static RenderToggleBitmap(w, h, on) {
        GdiPlusSession.EnsureStarted()
        pBitmap := 0
        stride := ((w * 4 + 3) // 4) * 4
        if DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", w, "int", h, "int", stride, "int", this.PixelFormat32bppARGB, "ptr", 0, "ptr*", &pBitmap := 0) != 0 || !pBitmap {
            return 0
        }
        try {
            gr := 0
            if DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", pBitmap, "ptr*", &gr := 0) != 0 || !gr {
                return 0
            }
            try {
                DllCall("gdiplus\GdipSetSmoothingMode", "ptr", gr, "int", 4)
                DllCall("gdiplus\GdipGraphicsClear", "ptr", gr, "uint", 0)
                th := h - 2
                tw := w - 2
                trackArgb := on ? this.HexRgbToARGB(UiTheme.SwitchTrackOn) : this.HexRgbToARGB(UiTheme.KeyCellBg)
                this.FillRoundRect(gr, trackArgb, 1, 1, tw, th, th / 2)
                this.StrokeRoundRect(gr, 0x22000000, 1, 1, tw, th, th / 2, 1)
                ks := th - 4
                kx := on ? (1 + tw - ks - 2) : 3
                ky := 3
                knobFill := this.HexRgbToARGB("FFFFFF")
                this.FillRoundRect(gr, knobFill, kx, ky, ks, ks, ks / 2)
                this.StrokeRoundRect(gr, 0x22000000, kx, ky, ks, ks, ks / 2, 1)
            } finally {
                DllCall("gdiplus\GdipDeleteGraphics", "ptr", gr)
            }
            return this.BitmapToHBITMAP(pBitmap)
        } finally {
            DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
        }
    }
}
