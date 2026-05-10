SendIP(keyCode) {
    Critical("On")
    try {
        SetKeyDelay(-1, 8)
        SendEvent("{Blind}{" keyCode "}")
    } finally {
        Critical("Off")
    }
}
