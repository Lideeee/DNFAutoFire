AutoFire(key){
    keyCode := Key2NoVkSC(key)
    pressKey := Key2PressKey(key)
    loop {
        while (GetKeyState(pressKey, "P")) {
            SendIP(keyCode)
        }
        Sleep(1)
    }
}