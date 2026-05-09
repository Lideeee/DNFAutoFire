#Requires AutoHotkey v2.0

; 统一按键分发：同一物理键只注册一对 Hotkey，按下/抬起时广播给所有订阅者（主连发、战法等）
;
; 契约：SubscribeDown / SubscribeUp 仅在「真实边沿」触发——Windows 在按住期间会反复产生 KeyDown（键位重复），
; 此处只把第一次 Down 当作按下边沿，后续重复 Down 不再转发。扩展功能无需再单独处理系统重复。
; （极少数焦点切换丢 KeyUp 时 held 状态可能偏差；停止连发 KeyRouter.ClearAll 会清空状态。）
; DNF 失焦时物理 KeyUp 可能发生在 HotIfWinActive 之外，由 GameContext 失焦事件触发 FlushAllHeld。
; UnsubscribeDown/Up 与 Subscribe 成对使用；某 scID 无任何订阅者时注销对应热键。ClearAll 仍用于整表重置（如启停连发）。

class KeyRouter {
    static _downSubs := Map()
    static _upSubs := Map()
    static _registeredScIDs := Map()
    ; 是否已从「边沿 Down」进入按住态；用于屏蔽键位重复产生的 Down
    static _heldFromEdge := Map()
    static _focusLostRegistered := false
    static _focusLostCb := 0

    ; scID 如 "sc01e" / "sc01E" 或单键名 "a"；统一小写 sc 前缀扫描码，避免同一键重复注册
    static _NormScID(scID) {
        s := Trim(scID "")
        if (s = "") {
            return ""
        }
        if RegExMatch(s, "i)^sc[0-9A-F]+$") {
            return StrLower(s)
        }
        return s
    }

    ; callback 为已 Bind 的函数对象，调用时无参。成功返回 true；参数无效或热键注册失败返回 false（不会入队回调）。
    static SubscribeDown(scID, callback) {
        if !IsObject(callback) {
            return false
        }
        id := KeyRouter._NormScID(scID)
        if (id = "") {
            return false
        }
        if !this._EnsureHotkey(id) {
            return false
        }
        if !this._downSubs.Has(id) {
            this._downSubs[id] := []
        }
        this._downSubs[id].Push(callback)
        return true
    }

    static SubscribeUp(scID, callback) {
        if !IsObject(callback) {
            return false
        }
        id := KeyRouter._NormScID(scID)
        if (id = "") {
            return false
        }
        if !this._EnsureHotkey(id) {
            return false
        }
        if !this._upSubs.Has(id) {
            this._upSubs[id] := []
        }
        this._upSubs[id].Push(callback)
        return true
    }

    ; 与 Subscribe 成对使用；须传入注册时的同一 callback 引用。该键 Down/Up 均无订阅者时注销热键。
    static UnsubscribeDown(scID, callback) {
        if !IsObject(callback) {
            return
        }
        id := KeyRouter._NormScID(scID)
        if (id = "") || !this._downSubs.Has(id) {
            return
        }
        this._RemoveCallback(this._downSubs[id], callback)
        if (this._downSubs[id].Length = 0) {
            this._downSubs.Delete(id)
        }
        this._SyncHotkeyRegistration(id)
    }

    static UnsubscribeUp(scID, callback) {
        if !IsObject(callback) {
            return
        }
        id := KeyRouter._NormScID(scID)
        if (id = "") || !this._upSubs.Has(id) {
            return
        }
        this._RemoveCallback(this._upSubs[id], callback)
        if (this._upSubs[id].Length = 0) {
            this._upSubs.Delete(id)
        }
        this._SyncHotkeyRegistration(id)
    }

    static _RemoveCallback(arr, callback) {
        loop arr.Length {
            i := A_Index
            if (arr[i] == callback) {
                arr.RemoveAt(i)
                return
            }
        }
    }

