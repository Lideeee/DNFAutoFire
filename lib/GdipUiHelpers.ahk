#Requires AutoHotkey v2.0

class GdipUiHelpers {
    static PixelFormat32bppARGB := 0x26200A
    static _bitmapCache := Map()

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

    static BitmapToHBITMAP(pBitmap) {
        hbm := 0
        if DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", pBitmap, "ptr*", &hbm := 0, "uint", 0) != 0 || !hbm {
            return 0
        }
        return hbm
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

    static CloneBitmapHandle(hbm) {
        if !hbm {
            return 0
        }
        return DllCall("user32\CopyImage", "ptr", hbm, "uint", 0, "int", 0, "int", 0, "uint", 0, "ptr")
    }

    static RenderKeycapBitmap(w, h, text, visualState, renderState, textSizePx, bold := false, keyName := "", showHint := false) {
        cacheKey := "keycap|" w "|" h "|" visualState "|" renderState "|" keyName "|" (showHint ? 1 : 0)
        if this._bitmapCache.Has(cacheKey) {
            hbm := this.CloneBitmapHandle(this._bitmapCache[cacheKey])
            if hbm {
                return hbm
            }
        }
        hbm := this._RenderKeycapBitmapUncached(w, h, text, visualState, renderState, textSizePx, bold, keyName, showHint)
        if !hbm {
            return 0
        }
        cloned := this.CloneBitmapHandle(hbm)
        if cloned {
            this._bitmapCache[cacheKey] := hbm
            return cloned
        }
        return hbm
    }

