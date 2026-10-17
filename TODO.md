- [ ] dpms off => on 后 float 窗口会跑到屏幕外面去
  - [ ] 而且必须要切换workspace才能正常输入/互动当前窗口
  - 根因(2026-10-17 调查): Hyprland <=v0.56.2 的 FALLBACK 占位输出状态机缺陷。dpms off 在 0.56
    是完整 disable output+DRM commit, VG273U PRO 深睡拉掉 HPD → DP-2 remove → FALLBACK → on 时
    re-add。恢复时 workspace orphan 状态损坏: float 按 stale monitor 位置平移出屏
    (WorkspacePlacementController::moveWorkspaceToMonitor 的 translate/modulo 分支); 单屏断开时
    focus window/surface/monitor 全被 onDisconnect 清空, 重连路径不补 window focus → 键盘假死,
    切 workspace 强制 focusWindow 才恢复。上游同族: #15800(crash 版), 修复 #15890 已进 main
    (2026-08-24) 但晚于 v0.56.2, 无 release 包含。
  - [x] 配置层 workaround: hyprland.lua `wake_recovery()`(monitor.added 后 3s 拉回屏外 float+
        补 focus, hyprlock 持锁时跳过); debug 文件日志保持开启(TODO 其余条目排查也要用)
  - [ ] 等包含 #15890 的 release(≥0.56.3)发布: 升级 → 人工踩一次 dpms 循环验证 → 移除
        wake_recovery 和 hl.config{debug=...} 两段, 再勾掉本条
- [ ] suspend之后回来会黑屏
- [ ] 让 Hyprland 能够处理窗口 minimize 事件
- [ ] 滚轮切换workspace方向需要反过来
- [ ] 用Vicinae做launcher
- [ ] Vicinae需要重做样式
- [ ] Vicinae的电源菜单太丑了
- [ ] PC上hypridle不设置suspend