    static _HasAnySubs(id) {
        if this._downSubs.Has(id) && this._downSubs[id].Length {
            return true
        }
        if this._upSubs.Has(id) && this._upSubs[id].Length {
            return true
        }
        return false
    }

    static _SyncHotkeyRegistration(id) {
        if !this._HasAnySubs(id) {
            this._UnregisterHotkey(id)
        }
    }

    static _UnregisterHotkey(scID) {
        if !this._registeredScIDs.Has(scID) {
            return
        }
        try {
            HotIfWinActive("ahk_group DNF")
            try Hotkey("~$" scID, "Off")
            try Hotkey("~$" scID " up", "Off")
            HotIf()
        } catch {
            try HotIf()
        }
        this._registeredScIDs.Delete(scID)
        if this._heldFromEdge.Has(scID) {
            this._heldFromEdge.Delete(scID)
        }
        if this._downSubs.Has(scID) {
            this._downSubs.Delete(scID)
        }
        if this._upSubs.Has(scID) {
            this._upSubs.Delete(scID)
        }
    }

    ; 返回是否已为该 scID 注册（或本次成功注册）热键对
    static _EnsureHotkey(scID) {
        if this._registeredScIDs.Has(scID) {
            return true
        }
        this._registeredScIDs[scID] := true
        hkDown := "~$" scID
        hkUp := "~$" scID " up"
        try {
            HotIfWinActive("ahk_group DNF")
            Hotkey(hkDown, (*) => KeyRouter.OnKeyDown(scID), "On")
            Hotkey(hkUp, (*) => KeyRouter.OnKeyUp(scID), "On")
            HotIf()
            return true
        } catch {
            try HotIf()
            this._registeredScIDs.Delete(scID)
            return false
        }
    }

    static OnKeyDown(scID, *) {
        if this._heldFromEdge.Get(scID, false) {
            return
        }
        this._heldFromEdge[scID] := true
        if !this._downSubs.Has(scID) {
            return
        }
        for fn in this._downSubs[scID] {
            try fn()
        }
    }

    static OnKeyUp(scID, *) {
        if this._heldFromEdge.Has(scID) {
            this._heldFromEdge.Delete(scID)
        }
        if !this._upSubs.Has(scID) {
            return
        }
        for fn in this._upSubs[scID] {
            try fn()
        }
    }

    static ClearAll() {
        scList := []
        for scID in this._registeredScIDs {
            scList.Push(scID)
        }
        if (scList.Length) {
            try {
                HotIfWinActive("ahk_group DNF")
                for scID in scList {
                    try Hotkey("~$" scID, "Off")
                    try Hotkey("~$" scID " up", "Off")
                }
                HotIf()
            } catch {
                try HotIf()
            }
        }
        this._registeredScIDs := Map()
        this._downSubs := Map()
        this._upSubs := Map()
        this._heldFromEdge := Map()
    }

    ; 对所有仍处于「边沿按下」态的键合成 KeyUp，清除订阅者的定时器等（焦点切走时 HotIf 收不到 up）
    static FlushAllHeld() {
        scList := []
        for scID in this._heldFromEdge {
            scList.Push(scID)
        }
        for scID in scList {
            this.OnKeyUp(scID)
        }
    }

    static StartFocusWatcher() {
        GameContext.Init()
        if this._focusLostRegistered {
            return
        }
        this._focusLostCb := ObjBindMethod(this, "FlushAllHeld")
        GameContext.RegisterFocusLost(this._focusLostCb)
        this._focusLostRegistered := true
    }

    ; 仅撤销失焦 Flush；不关闭 GameContext（主界面与 Tick 仍依赖）。进程退出时在 StopAutoFire 之后由 CleanupOnExit 调用 GameContext.Shutdown。
    static StopFocusWatcher() {
        if !this._focusLostRegistered {
            return
        }
        if IsObject(this._focusLostCb) {
            GameContext.UnregisterFocusLost(this._focusLostCb)
        }
        this._focusLostCb := 0
        this._focusLostRegistered := false
    }
}
