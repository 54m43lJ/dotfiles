# 登录界面数值规范（SDDM + hyprlock）

本文是 SDDM `sugar-dark` greeter 和 hyprlock 的**唯一数值来源**。这里只定义一套
共享数值和标准单位；两个组件各自把这些值换算成自己的配置文件。

## 1. 标准单位

- **画布**：1920×1080 设计画布。
- **几何位置/尺寸**：百分比（`%`），相对画布宽/高。组件直接把它当作相对实际输出
  逻辑尺寸的锚点。
- **字号**：`pt`，指 1080p 画布下的目标字号。
- **细节尺寸**：`U`，指 1080p 画布下的逻辑像素（描边、圆角、图标框等）。
- 除特别注明外，本文不写某个组件的实际配置值；组件自行取整和换算。

通用缩放规则（逻辑单位）：

```text
logicalScale = output_logical_height / 1080
pt           -> pt * logicalScale
U            -> U * logicalScale
```

百分比本身已经是相对的，不乘 `logicalScale`。高宽比变化时，x 方向百分比相对宽度、
y 方向百分比相对高度。hyprlock 的配置使用 surface 像素，换算时改用
`surfaceScale = output_physical_height / 1080 = logicalScale * monitorScale`。

## 2. 设计令牌

颜色统一取 `palette/README.md` 的 **dark** mode；SDDM 侧同时落在
`theme.conf` 的 `[Palette]` 段。登录界面不再维护独立颜色。
`palette/README.md` 是只读参考；登录界面的 token 使用方式记录在本文和
`sddm/sugar-dark/README.md`。

| 令牌 | 值 |
| --- | --- |
| 调色板 | `palette/README.md` dark mode |
| 背景图 | `~/.config/hypr/graduation_dark.jpg`（SDDM 侧为同图的 `graduation2.jpg`） |
| 面板底色 | `surface #3E3542`，alpha `0.6` |
| 主文字 | `fg #D6CAB6` |
| 边框/图标/次要文字 | `muted #B0B4BC` |
| 强调文字/选中填充 | `purple-light #E593E7` |
| 边框/焦点描边 | `purple #89338E` |
| 高亮文字/装饰亮线 | `cream #FFF7E4` |
| 弹层阴影 | `gold #9D7E4D`，alpha `0.55` |

普通文字统一 `fg`；日期、`Session:` 标签和 Caps Lock 提示用 `muted`，时间用 `cream`，
强调文字和选中项填充用 `purple-light`；边框/焦点描边用 `purple`。错误用 `red`。
`gold` 只用于弹层阴影，不再作为文字颜色。
hyprlock 密码框边框与用户名框共用 `muted`；`purple` 用于 SDDM 的焦点描边。
| 错误/危险 | `red #CC2A47` |
| 字体 | `Noto Sans` |
| 图标字体 | `Noto Sans Nerd Font`，用户图标 `U+F007` |
| 胶囊 | 完整圆头；半径 = 高度的一半 |

## 3. 共享布局数值

坐标为中心点（除非写“左缘”），单位见上。画布 1920×1080。

| 元素 | 锚点 | 位置 | 尺寸 | 字号 | 细节 |
| --- | --- | --- | --- | --- | --- |
| 背景 | 全屏 | — | 100% × 100% | — | 等比裁切填满 |
| 右侧面板 | 右缘 | x 60%–100%，y 0–100% | 40% × 100% | — | `surface` 60%，无圆角 |
| 时间 | 面板中心 | (80%, 18.1%) | — | 38pt | `HH:mm`，24 小时制；`cream` |
| 日期 | 面板中心 | (80%, 22.1%) | — | 13pt | `dddd, d of MMMM`；`muted` |
| 用户框 | 面板中心 | (80%, 46.4%) | 20% × 3.7% | — | 下拉框胶囊；`muted` 描边 1U；无箭头；内部文本框透明无边框 |
| 用户图标 | 用户框左侧 | (72%, 46.4%) | 16U × 16U | — | `muted`，激活时 `purple-light` |
| 用户名 | 面板中心 | (80%, 46.4%) | — | 13pt | `fg`，聚焦时 `purple-light` |
| 密码框 | 面板中心 | (80%, 51.8%) | 20% × 3.7% | — | `purple` 描边 2U，胶囊，透明底；聚焦文字 `purple-light` |
| 提交箭头 | 密码框右端 | (89%, 51.8%) | 约 23U × 12U | 19.5pt | `→`，`fg`；点击提交 |
| 会话标签 | 面板左下 | 中心 y 96.5%；值胶囊左缘 70% | — | 11.5pt | `muted` 静态 `Session:` 标签在胶囊左侧；值胶囊内只显示值；无箭头 |

界面上没有独立的 Login 按钮，也没有 Welcome 标题。

描边粗细（字段、按钮、面板边框，除非另注）：

- 未聚焦：1U
- 聚焦：2U
- 没有焦点态：1U

由此 SDDM 用户框未聚焦 1U、聚焦 2U；密码框聚焦 2U。hyprlock 所有边框统一 1U
（`$border = 2` @4K@2x）。复选框 focus underline 等纯指示线不适用本条。

## 4. 组件推导指导

这里只讲换算方法，不重复上面的数值。

