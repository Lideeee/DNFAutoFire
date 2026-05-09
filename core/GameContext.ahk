#Requires AutoHotkey v2.0

; DNF 窗口组、前台/存在状态缓存与失焦回调（业务读 IsActive / Exists / DnfHwnd；热键仍用 HotIfWinActive）

class GameContext {
    static IsActive := false
    static Exists := false
    static DnfHwnd := 0
    static _inited := false
    static _timerFn := 0
    static _FocusLostCallbacks := []

    static Init() {
        if this._inited {
            return
        }
        this._inited := true
        this._AddDnfGroup()
        this._RefreshWindowState()
        this._timerFn := ObjBindMethod(this, "_Tick")
        SetTimer(this._timerFn, 80)
    }

    static Shutdown() {
        if !this._inited {
            return
        }
        SetTimer(this._timerFn, 0)
        this._timerFn := 0
        this._inited := false
        this._FocusLostCallbacks := []
    }

    static _AddDnfGroup() {
        ; 与旧 SetDNFWindowClass 一致：标题 + 进程（不加错误 ahk_class）
        GroupAdd("DNF", "地下城与勇士")
        GroupAdd("DNF", "Dungeon & Fighter")
        GroupAdd("DNF", "Dungeon Fighter Online")
        GroupAdd("DNF", "次元对决")
        GroupAdd("DNF", "ahk_exe dnf.exe")
        GroupAdd("DNF", "ahk_exe DNF.exe")
        GroupAdd("DNF", "ahk_exe DungeonFighter.exe")
        GroupAdd("DNF", "ahk_exe DFO.exe")
        GroupAdd("DNF", "ahk_exe DNF_SGM.exe")
    }

    static _RefreshWindowState() {
        this.IsActive := this.IsActiveNow()
        hwnd := WinExist("ahk_group DNF")
        this.DnfHwnd := hwnd ? hwnd : 0
        this.Exists := this.DnfHwnd != 0
    }

    static IsActiveNow() {
        return WinActive("ahk_group DNF") != 0
    }

    ; 立刻从系统同步前台/存在/hwnd，并在「刚失焦」时触发失焦回调（与定时 Tick 语义一致）
    static _PulseFromOs() {
        wasActive := this.IsActive
        this._RefreshWindowState()
        if (wasActive && !this.IsActive) {
            this._OnFocusLost()
        }
    }

    static _Tick(*) {
        this._PulseFromOs()
    }

    ; AppTip 等需在弹出瞬间读到最新 hwnd/焦点，避免最多 80ms 缓存滞后；已 Init 时生效
    static RefreshNow() {
        if !this._inited {
            return
        }
        this._PulseFromOs()
    }

    static _OnFocusLost() {
        for cb in this._FocusLostCallbacks {
            try cb()
        }
    }

    static RegisterFocusLost(callback) {
        if !IsObject(callback) {
            return
        }
        this._FocusLostCallbacks.Push(callback)
    }

    ; 与 RegisterFocusLost 成对使用；须传入同一函数对象引用（例如 KeyRouter 保存的 ObjBindMethod 结果）
    static UnregisterFocusLost(callback) {
        if !IsObject(callback) {
            return
        }
        rest := []
        for cb in this._FocusLostCallbacks {
            if (cb != callback) {
                rest.Push(cb)
            }
        }
        this._FocusLostCallbacks := rest
    }

    static CheckExists() {
        return this.IsActive || this.Exists
    }
}
