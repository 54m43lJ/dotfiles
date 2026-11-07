# monitor-control: 三种匹配模式的显示器配置

最终方案是 **纯 Lua**，只依赖 `hypr/monitor_control.lua`。monitor 规则的
应用、默认布局/scale 推导和 start/hotplug/reload 事件都在这个模块里；
`hypr/hyprland.lua` 只保留 workspace、唤醒恢复和自启动。

## 1. 三种匹配模式

| 模式 | profile 字段 | 匹配条件 | 优先级 |
|---|---|---|---|
| 双键 | `connector` + `description` | 两者同时精确相等 | 最高 |
| 单连接器 | 只有 `connector` | 连接器名相等，忽略描述 | 中 |
| 单描述 | 只有 `description` | 描述相等，忽略连接器 | 最低 |

优先级固定为：

```text
dual > connector-only > description-only
```

同一个显示器同时命中多种模式时，按上表取最高优先级；同一模式内重复定义
`(connector, description)` 相同的 profile，后定义的覆盖前定义的。

匹配是精确匹配，不做前缀、通配符或模糊匹配。`FALLBACK` 永远不匹配。

## 2. 怎么写 profile

### 双键：同一块面板，两条链路

```lua
local monitor_control = require("monitor_control")

monitor_control.define({
    {
        connector   = "DP-2",
        description = "HKC OVERSEAS LIMITED VG273U PRO 0000000000001",
        mode        = "highrr",
        position    = "auto",
        reserved    = { top = -5 },
        vrr         = 1,
    },
    {
        connector   = "HDMI-A-1",
        description = "HKC OVERSEAS LIMITED VG273U PRO 0000000000001",
        mode        = "3840x2160@60",
        position    = "auto",
        reserved    = { top = -5 },
        vrr         = 1,
    },
})
```

这是 `per-device-conf/pc_beijing/hypr.lua` 当前的内容：同一块 VG273U PRO
接在 dGPU DP 和 dock HDMI 时，分别应用 4K160 highrr / 4K60。`scale`
故意不写，由模块根据目标 mode 自动判断；当前两条链路都会得到 2x。

### 单连接器：这个端口固定一套配置

```lua
{
    connector = "DP-1",
    mode      = "2560x1440@165",
    vrr       = 1,
}
```

不管插什么显示器到 `DP-1`，都用这套配置。适合固定工位/固定线缆。

### 单描述：这块面板无论插哪个口都用同一套配置

```lua
{
    description = "HKC OVERSEAS LIMITED VG273U PRO 0000000000001",
    mode        = "highrr",
    vrr         = 1,
}
```

如果两块完全相同的面板同时连接，描述相同，会同时命中；需要区分时改回
双键或连接器模式。

### 必填与可选字段

- 至少要有 `connector` 或 `description` 其中一个。
- `connector` 非空字符串；`description` 字符串（允许 `""`）。
- 其他字段就是 `hl.monitor()` 支持的字段：
  `mode`、`position`、`scale`、`vrr`、`reserved`、`transform`、
  `disabled`、`bitdepth`、`cm`、`icc`、`mirror` 等。
- `scale` 可以省略；省略时按目标 mode / `available_modes` 自动推断。
  只有自动结果不符合预期时才需要显式覆盖。
- 未知字段直接报错，避免拼写错误静默失效。
- `description` 用 `hyprctl monitors -j` 里的 `description`（Hyprland 的
  short description：make + model + serial）。逗号会被 Hyprland 从 EDID
  描述里删掉，本模块也做同样的归一化。

## 3. 怎么查键

当前连接的显示器：

```bash
hyprctl monitors -j | jq -r '.[] | "\(.name)|\(.description)"'
```

被 `disabled = true` 规则关掉、普通列表看不到的，用：

```bash
hyprctl monitors all -j | jq -r '.[] | "\(.name)|\(.description)"'
```

输出：

```text
HDMI-A-1|HKC OVERSEAS LIMITED VG273U PRO 0000000000001
```

把 `name` 和 `description` 原样填进 profile。

## 4. 应用流程

