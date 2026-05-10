#Requires AutoHotkey v2.0

; 管理 DNF 窗口组、前台状态缓存和失焦回调。
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
        ; 兼容不同地区与版本的窗口标题和进程名。
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

    ; 立即同步窗口状态，并在刚失焦时触发回调。
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

    ; 供 AppTip 等即时逻辑主动刷新，避免依赖定时器缓存。
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

    ; 与 RegisterFocusLost 成对使用，传入同一个函数对象即可解绑。
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
