#Requires AutoHotkey v2.0

class ToggleGdip {
    __New(gui, x, y, tw, th) {
        GdiPlusSession.EnsureStarted()
        this.gui := gui
        this.x := x
        this.y := y
        this.tw := tw
        this.th := th
        this._on := false
        this._assignBitmap(GdipUiHelpers.RenderToggleBitmap(tw, th, false))
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

    Draw(on) {
        this._on := !!on
        this._assignBitmap(GdipUiHelpers.RenderToggleBitmap(this.tw, this.th, this._on))
    }

    OnClick(handler) {
        this.ctrl.OnEvent("Click", handler)
    }
}
