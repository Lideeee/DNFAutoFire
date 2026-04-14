full_command_line := DllCall("GetCommandLine", "Str")

; 需要管理员时先尝试 UAC 提升；若用户取消或失败，则提示并以普通权限继续（避免进程静默退出）
if !(A_IsAdmin || RegExMatch(full_command_line, " /restart(?!\S)")) {
    try {
        if A_IsCompiled {
            Run('*RunAs "' A_ScriptFullPath '" /restart')
        } else {
            Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
        }
    } catch Error as err {
        MsgBox(
            "未能自动获取管理员权限（例如已取消 UAC 提示）。`n"
            "将尝试以当前用户权限运行；若连发无效，请右键脚本选择「以管理员身份运行」。`n`n"
            "详情: " err.Message,
            "DAF连发工具",
            "Icon!"
        )
    } else {
        ExitApp()
    }
}