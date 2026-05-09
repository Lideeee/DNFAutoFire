#Requires AutoHotkey v2.0

global G_MAIN_EX_SWITCH_NAMES := ["LvRen", "GuanYu", "JianZong", "ZhanFa", "PetSkill", "AutoRun", "Combo"]

class MainWindow {
    Gui := 0
    Ctrls := 0
    ExSwitchUi := 0

    static EnsureBuilt() {
        static _singleton := unset
        if IsSet(_singleton) {
            return _singleton
        }
        global gMainGui, gMainCtrls, gMainExSwitchUi
        gMainGui := Gui("-MinimizeBox -MaximizeBox -Theme +OwnDialogs")
        gMainCtrls := Map()
        gMainExSwitchUi := Map()
        gMainGui.OnEvent("Escape", MainGuiEscape)
        gMainGui.OnEvent("Close", MainGuiClose)
        gMainGui.OnEvent("ContextMenu", MainGuiContextMenu)
        OnMessage(0x0201, MainPresetListOnLButtonDown)
        OnMessage(0x0202, MainPresetListOnLButtonUp)
        OnMessage(0x0200, MainPresetListOnMouseMove)
        GuiTheme_Apply(gMainGui)

        gMainGui.SetFont("s10 c" GuiTheme_Hint, GuiTheme_Face)
        gMainGui.Add("Text", "x16 y10 w590 h20 +0x200", "按键设置 - [ 黑色=关闭 红色=启用 蓝色=独立间隔（右键可设置独立间隔） ]")
        for item in [
            ["Esc","x16 y30 w36 h36"],["F1","x90 y30 w36 h36"],["F2","x130 y30 w36 h36"],["F3","x170 y30 w36 h36"],["F4","x210 y30 w36 h36"],["F5","x270 y30 w36 h36"],["F6","x310 y30 w36 h36"],["F7","x350 y30 w36 h36"],["F8","x390 y30 w36 h36"],["F9","x450 y30 w36 h36"],["F10","x490 y30 w36 h36"],["F11","x530 y30 w36 h36"],["F12","x570 y30 w36 h36"],
            ["Tilde","x16 y80 w36 h36","``"],["1","x56 y80 w36 h36"],["2","x96 y80 w36 h36"],["3","x136 y80 w36 h36"],["4","x176 y80 w36 h36"],["5","x216 y80 w36 h36"],["6","x256 y80 w36 h36"],["7","x296 y80 w36 h36"],["8","x336 y80 w36 h36"],["9","x376 y80 w36 h36"],["0","x416 y80 w36 h36"],["Sub","x456 y80 w36 h36","-"],["Add","x496 y80 w36 h36","+"],["Backspace","x536 y80 w70 h36","←"],
            ["Tab","x16 y120 w54 h36"],["Q","x74 y120 w36 h36"],["W","x114 y120 w36 h36"],["E","x154 y120 w36 h36"],["R","x194 y120 w36 h36"],["T","x234 y120 w36 h36"],["Y","x274 y120 w36 h36"],["U","x314 y120 w36 h36"],["I","x354 y120 w36 h36"],["O","x394 y120 w36 h36"],["P","x434 y120 w36 h36"],["LeftBracket","x474 y120 w36 h36","["],["RightBracket","x514 y120 w36 h36","]"],["Backslash","x554 y120 w52 h36","\"],
            ["Caps","x16 y160 w64 h36"],["A","x84 y160 w36 h36"],["S","x124 y160 w36 h36"],["D","x164 y160 w36 h36"],["F","x204 y160 w36 h36"],["G","x244 y160 w36 h36"],["H","x284 y160 w36 h36"],["J","x324 y160 w36 h36"],["K","x364 y160 w36 h36"],["L","x404 y160 w36 h36"],["Semicolon","x444 y160 w36 h36",";"],["QuotationMark","x484 y160 w36 h36","'"],["Enter","x524 y160 w82 h36"],
            ["LShift","x16 y200 w86 h36","Shift"],["Z","x106 y200 w36 h36"],["X","x146 y200 w36 h36"],["C","x186 y200 w36 h36"],["V","x226 y200 w36 h36"],["B","x266 y200 w36 h36"],["N","x306 y200 w36 h36"],["M","x346 y200 w36 h36"],["Comma","x386 y200 w36 h36",","],["Period","x426 y200 w36 h36","."],["Slash","x466 y200 w36 h36","/"],["RShift","x506 y200 w62 h36","Shift"],["Up","x572 y200 w36 h36","↑"],
            ["NumLk","x612 y80 w36 h36","Num"],["NumSlash","x652 y80 w36 h36","/"],["NumStar","x692 y80 w36 h36","*"],["NumSub","x732 y80 w36 h36","-"],
            ["Num7","x612 y120 w36 h36","7"],["Num8","x652 y120 w36 h36","8"],["Num9","x692 y120 w36 h36","9"],["NumAdd","x732 y120 w36 h76","+"],
            ["Num4","x612 y160 w36 h36","4"],["Num5","x652 y160 w36 h36","5"],["Num6","x692 y160 w36 h36","6"],
            ["Num1","x612 y200 w36 h36","1"],["Num2","x652 y200 w36 h36","2"],["Num3","x692 y200 w36 h36","3"],["NumEnter","x732 y200 w36 h76","Ent"],
            ["LCtrl","x16 y240 w48 h36","Ctrl"],["LAlt","x120 y240 w48 h36","Alt"],["Space","x172 y240 w216 h36"],["RAlt","x392 y240 w64 h36","Alt"],["RCtrl","x460 y240 w68 h36","Ctrl"],
            ["Left","x532 y240 w36 h36","←"],["Down","x572 y240 w36 h36","↓"],["Right","x612 y240 w36 h36","→"],
            ["Num0","x652 y240 w36 h36","0"],["NumPeriod","x692 y240 w36 h36","."]
        ] {
            name := item[1], pos := item[2], label := item.Length >= 3 ? item[3] : name
            fontSize := GuiTheme_MainKeyLabelFontSize(name)
            if MainKeyUiGrayOnly(name) {
                gMainGui.SetFont(fontSize, GuiTheme_Face)
                ctrl := MainAdd("Text", "v" name " " pos . GuiTheme_MainKeyCellSuffix(true), label)
            } else {
                gMainGui.SetFont(fontSize " c" GuiTheme_KeyOff, GuiTheme_Face)
                ctrl := MainAdd("Text", "v" name " " pos . GuiTheme_MainKeyCellSuffix(false), label)
                ctrl.OnEvent("Click", MainKeyClick)
            }
        }
        gMainGui.SetFont("s10 norm c334155", GuiTheme_Face)
        gMainGui.Add("Text", "x68 y240 w48 h36" . GuiTheme_MainKeyCellSuffix(true), "Win")
        gMainGui.SetFont("s9", GuiTheme_Face)
        MainAdd("Text", "vMainVersionText x612 y28 w100 h40", "版本信息：v" __Version "`n原作者：某亚瑟")
        gMainCtrls["MainClear"] := GuiTheme_FlatTextBtn(gMainGui, "vMainClear x732 y30 w36 h36", "清空", MainClear)
        gMainGui.SetFont("s10 norm c334155", GuiTheme_Face)
        gMainGui.SetFont("s10 norm c64748B", GuiTheme_Face)
        gMainGui.Add("Text", "x16 y" . (MAIN_BOTTOM_Y + 6) . " w324 h18 +0x200", "配置设置 - [ 单击切换配置，右键配置列表管理 ]")
        gMainGui.SetFont("s10 norm c334155", GuiTheme_Face)
        ; RFC: 虚拟列表 vs 原生 ListBox（预设拖拽）——后续单独方案；当前保留 ListBox 行为。
        MainAdd("ListBox", GuiTheme_MainCfgPresetListOpts("Preset", 16, MAIN_CFG_LIST_TOP, 150, MAIN_CFG_LIST_H))
        MainGetCtrl("Preset").OnEvent("Change", MainChangeListPreset)
        gMainGui.Add("Text", "x" . MAIN_CFG_FIELD_X . " y" . MAIN_CFG_LIST_TOP . " w" . MAIN_CFG_FIELD_W . " h24 +0x200", "当前配置名称：")
        MainAdd("Edit", "vPresetNameEdit x" . MAIN_CFG_FIELD_X . " y" . (MAIN_CFG_LIST_TOP + 24) . " w" . MAIN_CFG_FIELD_W . " h22 +ReadOnly -E0x200 Border")
        gMainGui.Add("Text", "x" . MAIN_CFG_FIELD_X . " y" . (MAIN_CFG_LIST_TOP + 50) . " w" . MAIN_CFG_FIELD_W . " h24 +0x200", "连发间隔(ms)")
        ctrlInterval := MainAdd("Edit", "vMainAutoFireInterval x" . MAIN_CFG_FIELD_X . " y" . (MAIN_CFG_LIST_TOP + 74) . " w" . MAIN_CFG_FIELD_W . " h22 +Number -E0x200 Border")
        ctrlInterval.OnEvent("Change", MainSaveAutoFireInterval)
        ctrlInterval.OnEvent("LoseFocus", MainCommitAutoFireInterval)
        gMainGui.SetFont("s9 norm c334155", GuiTheme_Face)
        gMainCtrls["MainPresetSkill"] := GuiTheme_FlatTextBtn(gMainGui, "vMainPresetSkill x" . MAIN_CFG_FIELD_X . " y" . MAIN_PRESET_BTN_Y . " w" . MAIN_CFG_FIELD_W . " h" . MAIN_PRESET_BTN_H, "自动识别配置", MainPresetSkill)
        gMainGui.SetFont("s10 norm c334155", GuiTheme_Face)
        gMainCtrls["MainSetting"] := GuiTheme_FlatTextBtn(gMainGui, "vMainSetting x" . MAIN_BTN_X . " y" . (MAIN_BOTTOM_Y + 5) . " w96 h60", "软件设置", MainSetting)
        gMainCtrls["MainCheckUpdate"] := GuiTheme_FlatTextBtn(gMainGui, "vMainCheckUpdate x" . MAIN_BTN_X . " y" . (MAIN_BOTTOM_Y + 72) . " w96 h60", "检查更新", MainCheckUpdate)
        gMainCtrls["MainStart"] := GuiTheme_FlatTextBtn(gMainGui, "vMainStart x" . MAIN_BTN_X . " y" . (MAIN_BOTTOM_Y + 140) . " w96 h60", "启动连发", MainStart)
        gMainGui.SetFont("s10 norm c64748B", GuiTheme_Face)
        gMainGui.Add("Text", "x334 y" . (MAIN_BOTTOM_Y + 6) . " w200 h18 +0x200", "其他功能")
        gMainGui.SetFont("s10 norm c334155", GuiTheme_Face)
        for n in G_MAIN_EX_SWITCH_NAMES {
            MainAdd("CheckBox", "v" n " Hidden x-2000 y-2000 w1 h1 -TabStop")
        }
        MAIN_OTHER_ROW := 36
        MAIN_OTHER_ROW0 := MAIN_BOTTOM_Y + 26
        MAIN_OTHER_COL1 := 334
        MAIN_OTHER_COL2 := 502
        MAIN_OTHER_TW := 40
        MAIN_OTHER_LW1 := 104
        MAIN_OTHER_LW2 := 84
        __mainExLi := 0
        for row in [
            ["LvRen", "旅人自动流星", MainLvRen],
            ["GuanYu", "关羽自动猛攻", MainGuanYu],
            ["JianZong", "太宗帝剑延迟", MainJianZong],
            ["ZhanFa", "战法自动炫纹", MainZhanFa],
        ] {
            __mainExLi += 1
            y := MAIN_OTHER_ROW0 + (__mainExLi - 1) * MAIN_OTHER_ROW
            MainAddExFeatureRow(row[1], MAIN_OTHER_COL1, y, MAIN_OTHER_TW, MAIN_OTHER_LW1, row[2], row[3])
        }
        __mainExRi := 0
        for row in [
            ["PetSkill", "自动宠物技能", MainPetSkill],
            ["AutoRun", "自动奔跑", MainAutoRun],
            ["Combo", "一键连招", MainCombo],
        ] {
            __mainExRi += 1
            y := MAIN_OTHER_ROW0 + (__mainExRi - 1) * MAIN_OTHER_ROW
            MainAddExFeatureRow(row[1], MAIN_OTHER_COL2, y, MAIN_OTHER_TW, MAIN_OTHER_LW2, row[2], row[3])
        }
        MainExSwitchPaintAll()

        inst := MainWindow()
        inst.Gui := gMainGui
        inst.Ctrls := gMainCtrls
        inst.ExSwitchUi := gMainExSwitchUi
        _singleton := inst
        return inst
    }

    GetCtrl(name) {
        global gMainCtrls
        return gMainCtrls.Has(name) ? gMainCtrls[name] : ""
    }
}
