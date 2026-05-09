#Requires AutoHotkey v2.0

; 进程内唯一 GDI+ 会话（与截图/PNG 保存、GUI 自绘共用）。
class GdiPlusSession {
    static _token := 0
    static _oleInited := false

    static EnsureStarted() {
        if this._token {
            return this._token
        }
        DllCall("ole32\OleInitialize", "ptr", 0)
        this._oleInited := true
        si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
        NumPut("uint", 1, si, 0)
        if (A_PtrSize = 8) {
            NumPut("ptr", 0, si, 8)
            NumPut("int", 0, si, 16)
            NumPut("int", 0, si, 20)
        } else {
            NumPut("ptr", 0, si, 4)
            NumPut("int", 0, si, 8)
            NumPut("int", 0, si, 12)
        }
        if DllCall("gdiplus\GdiplusStartup", "ptr*", &pToken := 0, "ptr", si, "ptr", 0) != 0 {
            throw Error("GdiplusStartup failed")
        }
        this._token := pToken
        return pToken
    }

    static Shutdown() {
        if this._token {
            DllCall("gdiplus\GdiplusShutdown", "ptr", this._token)
            this._token := 0
        }
        if this._oleInited {
            DllCall("ole32\OleUninitialize")
            this._oleInited := false
        }
    }

    static Token => this._token
}