### SDDM

- 百分比直接用于锚点和宽高比例；面板右缘对齐屏幕右缘。
- 基础正文 13pt 是参照值，实际字号按根高度取整：
  `base = max(1, trunc(root.height / 80))`。
- `U` 细节按 `root.height / 1080` 缩放；圆角再按 `height / 2` 夹紧成胶囊。
- 垂直位置由表单的 `ColumnLayout` 槽高和内容高度推导；上表的中心点是目标值，
  实现时用槽高和间距逼近它。
- 输入框、箭头、图标等组件内部字号/尺寸都由上表的 `pt`/`U` 推导，不在本文另列。

### hyprlock

- hyprlock 的 `position` 是相对中心的偏移，且 **y 正方向向上**：
  ```text
  position_x = center_x - 50%
  position_y = 50% - center_y
  ```
- `size` 直接使用上表的百分比。
- `font_size` 和 `U` 细节使用 surface 像素，按 `surfaceScale` 换算：4K@2x 下为 2，
  1080p@1x 下为 1。
- 胶囊用 `rounding = -1`；描边/边框按 `U * surfaceScale` 推导。
- 图标是字体字形，选一个字号让字形视觉高度接近 16U 即可。
- 用户名框和密码框共用 `muted` 和同一个 `$border = 2`（1U @4K@2x）；hyprlock 所有
  边框统一 1U。文字/dots 用 `purple-light`，check 指示保持 `purple-light`。不使用
  `fade_on_empty`。

## 5. 交互样式（仅 SDDM）

hyprlock 没有悬停状态、按钮或下拉框，以下规则只适用于 greeter。

| 项目 | 规则 |
| --- | --- |
| 悬停高亮 | 半透明 `purple-light` 填充，内缩 2–4U，默认 150ms `OutCubic` 淡入；高亮行文字用 `purple-light`；不使用渐变 |
| 入口与菜单 | 入口和菜单共用同一个面板、边框和底色；入口是面板在触发边的一行，不再有独立边框或间距 |
| 下拉展开 | 只动画菜单部分的高度 0→内容高度，入口行保持原位；内容同时沿展开方向滑入 16U；不做纵向缩放；展开 200ms，收起 140ms |
| 展开方向 | 向下展开时固定面板上缘向下长；向上展开时固定面板下缘向上长，y 绑定到动画高度 |
| 菜单尺寸 | 宽度 = 入口宽度；面板高度 = 入口高度 + 选项数 × 入口高度；选项行高 = 入口高度 |
| 选项留白 | 弹层 padding 为 0，选项填充到边框内侧 1U |
| 实现 | `Components/HoverFill.qml`、`Components/ThemedDropdown.qml` |

下拉菜单不使用 `Popup`。`Popup.y` 是 positioner 调整后的 effective position，而向上展开需要先知道
内容高度；内容在弹层显示前又不会被 polish，因此 `aboutToShow` 时量到 0，靠额外重置/测量才能
对齐，且修正一个方向会破坏另一个方向。`ThemedDropdown` 是普通 `Item`，面板高度 =
`triggerHeight + revealHeight`，只让 `revealHeight` 做动画：向下时面板上缘固定在入口顶部，向上时
`y = trigger.y + trigger.height - height`，所以入口和菜单始终是同一个几何体。

`ThemedDropdown` 不内置主题颜色，所有颜色通过属性注入：
`fillColor`（surface）、`borderColor`（purple）、`textColor`（fg）、`highlightedTextColor`（purple-light）、
`highlightColor`（purple-light）、`shadowColor`（gold alpha）。
SDDM 从 `theme.conf` 的 `[Palette]` 段取值，hyprlock 使用同一组 dark token。

按钮、下拉触发器和菜单项共用同一套悬停高亮；用户名/会话下拉共用同一个可展开面板。
用户名入口的触发范围覆盖整个胶囊，中央由 `TextField` 覆盖：中间用于编辑，图标和两侧留白用于展开；
会话入口整块都是触发。

## 6. 实现入口

- SDDM：`sddm/sugar-dark/theme.conf` 暴露换算后的比例/系数和 `[Palette]` 颜色 token，
  `Main.qml`、`Components/*.qml` 消费它们。
- hyprlock：`hypr/hyprlock.conf` 顶部的命名变量；颜色使用同一组 dark token。
- 两边都从本文推导；改数值时先改本文，再按上面的换算更新各自的实现。

## 7. 测试

```bash
# SDDM：直接跑，HiDPI 下清晰；嵌套 cage 会因缩放发糊
sddm-greeter-qt6 --test-mode --theme ~/Documents/dotfiles/sddm/sugar-dark

# hyprlock
hyprlock --no-fade-in
# 解锁：kill -USR1 "$(pidof hyprlock)"
```

## 8. 已知限制

- SDDM 的纵向位置由 `ColumnLayout` 推导，不是每个元素独立的绝对 y 坐标；本文给出
  的是目标中心点。若要求逐元素绝对定位，需要把 `LoginForm.qml` 改成显式定位。
- 两个组件没有共享的机器可读配置文件；本文是人工维护的单一来源。若以后需要自动
  生成两边配置，可以再加一层从本文表格到配置的生成脚本。
