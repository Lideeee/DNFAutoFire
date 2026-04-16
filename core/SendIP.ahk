SendIP(keyCode){
    ; DNF 对“按下时长”较敏感：过短的 tap 可能被吞。
    ; 这里保留 Down/Up，并用一个很短的按住时长（默认 8ms）提高识别率。
    ; 同时避免长时间 Critical 抢占：只在发送瞬间 Critical。
    holdMs := 8
    try {
        Critical("On")
        SendInput("{Blind}{" keyCode " DownTemp}")
        Critical("Off")

        ; 在不占用 Critical 的情况下维持短按住
        DllCall("Sleep", "UInt", holdMs)

        Critical("On")
        SendInput("{Blind}{" keyCode " Up}")
    } finally {
        Critical("Off")
    }
}