`monitor_control.define()`：

1. 校验并存入 profile 表；
2. 对已存在的显示器立即匹配并应用。

第 2 步是必要的：`CConfigManager` 在配置解析结束后才调用
`ensureMonitorStatus()` / `ensureVRR()`。如果只在 `config.reloaded` 里
应用，规则会更新，但 `ensureVRR()` 已经用旧规则跑过了，VRR 会停在旧值。

`monitor_control` 自己注册以下事件：

- `hyprland.start` → `apply_all()`
- `monitor.added` → `apply_monitor(mon)`
- `config.reloaded` → `apply_all()`

每个显示器：

- 命中 profile：`apply()` 使用具体连接器名应用 profile；
- 没命中且 enabled：`apply_default()` 用 `desc:` 规则应用自动布局；
- 没命中且 disabled：跳过，避免把有意禁用的显示器重新打开。

`apply()` 会：

- 用 profile 字段构造 `hl.monitor()` spec；
- 用 `output = mon.name` 应用，确保规则落在当前实际连接器上；
- 对省略的 `position` / `scale` / `reserved` 填默认值；
- 安排一个 250 ms 的一次性重放，修复 `ensureVRR()` 早于规则生效的竞态。

`apply_default()` 是老 `apply_monitor_configs()` fallback 的唯一实现：
`desc:` 规则 + 自动 position/scale/reserved，不再由 `hyprland.lua` 维护。

## 5. 和现有自定义脚本怎么配合

### 自动 scale

自动 scale 的逻辑已经集中到：

```lua
monitor_control.apply_monitor(mon)
monitor_control.apply_default(mon)
monitor_control.default_layout(mon, spec)
monitor_control.effective_scale(mon, profile)
monitor_control.resolve(mon, profile)
```

规则：

- profile 显式写了 `scale`：用 profile 的；
- profile 没写：`default_layout()` 按 `mode` 里的分辨率套
  `>1080p -> 2x，否则 1x`；`highrr` / `highres` / `preferred` 会从
  `mon.available_modes` 推断目标高度（例如 1080p 面板切到 4K160 highrr
  时自动给 2x）；
- 没有 profile 的显示器：`apply_default()` 用同一个 `default_layout()`
  生成 `desc:` fallback。`hyprland.lua` 里不再有独立的 auto-scale pass。

自定义脚本想拿最终 scale：

```lua
local profile = monitor_control.match(mon)
if profile then
    local scale = monitor_control.effective_scale(mon, profile)
end
```

`monitor_control.status()` 返回每个 profile 的 `mode`/`key`，以及每台显示器
的 `matched`/`mode`/`key`/`scale`，适合临时接到日志或调试绑定里。

不要对已被 profile 管理的显示器直接 `hl.monitor({ output = mon.name,
scale = ... })`，否则会生成一条同名的后置规则，覆盖 profile 的 mode/VRR。

### 旋转/变换这类单字段修改

`hyprland.lua` 的 `toggle_orientation()` 已改成：

```lua
local profile = monitor_control.match(mon)
if profile then
    local spec = monitor_control.resolve(mon, profile)
    spec.transform = new_transform
    hl.monitor(spec)
else
    local layout = monitor_control.default_layout(mon)
    hl.monitor({
        output    = mon.name,
        position  = layout.position,
        scale     = layout.scale,
        reserved  = layout.reserved,
        transform = new_transform,
    })
end
```

`resolve()` 返回 profile 的完整具体 spec（含自动布局默认值），所以改
transform 不会丢掉 mode/scale/VRR。自定义脚本修改任何单字段时建议照这个
模式做。

### 其他脚本

- `assign_workspaces()` / `hypr/scripts/assign-workspaces`：仍然按
  **连接器名** 分 workspace，profile 不改变连接器名，所以不受影响。
  如果以后要让 workspace 范围也按双键稳定，可以在 profile 里加
  `workspace_base` 再改 `assign_workspaces()`。
- `hypr/scripts/dim` / `undim`：走 DRM connector + DDC/CI，和 profile
  无关。
