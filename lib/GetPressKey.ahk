GetPressKey(){
    return GetUserInputKey()
}

GetUserInputKey(){
    ; 给出可见提示，避免用户误以为按钮无响应
    ToolTip("请按下一个按键，Esc清空")
    try {
        ih := InputHook("L0")
        ih.KeyOpt("{All}", "E")
        ih.KeyOpt("{LWin}{RWin}{AppsKey}", "-E")
        ih.Start()
        ih.Wait()
        key := ih.EndKey
        ; Escape：清空（不写入 Esc）；含 InputHook 用 Esc 结束时的 EndReason
        k := StrLower(key)
        if (ih.EndReason = "Escape" || k = "esc" || k = "escape") {
            return ""
        }
        if (StrLen(key) == 1) {
            key := Format("{:U}", key)
        }
        return key
    } finally {
        ToolTip()
    }
}