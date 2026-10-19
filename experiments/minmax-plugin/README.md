# minmax-plugin feasibility probe

目标是验证：**Hyprland 插件能否在进程内看到应用发出的 minimize/maximize 请求，并把
minimize 请求转成 special-workspace 动作**。

这是可行性验证，不是最终产品。插件目前只记录请求，不真正移动窗口；移动动作单独用
`hyprctl` 验证，以免在 `onUpdateState` 回调里递归触发状态更新。

## 结论（先看这里）

| 环节 | 结果 | 说明 |
|---|---|---|
| 插件编译、加载、卸载 | ✅ 已验证 | 使用发行版安装的 `/usr/include/hyprland` 头文件 |
| `window.open` EventBus | ✅ 已验证 | 插件能收到新窗口事件 |
| `window.fullscreen` EventBus | ✅ 已验证 | maximize 走 fullscreen 事件，可观察 |
| `CWindow::onUpdateState` hook | ✅ 已验证 | 通过 `findFunctionsByName` 找到并 hook |
| 应用 `xdg_toplevel.set_minimized` | ✅ 已验证 | hook 能看到 `requestsMinimize` |
| 应用 `xdg_toplevel.set_maximized` | ✅ 已验证 | hook 能看到 `requestsMaximize`，Hyprland 原生处理 |
| special workspace 移动/恢复 | ✅ 已验证 | 用 `hyprctl` 动作链验证 |
| 在 hook 内直接移动窗口 | ⏭ 跳过 | 需要处理重入/焦点/原 workspace 记忆，原型不冒险 |
| 应用自带 minimize 按钮最终行为 | ⏭ 跳过 | Hyprland 仍会忽略请求；插件只证明能拦截 |

## 为什么值得走插件

0.56.2 的 `CWindow::onUpdateState()` 只消费 `requestsFullscreen` 和
`requestsMaximize`；`requestsMinimize` 在 `XDGShell` / XWayland 中虽然被记录，
但没有被处理，也没有 IPC 事件。外部守护进程看不到它。

插件在 Hyprland 进程内 hook `CWindow::onUpdateState()`，因此可以：

1. 读到 `requestsMinimize` / `requestsMaximize`；
2. 对 minimize 执行自定义逻辑（例如移入 `special:minimized`）；
3. 对 maximize 只观察，交给原生 fullscreen/maximize 逻辑。

## 方案

```text
app (Wayland/X11)
      │  xdg_toplevel.set_minimized / set_maximized
      ▼
Hyprland  CWindow::onUpdateState
      │  plugin hook
      ├─ requestsMinimize  -> 记录（未来：moveToWorkspace(special:minimized)）
      └─ requestsMaximize  -> 记录，原逻辑继续处理
```

后续真正实现 minimize 时需要：

- 记录每个 window 的原 workspace（插件内维护 `address -> workspace id`）；
- 在 `onUpdateState` 里不要在状态回调中直接重入移动；用
  `Config::Actions::moveToWorkspace()` 或事件循环延迟执行；
- 恢复时移回原 workspace，并清掉标记；
- 处理窗口关闭、跨 workspace 移动、special workspace 自身等边界。

落地步骤建议：

1. `window.open` / `onUpdateState` 时记录 `address -> workspace id`；
2. 看到 `requestsMinimize == true` 后，用 `CEventLoopTimer` 延迟到当前
   state 处理结束，再调用 `Config::Actions::moveToWorkspace(special, true, window)`；
3. `special:minimized` 不存在时创建，存在时复用；
4. 增加 `minmax:restore` dispatcher（或 Lua 函数）：把窗口移回原
   workspace、`fullWindowFocus`，并从 map 删除；关闭窗口时清理 map。
5. Wayland 的 xdg-shell 没有 unminimize 请求，恢复只能由 keybind、bar
   或 tray 触发；这是协议层限制，不是插件能补的。

## 测试链

`tests/run-tests.sh` 会：

1. 编译插件和 Wayland probe；
2. 加载插件，确认 `hyprctl plugin list` 和 init 日志；
3. 启动 probe 窗口，确认 `window.open` 事件；
4. 让 probe 调用 `xdg_toplevel_set_minimized`，确认 hook 记录；
5. 让 probe 调用 `xdg_toplevel_set_maximized`，确认 hook 记录且
   `hyprctl clients` 的 `fullscreenClient == 1`；
6. 用 `hyprctl` 把 probe 移入/移出 `special:minimized`，确认动作链；
7. 卸载插件，确认 exit 日志且插件列表为空。

结果写入 `results/`。

## 本次实测结果（2026-10-19）

`results/summary.txt`：**PASS=11 FAIL=0 SKIP=0**。

关键链路：

- `PLUGIN_INIT`：server/client hash 一致，API `0.1`
- `FIND onUpdateState matches=1`
- `HOOK onUpdateState install=ok`
- `EVENT window.open class=minmax-probe`
- `MINIMIZE_REQUEST class=minmax-probe ... value=1`
  - 窗口仍留在原 workspace，证明 0.56.2 确实忽略了应用 minimize 请求
- `MAXIMIZE_REQUEST class=minmax-probe ... value=1`
  - `hyprctl clients`：`fullscreen=1`、`fullscreenClient=1`
  - `EVENT window.fullscreen ... internal=1 client=1`
- special workspace：workspace `3` → `special:minimized`（id `-98`）→ `3`
- `PLUGIN_EXIT`，插件列表恢复为空

未测/跳过的部分：

- 在 hook 内真正移动窗口（需要事件循环延迟和重入处理）
- 应用自带 minimize 按钮的最终可见行为（当前插件只证明能拦截）
- XWayland 的实际 minimize 请求（代码路径已覆盖，未造 X11 probe）
- 下一个 Hyprland release 的 `window.minimize` 事件（0.56.2 没有）


## 风险

- 插件 ABI 与 Hyprland 版本强绑定；升级 Hyprland 后必须重编，最好用
  `__hyprland_api_get_hash()` 做版本检查（插件已做）。
- `onUpdateState` 是内部方法，升级后可能改名/内联。
- 在状态回调里移动窗口可能重入；原型刻意只记录。
- XWayland 和 Wayland 的请求路径不同，最终实现要分别处理。
- 插件崩溃会带崩整个 compositor，测试脚本应始终在 trap 中卸载插件。