- `hypr/scripts/after_sleep`：只做 DPMS on / hyprpaper 恢复，不写
  monitor 规则，无冲突。
- `wake_recovery()`：按连接器名和几何位置修复浮动窗口/焦点，不写
  monitor 规则，无冲突。
- `drm-ignore-dock.service`：按 GPU PCI id force-off iGPU 连接器，属于
  kernel/DRM 层，和 profile 的 Hyprland 规则层互不替代。双键 profile
  只是让“同一块屏、两条链路”可以分别配置；是否继续强制关 dock 链路是
  另一个独立策略。

## 6. 预期行为

| 场景 | 行为 |
|---|---|
| 启动时命中 dual | 使用 dual profile（最高优先级） |
| 启动时只命中 connector | 使用 connector profile |
| 启动时只命中 description | 使用 description profile |
| 同时命中多种 | dual > connector > description |
| 连接器和描述都对不上 | 不应用 profile，走旧 `desc:` 布局 fallback 或 Hyprland 默认规则 |
| 同一描述在不同连接器 | 两个显示器都能命中 description-only profile（如果没被更具体的规则覆盖） |
| 同一连接器换不同面板 | connector-only profile 仍会命中；dual/description-only 会按新描述重新匹配 |
| profile 写 `disabled = true` | 只禁用命中的那个组合；其他模式/链路不受影响 |
| 改 profile 后 reload | 规则重建并重新匹配，可能触发 modeset 闪烁和窗口重排 |
| VRR | 最终与 profile 的 `vrr` 一致；热插拔时 Lua 靠 250 ms 重放纠正 |
| workspace | 不变，仍按连接器名 |

## 7. 测试

`tests/run-tests.sh` 只跑纯 Lua 单测，不需要 Hyprland：

```text
ok: monitor_control
```

覆盖：

- 三种模式的匹配和优先级 dual > connector > description；
- 同一模式内后定义覆盖前定义；
- dual 规则不受后定义的 connector-only 影响；
- 描述-only 跨连接器匹配、连接器-only 忽略描述；
- 逗号归一化、FALLBACK；
- 显式字段透传、省略字段的自动布局；
- `highrr` / `highres` / `preferred` 从 `available_modes` 推断 4K/1080p
  scale；
- 无 profile 的 enabled 显示器走 `apply_default()` 的 `desc:` 规则，
  disabled 的跳过；
- `default_layout` / `resolve` / `effective_scale` / `apply_default`；
- 缺少双键、空 connector、非字符串 description、未知字段、
  `reserved` 与 `reserved_area` 同时出现时报错；
- 模块自己注册 `hyprland.start` / `monitor.added` / `config.reloaded`；
- `define()` 立即应用、`apply_all()` 包含 disabled 显示器；
- 单 profile 表和 profile 数组两种写法；
- `status` / `match_mode` / `is_managed`。

## 8. 已知限制

- Lua 事件表只有 `monitor.added`，没有 `monitor.preAdded`。同一连接器上
  换一块面板时，Hyprland 可能先按上一条同名规则做第一次 modeset，随后
  `monitor.added` 才纠正。会有一个短暂窗口。
- 250 ms 重放是 workaround，不是 Hyprland 正式接口。
- 匹配是精确匹配，没有通配符/前缀。连接器名漂移时需要补一条 profile。
- 自动 scale 对 `highrr` / `highres` / `preferred` 只是按
  `available_modes` 推断；自定义 modeline 或特殊驱动模式仍可能推断不准，
  这种场景建议显式写 `scale`。
- workspace 范围仍按连接器名，不随 profile 的双键稳定。
- 只解决 Hyprland monitor 规则；不改变 kernel/DRM/DDC 层行为。

## 9. 后续可做

- profile 增加 `workspace_base`，让 workspace 范围也按连接器+描述稳定。
- 支持连接器通配符或显式 `priority`，用于连接器漂移但描述仍可唯一识别
  的场景。
- 如果上游以后支持 `name+desc` 组合 selector，可以把这套逻辑下推到
  monitor/workspace/layer 所有规则类型。
