SendIP(keyCode, pressDurationMs := 8) {
    Critical("On")
    try {
        SendEvent("{Blind}{" keyCode " Down}")
        if (pressDurationMs > 0) {
            Sleep(pressDurationMs)
        }
        SendEvent("{Blind}{" keyCode " Up}")
    } finally {
        Critical("Off")
    }
}
