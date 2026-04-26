; 勿命名为 Thread：AHK v2 标准库已有内置 Thread 类，会覆盖 ScriptStart 等调用
class SubProcessThread
{
    __New(RunLabelOrFunc)
    {
        args := "/Run=" RunLabelOrFunc
        ; v2：命令行为 "解释器" "脚本" "参数"，勿插入 v1 式 /f，否则会把 /f 当成脚本路径
        if (A_IsCompiled) {
            Run('"' A_ScriptFullPath '" "' args '"', , , &pid)
        } else {
            Run('"' A_AhkPath '" "' A_ScriptFullPath '" "' args '"', , , &pid)
        }
        this.pid := pid
    }
    __Delete()
    {
        try ProcessClose(this.pid)
    }
    static ScriptStart()
    {
        if (A_Args.Length < 1 || !InStr(A_Args[1], "/Run="))
        {
            return
        }
        ; 子进程仅负责连发逻辑，不显示托盘图标，避免任务栏出现大量 H 图标
        A_IconHidden := true
        Suspend(true)
        k := SubStr(A_Args[1], 6)
        ; v2 函数名不能以数字开头，所以将数字按键映射到 Keys.ahk 中的 Key1~Key0
        if RegExMatch(k, "^\d$") {
            k := "Key" k
        }
        try {
            if (k = "ReleaseKeys") {
                ReleaseKeys()
            } else if (k = "ExLvRen") {
                ExLvRen()
            } else if (k = "ExGuanYu") {
                ExGuanYu()
            } else if (k = "ExPetSkill") {
                ExPetSkill()
            } else if (k = "ExZhanFa") {
                ExZhanFa()
            } else if (k = "ExJianZong") {
                ExJianZong()
            } else if (k = "ExAutoRun") {
                ExAutoRun()
            } else if (k = "ExCombo") {
                ExCombo()
            } else {
                ; 普通按键线程：直接走 AutoFire，避免 Func("F").Call() 在部分环境异常
                AutoFire(GetOriginKeyName(k))
            }
        } catch as err {
            ; 线程启动异常时保持静默，避免影响主流程
        }
        ExitApp()
    }
}