#Requires AutoHotkey v2.0

global AutoPresetsText := Map(
    "SectionTitle", "自动识别配置",
    "Enable", "启用自动识别",
    "PresetList", "配置列表",
    "ExtraHotkey", "触发识别键（冒险团玩法信息）",
    "Capture", "设置快捷键",
    "CurrentPreset", "当前配置",
    "SkillReference", "技能识别图",
    "CaptureReference", "截取",
    "DeleteReference", "删除",
    "PickRegion", "框选区域…",
    "CalTownReference", "血条 / 城镇识别图",
    "UpdateCalibrate", "更新血条识别图",
    "UpdateTown", "更新城镇识别图",
    "Save", "保存",
    "HelpTitle", "自动识别说明",
    "Help", "连发运行且已开启本功能时，仅在 DNF 游戏窗口前台按 Esc 或附加键会触发搜图（其它窗口不响应）。启动连发后也会自动进入一次识别序列；若中途切出 DNF，会暂停重试，回到前台后继续。`n`n流程：框选血条区域并更新血条参考图；框选城镇判定区域并更新城镇参考图；为各配置截取技能栏小图。`n`n仅在城镇图匹配成功时才会切换配置；血条图用于对齐画面。",
    "SkillRegion", "技能识别区域",
    "CalibrateRegion", "血条识别区域",
    "TownRegion", "城镇识别区域",
    "RegionPickHint", "Enter确认，Esc取消"
)
