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

    static DrawStringCentered(gr, text, face, sizePx, argb, x, y, w, h) {
        if (text = "") {
            return
        }
        try DllCall("gdiplus\GdipSetTextRenderingHint", "ptr", gr, "int", 5) ; ClearTypeGridFit
        try DllCall("gdiplus\GdipSetPixelOffsetMode", "ptr", gr, "int", 2) ; Half
        ff := 0
        st := DllCall("gdiplus\GdipCreateFontFamilyFromName", "wstr", face, "ptr", 0, "ptr*", &ff := 0)
        if (st != 0 || !ff) {
            return
        }
        try {
            pFont := 0
            if DllCall("gdiplus\GdipCreateFont", "ptr", ff, "float", sizePx, "int", 0, "int", 0, "ptr*", &pFont := 0) != 0 || !pFont {
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

    static _DarkenArgb(argb, factor) {
        a := (argb >> 24) & 0xFF
        r := Max(0, Round(((argb >> 16) & 0xFF) * factor))
        g := Max(0, Round(((argb >> 8) & 0xFF) * factor))
        b := Max(0, Round((argb & 0xFF) * factor))
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