    static _RenderKeycapBitmapUncached(w, h, text, visualState, renderState, textSizePx, bold := false, keyName := "", showHint := false) {
        GdiPlusSession.EnsureStarted()
        scale := this._KeycapRenderScale(keyName)
        sw := w * scale
        sh := h * scale
        pSrcBitmap := 0
        srcStride := ((sw * 4 + 3) // 4) * 4
        if DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", sw, "int", sh, "int", srcStride, "int", this.PixelFormat32bppARGB, "ptr", 0, "ptr*", &pSrcBitmap := 0) != 0 || !pSrcBitmap {
            return 0
        }
        try {
            srcGr := 0
            if DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", pSrcBitmap, "ptr*", &srcGr := 0) != 0 || !srcGr {
                return 0
            }
            try {
                DllCall("gdiplus\GdipSetSmoothingMode", "ptr", srcGr, "int", 4)
                DllCall("gdiplus\GdipSetPixelOffsetMode", "ptr", srcGr, "int", 4)
                DllCall("gdiplus\GdipSetCompositingQuality", "ptr", srcGr, "int", 4)
                DllCall("gdiplus\GdipGraphicsClear", "ptr", srcGr, "uint", 0)
                this._PaintKeycap(srcGr, sw, sh, visualState, renderState, keyName, showHint, scale)
            } finally {
                DllCall("gdiplus\GdipDeleteGraphics", "ptr", srcGr)
            }

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
                    DllCall("gdiplus\GdipSetPixelOffsetMode", "ptr", gr, "int", 4)
                    DllCall("gdiplus\GdipSetCompositingQuality", "ptr", gr, "int", 4)
                    DllCall("gdiplus\GdipSetInterpolationMode", "ptr", gr, "int", this._KeycapInterpolationMode(keyName))
                    DllCall("gdiplus\GdipGraphicsClear", "ptr", gr, "uint", 0)
                    DllCall("gdiplus\GdipDrawImageRectRectI", "ptr", gr, "ptr", pSrcBitmap, "int", 0, "int", 0, "int", w, "int", h, "int", 0, "int", 0, "int", sw, "int", sh, "int", 2, "ptr", 0, "ptr", 0, "ptr", 0)
                } finally {
                    DllCall("gdiplus\GdipDeleteGraphics", "ptr", gr)
                }
                return this.BitmapToHBITMAP(pBitmap)
            } finally {
                DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
            }
        } finally {
            DllCall("gdiplus\GdipDisposeImage", "ptr", pSrcBitmap)
        }
    }

    static _KeycapRenderScale(keyName := "") {
        switch keyName {
            case "Up", "Down", "Left", "Right":
                return 4
            default:
                return 2
        }
    }

    static _KeycapInterpolationMode(keyName := "") {
        switch keyName {
            case "Up", "Down", "Left", "Right":
                return 7
            default:
                return 7
        }
    }

    static _PaintKeycap(gr, w, h, visualState, renderState, keyName := "", showHint := false, unit := 1.0) {
        global UiTheme
        pad := 1.0 * unit
        rr := 3.0 * unit
        palette := this._KeycapPalette(visualState)
        bg := this.HexRgbToARGB(palette.bg)
        border := this.HexRgbToARGB(palette.border)
        hint := this.HexRgbToARGB(palette.hint)
        border := this._BlendArgb(border, bg, 0.58)
        if (renderState = "hover") {
            border := this.HexRgbToARGB("0078D7")
            hint := this._BlendArgb(hint, this.HexRgbToARGB("7FAEEA"), 0.48)
        } else if (renderState = "pressed") {
            border := this.HexRgbToARGB("2563EB")
            hint := this._BlendArgb(hint, this.HexRgbToARGB("6F9AE2"), 0.52)
        }
        fillInset := 1.9 * unit
        strokeInset := 1.78 * unit
        strokeW := 0.22 * unit
        this.FillRoundRect(gr, bg, pad + fillInset, pad + fillInset, w - 2 * (pad + fillInset), h - 2 * (pad + fillInset), Max(0, rr - fillInset / 2))
        this.StrokeRoundRect(gr, border, pad + strokeInset, pad + strokeInset, w - 2 * (pad + strokeInset), h - 2 * (pad + strokeInset), Max(0, rr - strokeInset / 2), strokeW)
        this._DrawKeycapHint(gr, showHint, hint, w, h, pad, unit)
        if (keyName = "Win") {
            this._DrawWindowsGlyph(gr, palette.text, w, h, unit)
        } else if (keyName = "Up" || keyName = "Down" || keyName = "Left" || keyName = "Right") {
            this._DrawArrowGlyph(gr, palette.text, w, h, keyName, unit)
        }
    }

    static _DrawKeycapHint(gr, showHint, hintArgb, w, h, pad, unit := 1.0) {
        if !showHint {
            return
        }
        lineW := 8 * unit
        lineH := 2 * unit
        inset := 4 * unit
        x := w - pad - inset - lineW
        y := pad + inset
        this.FillRoundRect(gr, hintArgb, x, y, lineW, lineH, lineH / 2)
    }

    static _DrawWindowsGlyph(gr, colorHex, w, h, unit := 1.0) {
        argb := this.HexRgbToARGB(colorHex)
        glyphW := 16 * unit
        glyphH := 16 * unit
        gap := 2 * unit
        paneW := Floor((glyphW - gap) / 2)
        paneH := Floor((glyphH - gap) / 2)
        startX := Floor((w - glyphW) / 2)
        startY := Floor((h - glyphH) / 2)
        this.FillRoundRect(gr, argb, startX, startY, paneW, paneH, 0)
        this.FillRoundRect(gr, argb, startX + paneW + gap, startY, paneW, paneH, 0)
        this.FillRoundRect(gr, argb, startX, startY + paneH + gap, paneW, paneH, 0)
        this.FillRoundRect(gr, argb, startX + paneW + gap, startY + paneH + gap, paneW, paneH, 0)
    }

    static _DrawArrowGlyph(gr, colorHex, w, h, direction, unit := 1.0) {
        argb := this.HexRgbToARGB(colorHex)
        cx := Floor(w / 2.0)
        cy := Floor(h / 2.0)
        head := Round(3 * unit)
        shaftW := Max(1, Round(1 * unit))
        shaftLen := Round(9 * unit)
        switch direction {
            case "Up":
                shaftX := cx - Floor(shaftW / 2)
                shaftTop := cy - Round(1 * unit)
                this.FillRoundRect(gr, argb, shaftX, shaftTop, shaftW, shaftLen, 0)
                pts := [[cx, cy - head - Round(2 * unit)], [cx + head, cy + Round(1 * unit)], [cx - head, cy + Round(1 * unit)]]
            case "Down":
                shaftX := cx - Floor(shaftW / 2)
                shaftTop := cy - shaftLen + Round(1 * unit)
                this.FillRoundRect(gr, argb, shaftX, shaftTop, shaftW, shaftLen, 0)
                pts := [[cx - head, cy - Round(1 * unit)], [cx + head, cy - Round(1 * unit)], [cx, cy + head + Round(2 * unit)]]
            case "Left":
                shaftY := cy - Floor(shaftW / 2)
                shaftLeft := cx - Round(1 * unit)
                this.FillRoundRect(gr, argb, shaftLeft, shaftY, shaftLen, shaftW, 0)
                pts := [[cx - head - Round(2 * unit), cy], [cx + Round(1 * unit), cy - head], [cx + Round(1 * unit), cy + head]]
            default:
                shaftY := cy - Floor(shaftW / 2)
                shaftLeft := cx - shaftLen + Round(1 * unit)
                this.FillRoundRect(gr, argb, shaftLeft, shaftY, shaftLen, shaftW, 0)
                pts := [[cx - Round(1 * unit), cy - head], [cx + head + Round(2 * unit), cy], [cx - Round(1 * unit), cy + head]]
        }
        this.FillPolygon(gr, argb, pts)
    }

    static _KeycapPalette(visualState) {
        global UiTheme
        switch visualState {
            case "on":
                return { bg: UiTheme["KeyCapOnBg"], border: UiTheme["KeyCapOnBorder"], text: UiTheme["KeyOn"], hint: UiTheme["KeyCapHintOn"] }
            case "override":
                return { bg: UiTheme["KeyCapOvBg"], border: UiTheme["KeyCapOvBorder"], text: UiTheme["KeyOv"], hint: UiTheme["KeyCapHintOv"] }
            case "locked":
                return { bg: UiTheme["KeyCapLockedBg"], border: UiTheme["KeyCapLockedBorder"], text: UiTheme["KeyCapLockedText"], hint: UiTheme["KeyCapHintLocked"] }
            default:
                return { bg: UiTheme["KeyCapOffBg"], border: UiTheme["KeyCapOffBorder"], text: UiTheme["KeyOff"], hint: UiTheme["KeyCapOffBorder"] }
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

    static RenderToggleBitmap(w, h, progress, renderState := "normal") {
        step := Round(Max(0, Min(1, progress)) * 8)
        cacheKey := "toggle|" w "|" h "|" step "|" renderState
        if this._bitmapCache.Has(cacheKey) {
            hbm := this.CloneBitmapHandle(this._bitmapCache[cacheKey])
            if hbm {
                return hbm
            }
        }
        hbm := this._RenderToggleBitmapUncached(w, h, step / 8.0, renderState)
        if !hbm {
            return 0
        }
        cloned := this.CloneBitmapHandle(hbm)
        if cloned {
            this._bitmapCache[cacheKey] := hbm
            return cloned
        }
        return hbm
    }

    static _RenderToggleBitmapUncached(w, h, progress, renderState := "normal") {
        GdiPlusSession.EnsureStarted()
        global UiTheme
        scale := 4
        sw := w * scale
        sh := h * scale
        pSrcBitmap := 0
        srcStride := ((sw * 4 + 3) // 4) * 4
        if DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", sw, "int", sh, "int", srcStride, "int", this.PixelFormat32bppARGB, "ptr", 0, "ptr*", &pSrcBitmap := 0) != 0 || !pSrcBitmap {
            return 0
        }
        try {
            srcGr := 0
            if DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", pSrcBitmap, "ptr*", &srcGr := 0) != 0 || !srcGr {
                return 0
            }
            try {
                DllCall("gdiplus\GdipSetSmoothingMode", "ptr", srcGr, "int", 4)
                DllCall("gdiplus\GdipSetPixelOffsetMode", "ptr", srcGr, "int", 4)
                DllCall("gdiplus\GdipSetCompositingQuality", "ptr", srcGr, "int", 4)
                DllCall("gdiplus\GdipGraphicsClear", "ptr", srcGr, "uint", 0)
                this._PaintToggle(srcGr, sw, sh, progress, renderState, scale)
            } finally {
                DllCall("gdiplus\GdipDeleteGraphics", "ptr", srcGr)
            }

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
                    DllCall("gdiplus\GdipSetPixelOffsetMode", "ptr", gr, "int", 4)
                    DllCall("gdiplus\GdipSetCompositingQuality", "ptr", gr, "int", 4)
                    DllCall("gdiplus\GdipSetInterpolationMode", "ptr", gr, "int", 7)
                    DllCall("gdiplus\GdipGraphicsClear", "ptr", gr, "uint", 0)
                    DllCall("gdiplus\GdipDrawImageRectRectI"
                        , "ptr", gr
                        , "ptr", pSrcBitmap
                        , "int", 0, "int", 0, "int", w, "int", h
                        , "int", 0, "int", 0, "int", sw, "int", sh
                        , "int", 2
                        , "ptr", 0, "ptr", 0, "ptr", 0)
                } finally {
                    DllCall("gdiplus\GdipDeleteGraphics", "ptr", gr)
                }
                return this.BitmapToHBITMAP(pBitmap)
            } finally {
                DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
            }
        } finally {
            DllCall("gdiplus\GdipDisposeImage", "ptr", pSrcBitmap)
        }
    }

    static _PaintToggle(gr, w, h, progress, renderState := "normal", unit := 1.0) {
        global UiTheme
        pad := 1.0 * unit
        trackW := w - 2 * pad
        trackH := h - 2 * pad
        radius := trackH / 2

        offColor := this._ToggleStateColor("off", renderState)
        onColor := this._ToggleStateColor("on", renderState)
        borderColor := this._ToggleBorderColor(progress, renderState)
        thumbColor := renderState = "pressed"
            ? this.HexRgbToARGB(UiTheme["SwitchThumbPressed"])
            : this.HexRgbToARGB(UiTheme["SwitchThumb"])

        shellInset := 0.6 * unit
        innerInset := 1.45 * unit
        shellRadius := Max(0, radius - shellInset / 2)
        innerRadius := Max(0, radius - innerInset)
        trackArgb := this._BlendArgb(offColor, onColor, progress)
        this.FillRoundRect(gr, borderColor, pad + shellInset, pad + shellInset, trackW - shellInset * 2, trackH - shellInset * 2, shellRadius)
        this.FillRoundRect(gr, trackArgb, pad + innerInset, pad + innerInset, trackW - innerInset * 2, trackH - innerInset * 2, innerRadius)

        knobInset := 3.0 * unit
        knobBaseSize := trackH - knobInset * 2 + 1.4 * unit
        knobGrow := 0.0
        if (renderState = "hover") {
            knobGrow := 1.1 * unit
        } else if (renderState = "pressed") {
            knobGrow := 0.8 * unit
        }
        knobSize := knobBaseSize + knobGrow
        knobTravel := trackW - knobSize - knobInset * 2
        knobX := pad + knobInset + knobTravel * progress
        knobY := pad + (trackH - knobSize) / 2
        if (renderState = "pressed") {
            knobX += progress >= 0.5 ? 0.35 * unit : -0.35 * unit
        }
        if (renderState = "hover") {
            knobY -= 0.1 * unit
        }
        thumbShade := renderState = "pressed" ? 0x12000000 : 0x0A000000
        shadowOffset := renderState = "pressed" ? 0.3 * unit : 0.55 * unit
        this.FillRoundRect(gr, thumbShade, knobX + shadowOffset, knobY + shadowOffset, knobSize - shadowOffset * 1.6, knobSize - shadowOffset * 1.2, Max(0, knobSize / 2 - shadowOffset))
        this.FillRoundRect(gr, thumbColor, knobX, knobY, knobSize, knobSize, knobSize / 2)
    }

    static _ToggleStateColor(kind, renderState := "normal") {
        global UiTheme
        if (kind = "on") {
            switch renderState {
                case "hover":
                    return this.HexRgbToARGB(UiTheme["SwitchTrackOnHover"])
                case "pressed":
                    return this.HexRgbToARGB(UiTheme["SwitchTrackOnPressed"])
                default:
                    return this.HexRgbToARGB(UiTheme["SwitchTrackOn"])
            }
        }
        switch renderState {
            case "hover":
                return this.HexRgbToARGB(UiTheme["SwitchTrackOffHover"])
            case "pressed":
                return this.HexRgbToARGB(UiTheme["SwitchTrackOffPressed"])
            default:
                return this.HexRgbToARGB(UiTheme["SwitchTrackOff"])
        }
    }

    static _ToggleBorderColor(progress, renderState := "normal") {
        global UiTheme
        offBorder := this.HexRgbToARGB(UiTheme["SwitchBorder"])
        onBorder := this.HexRgbToARGB(UiTheme["SwitchBorderOn"])
        mixed := this._BlendArgb(offBorder, onBorder, progress)
        if (renderState = "hover") {
            return this._LightenArgb(mixed, 0.08)
        }
        if (renderState = "pressed") {
            return this._DarkenArgb(mixed, 0.92)
        }
        return mixed
    }

    static _BlendArgb(fromArgb, toArgb, progress) {
        p := Max(0, Min(1, progress))
        a0 := (fromArgb >> 24) & 0xFF, r0 := (fromArgb >> 16) & 0xFF, g0 := (fromArgb >> 8) & 0xFF, b0 := fromArgb & 0xFF
        a1 := (toArgb >> 24) & 0xFF, r1 := (toArgb >> 16) & 0xFF, g1 := (toArgb >> 8) & 0xFF, b1 := toArgb & 0xFF
        a := Round(a0 + (a1 - a0) * p)
        r := Round(r0 + (r1 - r0) * p)
        g := Round(g0 + (g1 - g0) * p)
        b := Round(b0 + (b1 - b0) * p)
        return (a << 24) | (r << 16) | (g << 8) | b
    }
}
