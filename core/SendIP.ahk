SendIP(keyCode){
    ; 确保一次按下/抬起序列尽量原子，减少多键连发互相打断
    Critical("On")
    try {
        SendInput("{Blind}{" keyCode " DownTemp}")
        Sleep(1)
        SendInput("{Blind}{" keyCode " Up}")
        Sleep(1)
    } finally {
        Critical("Off")
    }
}