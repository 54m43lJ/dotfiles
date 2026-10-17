- [ ] dpms off => on 后 float 窗口会跑到屏幕外面去
  - [ ] 而且必须要切换workspace才能正常输入/互动当前窗口
  - 根因(2026-10-17 调查): Hyprland <=v0.56.2 的 FALLBACK 占位输出状态机缺陷。dpms off 在 0.56
    是完整 disable output+DRM commit, VG273U PRO 深睡拉掉 HPD → DP-2 remove → FALLBACK → on 时
    re-add。恢复时 workspace orphan 状态损坏: float 按 stale monitor 位置平移出屏
    (WorkspacePlacementController::moveWorkspaceToMonitor 的 translate/modulo 分支); 单屏断开时
    focus window/surface/monitor 全被 onDisconnect 清空, 重连路径不补 window focus → 键盘假死,
    切 workspace 强制 focusWindow 才恢复。上游同族: #15800(crash 版), 修复 #15890 已进 main
    (2026-08-24) 但晚于 v0.56.2, 无 release 包含。
  - [x] 配置层 workaround: hyprland.lua `wake_recovery()` — monitor.added 后重试梯子(3s 起
        每 5s 一轮共 8 轮): 拉回屏外 float + 对活动窗口重发 focus 修复 seat 键盘焦点滞留
        (focus 对象在但 seat surface 陈旧 → 键盘假死; FocusState.cpp:155 的短路条件保证
        健康时为 no-op; hyprlock 持锁的轮次跳过重试)。2026-10-17 实测解锁后键盘立即可用;
        熄屏前光标不在输入框的场景未专门测, 日常使用覆盖
  - [ ] 等包含 #15890 的 release(≥0.56.3)发布: 升级 → 人工踩一次 dpms 循环验证 → 移除
        wake_recovery 和 hl.config{debug=...} 两段, 再勾掉本条
- [ ] suspend之后回来会黑屏
  - 根因(2026-10-17 取证, 日志回溯至 9/5 共 77 boots): 三层叠加
    L1 内核: RX 9070 XT (Navi48/DCN4.0.1/SMU 104.80.0) 每次 suspend 进入阶段失败并触发
      amdgpu MODE1 reset(整卡重置, 显示管线被拆) — 38 suspend↔38 MODE1 一一对应, 零运行时
      reset; 跨内核 7.2.3→7.2.6→7.2.9 + 固件 20260810→20260916 均复现 → 上游 amdgpu Navi4x
      S3 问题, 无前置错误日志(SMU 挂起失败的静默恢复路径)
    L2 面板: VG273U PRO 信号消失即深睡拉 HPD(同 TODO#1 已证), suspend 前 dpms 已关 300s,
      面板早已深睡、DP-2 早已移除、Hyprland 早已在 FALLBACK 状态
    L3 compositor: 唤醒后 DP-2 走 remove→FALLBACK→re-add 同一条坏路径(TODO#1 的 #15890
      家族), 叠加 mode1 reset 后内核显示状态重建, 恢复失败时 session 渲染到 headless
      FALLBACK → 系统活着、屏幕黑(所以能盲打重启)
  - 行为证据: 唤醒后数分钟内重启的 boot: -73(4min)/-52(3.6min)/-11(49s, 且该次 suspend 被
    "Wakeup pending" 打断没睡进去)/-10(2min, 唤醒 08:27→关机 08:29→08:31 你注释掉 suspend),
    之后现象绝迹; 9 月多数周期存活 ≥30min(显示有时能自己回来, 疑似 link retrain 竞态)
  - 复发判别法: 黑屏时 SSH/盲切 TTY → cat /sys/class/drm/card1-DP-2/status: disconnected=
    L1/L2(内核/面板), connected= L3(compositor); hyprctl monitors 只有 FALLBACK= L3
  - 修的方向(不急): 内核升级跟 Navi4x S3 修复; 或 suspend 前主动 dpms off 回 DPMS 而非 S3;
    L3 部分随 TODO#1 的 #15890 升级一并解决
- [ ] 让 Hyprland 能够处理窗口 minimize 事件
  - 2026-10-17 调查: 0.56.2 三条路径两条死路(xdg set_minimized / XWayland WM_CHANGE_STATE
    的 requestsMinimize 被丢弃, onUpdateState 只处理 fs/maximize); zwlr_foreign_toplevel 的
    set_minimized 只广播 socket2 事件不执行。main 已合 #16071(2026-09-01): Lua 原生事件
    hl.on("window.minimize", w, state) — 等下个 release 后在 Lua 里做 special-workspace 式
    最小化; 应用自带最小化按钮的路径上游仍未实现
- [x] ~~用Vicinae做launcher~~ 2026-10-17 确认完整集成: MODULES 含 vicinae(module.sh 装
      vicinae-bin + 部署 power-menu.sh); hyprland.lua 有 server 自启/SUPER+SPACE toggle/
      layer blur+no-anim 规则/SUPER+Q 电源菜单; vicinae-server 运行中, dmenu 依赖的
      /usr/local/bin/suspend.sh 由 system 模块提供
- [x] ~~滚轮切换workspace方向需要反过来~~ 2026-10-17: 垂直方向已由 d13e528 修正(下滚=next);
      倾斜滚轮 mouse_left/right 已补绑(m-1/m+1)。注意鼠标需发 REL_HWHEEL(倾斜时应用里能
      横向滚动即满足); 若鼠标倾斜发的是按键码则要改绑 mouse:8/9
- [ ] Vicinae需要重做样式
- [ ] Vicinae的电源菜单太丑了
- [ ] PC上hypridle不设置suspend