# Palette

全项目统一调色板（SDDM 主题优先使用者，后续 ags/eww/wofi/hypr 等可迁移至此）。
Light 以 [Alabaster](https://github.com/tonsky/sublime-scheme-alabaster) 为基底（`bg`/`fg` 与 `foot/foot.ini` 的 `[colors-light]` 一致），accent 融入紫金取向；Dark 由项目既有「奶油紫」深色体系合并、风格化而来。

两个 mode 的 token 名一一对应，主题按 mode 切换即可。

## Tokens

### Dark

| Token | Hex | 语义 / 用途 | 对比度备注 |
|---|---|---|---|
| `bg` | `#231F1F` | 主背景、窗口边框、选中底 | — |
| `surface` | `#3E3542` | 次级浮层：通知底、弹窗、输入框底 | — |
| `fg` | `#D6CAB6` | 正文文字、slider 轨道 | on bg 10.1:1 ✓ |
| `muted` | `#B0B4BC` | 中性边框、图标（dunst frame、电池图标） | 有意保留冷灰，与暖米正文区分 |
| `purple` | `#89338E` | accent：hover/选中填充（配 cream 字）；亮底（cream/white 面）上的文字 | 填充↔bg 2.3:1（仅填充用）；文字↔cream 底 7.2:1 ✓ |
| `purple-light` | `#E593E7` | accent 提亮：深浮层上的文字、hover 高亮 | on surface 5.4:1 ✓，on bg 7.5:1 ✓ |
| `gold` | `#9D7E4D` | accent：细线（栏底边）、进度填充、副标题弱文字、窗口阴影 | on bg 4.3:1（弱文字 OK，正文勉强） |
| `cream` | `#FFF7E4` | 最亮色：亮面背景（弹窗、wofi 面板）+ 选中/hover 文字 + 装饰亮线 | on bg 15.3:1 ✓ |
| `red` | `#CC2A47` | 警告/危险：低电量、关闭按钮 hover、错误填充 | on bg 3.1:1（警告文字/图标可用，正文不足）；cream 字压其上 4.9:1 ✓（红填充+cream 字为推荐用法） |

### Light

| Token | Hex | 语义 / 用途 | 对比度备注 |
|---|---|---|---|
| `bg` | `#F7F7F7` | 主背景（Alabaster background） | — |
| `surface` | `#F2F0EF` | 次级浮层：弹窗、输入框底（off-white，微暖） | — |
| `fg` | `#000000` | 正文文字（Alabaster foreground） | on bg 19.6:1 ✓ |
| `muted` | `#7A7472` | 次要文字、边框（暖灰，微偏金，平衡紫金占比） | on bg 4.3:1 ✓ |
| `purple` | `#8A2E8F` | accent 主紫（与 dark 同族 297°） | on bg 6.8:1 ✓ |
| `purple-light` | `#D998D9` | 柔和填充：hover/选中底，需配深色文字 | 深字压其上 9.4:1 ✓；色块↔bg 2.1:1（较隐身） |
| `gold` | `#5C4824` | accent 金：细线、进度填充、副标题文字 | on bg 8.1:1 ✓ 全用途 |
| `highlight` | `#E9DBF2` | 选中态高亮底（对应 dark 的 `cream` 角色） | 配 `fg` 文字 15.9:1 ✓ |
| `red` | `#AB3248` | 错误/危险（347° 樱桃红，与 dark 同族） | on bg 6.0:1 ✓ |

## 迁移提示

Dark：

- `purple` 在深底上做文字只有 2.3:1 —— 深底上的强调文字用 `purple-light` 或 `cream`。
- `red` 偏暗，文字用途限警告级别的大字/图标；正文级错误提示建议「红填充 + cream 字」。
- `muted` 是 dark 侧唯一冷灰，专用于边框/图标，勿用作正文。

Light：

- `purple-light` 是粉彩填充色，其上内容一律用 `fg` / `purple` 等深色（黑字 9.4:1）。
- `gold` 深度足够，可全用途（正文 / 细线 / 填充）。

跨 mode：同名 token 色相同族（purple 297°、purple-light ~300°、red 347°、gold ~37–39°），切换 mode 时视觉语言一致。
