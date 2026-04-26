ExCombo() {
    ProcessSetPriority("High")
    SetDNFWindowClass()
    presetName := LoadLastPreset()
    if !LoadPreset(presetName, "ComboState", false) {
        return
    }

    triggerKey := LoadPreset(presetName, "ComboTriggerKey", "X")
    if (triggerKey = "") {
        triggerKey := "X"
    }
    loopMode := LoadPreset(presetName, "ComboLoopMode", false)
    comboSkills := ExComboLoadSkills(presetName)
    if (comboSkills.Length = 0) {
        return
    }

    triggerPressKey := Key2PressKey(triggerKey)
    waitingRelease := false
    loop {
        if WinActive("ahk_group DNF") {
            triggerDown := GetKeyState(triggerPressKey, "P")
            if (loopMode) {
                if (triggerDown) {
                    ExComboRunOnce(comboSkills, triggerPressKey, true)
                }
            } else {
                if (triggerDown && !waitingRelease) {
                    ExComboRunOnce(comboSkills, triggerPressKey, false)
                    waitingRelease := true
                } else if (!triggerDown) {
                    waitingRelease := false
                }
            }
        } else {
            waitingRelease := false
        }
        Sleep(1)
    }
}

ExComboRunOnce(comboSkills, triggerPressKey, breakOnRelease) {
    loop comboSkills.Length {
        if !comboSkills.Has(A_Index) {
            continue
        }
        if (breakOnRelease && !GetKeyState(triggerPressKey, "P")) {
            return
        }
        item := comboSkills[A_Index]
        if !IsObject(item) {
            continue
        }
        SendIP(Key2NoVkSC(item.key))

        delay := item.delay + 0
        if (delay <= 0) {
            continue
        }
        beginTick := A_TickCount
        while (A_TickCount - beginTick < delay) {
            if (breakOnRelease && !GetKeyState(triggerPressKey, "P")) {
                return
            }
            Sleep(1)
        }
    }
}

ExComboLoadSkills(presetName) {
    items := []
    raw := LoadPreset(presetName, "ComboSkills", "")
    for unit in StrSplit(raw, "|") {
        unit := Trim(unit)
        if (unit = "") {
            continue
        }
        parts := StrSplit(unit, ",")
        if (parts.Length < 1) {
            continue
        }
        key := Trim(parts[1])
        if (key = "") {
            continue
        }
        delay := 20
        if (parts.Length >= 2) {
            delay := Round(parts[2] + 0)
        }
        if (delay < 20) {
            delay := 20
        } else if (delay > 3000) {
            delay := 3000
        }
        items.Push({ key: key, delay: delay })
    }
    return items
}
