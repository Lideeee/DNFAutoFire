#Requires AutoHotkey v2.0

; 会话态：当前预设、连发启用键列表、主连发定时器注册表（非持久化）

class SessionState {
    static CurrentPreset := ""
    static AutoFireEnableKeys := []
    static AutoFireMainHotkeyRegs := []

    static InitFromLastPreset() {
        this.CurrentPreset := LoadLastPresetTrimmed()
    }

    static SetCurrentPreset(name) {
        this.CurrentPreset := name
    }

    static GetCurrentPreset() {
        return this.CurrentPreset
    }

    static IsKeyAutoFire(key) {
        for k in this.AutoFireEnableKeys {
            if (k == key) {
                return true
            }
        }
        return false
    }
}

GetNowSelectPreset() => SessionState.GetCurrentPreset()

SetNowSelectPreset(name) {
    SessionState.SetCurrentPreset(name)
}
