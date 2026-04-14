global __AutoRunPressingRight := false
global __AutoRunDoubleRight := false
global __AutoRunRightCounter := 0
global __AutoRunPressingLeft := false
global __AutoRunDoubleLeft := false
global __AutoRunLeftCounter := 0
global __AutoRunRightPulseSend := "{Right Down}{Right Up}{Right Down}"
global __AutoRunRightUpSend := "{Right Up}"
global __AutoRunLeftPulseSend := "{Left Down}{Left Up}{Left Down}"
global __AutoRunLeftUpSend := "{Left Up}"

ExAutoRun(){
    ProcessSetPriority("High")
    SetStoreCapsLockMode(false)
    SetDNFWindowClass()
    ; 子进程入口默认会 Suspend(true)，自动奔跑依赖热键回调，需显式恢复
    Suspend(false)
    presetName := LoadLastPreset()
    leftKey := LoadPreset(presetName, "AutoRunLeftKey", "Left")
    rightKey := LoadPreset(presetName, "AutoRunRightKey", "Right")
    if (leftKey = "") {
        leftKey := "Left"
    }
    if (rightKey = "") {
        rightKey := "Right"
    }
    __AutoRunRightPulseSend := "{" rightKey " Down}{" rightKey " Up}{" rightKey " Down}"
    __AutoRunRightUpSend := "{" rightKey " Up}"
    __AutoRunLeftPulseSend := "{" leftKey " Down}{" leftKey " Up}{" leftKey " Down}"
    __AutoRunLeftUpSend := "{" leftKey " Up}"
    __AutoRunPressingRight := false
    __AutoRunDoubleRight := false
    __AutoRunRightCounter := 0
    __AutoRunPressingLeft := false
    __AutoRunDoubleLeft := false
    __AutoRunLeftCounter := 0

    HotIfWinActive("ahk_group DNF")
    Hotkey("~" rightKey, ExAutoRunRightDown, "On")
    Hotkey("~" rightKey " Up", ExAutoRunRightUp, "On")
    Hotkey("~" leftKey, ExAutoRunLeftDown, "On")
    Hotkey("~" leftKey " Up", ExAutoRunLeftUp, "On")
    HotIf

    loop {
        Sleep(1000)
    }
}

ExAutoRunRightDown(*) {
    global __AutoRunPressingRight, __AutoRunDoubleRight, __AutoRunRightCounter
    if !__AutoRunPressingRight {
        __AutoRunPressingRight := true
        __AutoRunDoubleRight := false
        __AutoRunRightCounter := 0
        SetTimer(ExAutoRunRightHoldTick, 25)
    }
}

ExAutoRunRightUp(*) {
    global __AutoRunPressingRight
    global __AutoRunRightUpSend
    __AutoRunPressingRight := false
    SetTimer(ExAutoRunRightHoldTick, 0)
    SendEvent(__AutoRunRightUpSend)
}

ExAutoRunRightHoldTick() {
    global __AutoRunPressingRight, __AutoRunDoubleRight, __AutoRunRightCounter
    global __AutoRunRightPulseSend
    __AutoRunRightCounter++
    if (__AutoRunPressingRight && !__AutoRunDoubleRight) {
        SendEvent(__AutoRunRightPulseSend)
        __AutoRunDoubleRight := true
    }
    if (__AutoRunRightCounter >= 3) {
        SetTimer(ExAutoRunRightHoldTick, 0)
    }
}

ExAutoRunLeftDown(*) {
    global __AutoRunPressingLeft, __AutoRunDoubleLeft, __AutoRunLeftCounter
    if !__AutoRunPressingLeft {
        __AutoRunPressingLeft := true
        __AutoRunDoubleLeft := false
        __AutoRunLeftCounter := 0
        SetTimer(ExAutoRunLeftHoldTick, 25)
    }
}

ExAutoRunLeftUp(*) {
    global __AutoRunPressingLeft
    global __AutoRunLeftUpSend
    __AutoRunPressingLeft := false
    SetTimer(ExAutoRunLeftHoldTick, 0)
    SendEvent(__AutoRunLeftUpSend)
}

ExAutoRunLeftHoldTick() {
    global __AutoRunPressingLeft, __AutoRunDoubleLeft, __AutoRunLeftCounter
    global __AutoRunLeftPulseSend
    __AutoRunLeftCounter++
    if (__AutoRunPressingLeft && !__AutoRunDoubleLeft) {
        SendEvent(__AutoRunLeftPulseSend)
        __AutoRunDoubleLeft := true
    }
    if (__AutoRunLeftCounter >= 3) {
        SetTimer(ExAutoRunLeftHoldTick, 0)
    }
}
