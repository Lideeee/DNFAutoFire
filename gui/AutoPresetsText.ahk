#Requires AutoHotkey v2.0

global AutoPresetsText := Map(
    "SectionTitle", "自动识别配置",
    "Enable", "启用自动识别",
    "PresetList", "配置列表",
    "SkillIconList", "技能图列表",
    "RenameSkillIconTitle", "重命名",
    "RenameSkillIconPrompt", "请输入名称",
    "ExtraHotkey", "冒险团玩法信息",
    "CurrentPreset", "当前配置",
    "SkillReference", "技能图（双击改名）",
    "CaptureReference", "截取",
    "DeleteReference", "删除",
    "PickSkillRegion", "框选技能区",
    "PickTownRegion", "框选城镇区",
    "TownReference", "城镇识别图（进图截灰色）",
    "TownResolutionList", "分辨率",
    "CaptureTown", "截取",
    "DeleteTown", "删除",
    "Save", "保存",
    "HelpTitle", "自动识别说明",
    "Help", "按 Esc 或附加键会触发搜图。启动连发或按下快捷键后开始识别，并自动切换角色，只要不是纯鼠标切换角色都能自动识别。`n`n流程：框选城镇判定区域并截取城镇参考图；为各配置可绑定多张技能图（双击可改名）。点击截取会自动为当前配置新增一张技能图。匹配到对应配置才切换，技能识别失败不切换。",
    "SkillRegion", "技能识别区域",
    "TownRegion", "城镇识别区域",
    "RegionPickHint", "Enter确认，Esc取消"
)
