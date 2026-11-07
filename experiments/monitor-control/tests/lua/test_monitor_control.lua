-- Standalone tests for hypr/monitor_control.lua.  Run with:
--   lua5.4 experiments/monitor-control/tests/lua/test_monitor_control.lua .
--
-- The engine is pure Lua; a tiny hl stub captures hl.monitor() calls and
-- feeds synthetic monitor objects so matching/layout behaviour can be tested
-- without a compositor.

local ROOT = arg[1] or "."
package.path = ROOT .. "/hypr/?.lua;" .. package.path

local function fail(message)
    io.stderr:write("FAIL: " .. message .. "\n")
    os.exit(1)
end

local function check(condition, message)
    if not condition then
        fail(message)
    end
end

local monitors = {}
local calls     = {}
local timers    = {}
local events    = {}

hl = {
    on = function(name, callback)
        events[name] = callback
    end,
    get_monitors = function(options)
        if options and options.all then
            return monitors
        end
        local active = {}
        for _, mon in ipairs(monitors) do
            if mon.enabled ~= false then
                active[#active + 1] = mon
            end
        end
        return active
    end,
    monitor = function(spec)
        calls[#calls + 1] = spec
    end,
    timer = function(callback, options)
        check(options and options.type == "oneshot", "retry must be a one-shot timer")
        timers[#timers + 1] = callback
        return { set_enabled = function() end }
    end,
    get_monitor = function(name)
        for _, mon in ipairs(monitors) do
            if mon.name == name then
                return mon
            end
        end
        return nil
    end,
}

local monitor_control = require("monitor_control")

check(type(events["hyprland.start"]) == "function", "module must register hyprland.start")
check(type(events["monitor.added"]) == "function", "module must register monitor.added")
check(type(events["config.reloaded"]) == "function", "module must register config.reloaded")

local HKC   = "HKC OVERSEAS LIMITED VG273U PRO 0000000000001"
local SHARED = "SHARED DESCRIPTION 0001"

-- 1. three match modes + priority: dual > connector > description
monitor_control.define({
    {
        connector   = "DP-2",
        description = HKC,
        mode        = "highrr",
        position    = "auto",
        scale       = 2,
        reserved    = { top = -5 },
        vrr         = 1,
    },
    {
        connector   = "HDMI-A-1",
        mode        = "1920x1080@120",
        position    = "auto",
        scale       = 1,
        reserved    = { top = -5 },
        vrr         = 1,
    },
    {
        description = HKC,
        mode        = "1920x1080@60",
    },
    {
        connector   = "DP-3",
        mode        = "2560x1440@60",
    },
    {
        description = SHARED,
        mode        = "1280x720@60",
    },
})

local app = monitor_control.match({ name = "DP-2", description = HKC })
check(app ~= nil and app.mode == "highrr", "DP-2 + HKC must use the dual profile")

local _, mode = monitor_control.match({ name = "DP-2", description = HKC })
check(mode == "dual", "dual profile must win over description-only")

_, mode = monitor_control.match({ name = "HDMI-A-1", description = HKC })
check(mode == "connector", "connector-only must win over description-only")

local hdmi = monitor_control.match({ name = "HDMI-A-1", description = HKC })
check(hdmi.mode == "1920x1080@120", "connector-only profile applied")

_, mode = monitor_control.match({ name = "DP-9", description = HKC })
check(mode == "description", "description-only must match on another connector")

_, mode = monitor_control.match({ name = "DP-3", description = SHARED })
check(mode == "connector", "connector-only must win over description-only on DP-3")

check(monitor_control.match({ name = "DP-2", description = "OTHER PANEL" }) == nil,
    "dual profile must not match a different description")
check(monitor_control.match({ name = "FALLBACK", description = HKC }) == nil, "FALLBACK must never match")

-- 2. Hyprland strips commas from EDID descriptions before exposing them
_, mode = monitor_control.match({ name = "DP-2", description = "HKC, OVERSEAS LIMITED VG273U PRO 0000000000001" })
check(mode == "dual", "comma normalization must match Hyprland's stripped description")

-- 3. connector-only matches any description; description-only matches any
--    connector
local connOnly = monitor_control.match({ name = "HDMI-A-1", description = "SOMETHING ELSE" })
check(connOnly ~= nil and connOnly.mode == "1920x1080@120", "connector-only must ignore description")

local descOnly = monitor_control.match({ name = "eDP-9", description = SHARED })
check(descOnly ~= nil and descOnly.mode == "1280x720@60", "description-only must ignore connector")

-- 4. apply()/resolve() use the concrete connector and pass profile fields
calls = {}
local dp2 = { name = "DP-2", description = HKC, height = 2160, enabled = true }
local profile = monitor_control.match(dp2)
check(monitor_control.apply(dp2, profile), "apply should succeed")
local spec = calls[#calls]
check(spec.output == "DP-2", "output must be the concrete connector")
check(spec.mode == "highrr", "mode must pass through")
check(spec.scale == 2, "explicit scale must pass through")
check(spec.vrr == 1, "vrr must pass through")
check(spec.connector == nil and spec.description == nil, "metadata must not leak into hl.monitor")

local resolved = monitor_control.resolve(dp2, profile)
check(resolved.output == "DP-2" and resolved.scale == 2, "resolve must return the concrete spec")
check(monitor_control.effective_scale(dp2, profile) == 2, "effective_scale")

-- 5. omitted layout fields get the shared legacy defaults
monitor_control.define({
    connector   = "eDP-1",
    description = "Laptop panel",
    mode        = "2560x1600@120",
})
local laptop = { name = "eDP-1", description = "Laptop panel", height = 1600, enabled = true }
local laptopSpec = monitor_control.resolve(laptop, monitor_control.match(laptop))
check(laptopSpec.position == "auto-right", "default position")
check(laptopSpec.scale == 2, "4K-ish literal mode should default to 2x")
check(type(laptopSpec.reserved) == "table" and laptopSpec.reserved.top == -5, "default reserved")

monitor_control.define({
    connector   = "eDP-2",
    description = "1080p panel",
    mode        = "1920x1080@60",
})
local small = { name = "eDP-2", description = "1080p panel", height = 1080, enabled = true }
check(monitor_control.resolve(small, monitor_control.match(small)).scale == 1, "1080p literal mode should default to 1x")

-- default_layout() is the shared source of truth for custom scripts
local layout = monitor_control.default_layout({ height = 2160 }, { mode = "3840x2160@60" })
check(layout.scale == 2 and layout.position == "auto-right" and layout.reserved.top == -5,
    "default_layout must expose the auto-scale heuristic")

-- highrr/highres should infer the height from available_modes, not from the
-- current 1080p mode
local hybrid = {
    height = 1080,
    available_modes = {
        { width = 1920, height = 1080, refresh_rate = 120 },
        { width = 3840, height = 2160, refresh_rate = 160 },
        { width = 3840, height = 2160, refresh_rate = 60, preferred = true },
    },
}
check(monitor_control.default_scale(hybrid, { mode = "highrr" }) == 2, "highrr must infer 4K height")
check(monitor_control.default_scale(hybrid, { mode = "highres" }) == 2, "highres must infer 4K height")
check(monitor_control.default_scale(hybrid, { mode = "preferred" }) == 2, "preferred must use the preferred mode height")

local dock = {
    height = 1080,
    available_modes = {
        { width = 1920, height = 1080, refresh_rate = 120 },
        { width = 3840, height = 2160, refresh_rate = 60 },
    },
}
check(monitor_control.default_scale(dock, { mode = "highrr" }) == 1,
    "highrr on a 1080p120/4K60 mode set must stay 1x")

-- 6. unknown/invalid profiles are rejected
local ok, err = pcall(function()
    monitor_control.define({ mode = "highrr" })
end)
check(not ok and tostring(err):find("at least one of connector/description", 1, true) ~= nil, "missing keys must be rejected")

ok, err = pcall(function()
    monitor_control.define({ connector = "", description = HKC })
end)
check(not ok and tostring(err):find("connector must be a non-empty string", 1, true) ~= nil, "empty connector must be rejected")

ok, err = pcall(function()
    monitor_control.define({ connector = "DP-2", description = 42 })
end)
check(not ok and tostring(err):find("description must be a string", 1, true) ~= nil, "non-string description must be rejected")

ok, err = pcall(function()
    monitor_control.define({ connector = "DP-2", description = HKC, modes = "typo" })
end)
check(not ok and tostring(err):find("unknown field", 1, true) ~= nil, "unknown profile field must be rejected")

ok, err = pcall(function()
    monitor_control.define({ connector = "DP-2", reserved = 1, reserved_area = 2 })
end)
check(not ok and tostring(err):find("not both", 1, true) ~= nil, "reserved/reserved_area must be exclusive")

-- 7. duplicate keys: last definition wins within the same mode; a dual
--    profile still wins over a newer connector-only profile
monitor_control.define({
    connector   = "DP-4",
    mode        = "1920x1080@60",
})
monitor_control.define({
    connector   = "DP-4",
    mode        = "2560x1440@120",
})
check(monitor_control.match({ name = "DP-4", description = "whatever" }).mode == "2560x1440@120",
    "last definition must win within the same mode")

monitor_control.define({
    connector   = "DP-6",
    mode        = "connector profile",
})
monitor_control.define({
    connector   = "DP-6",
    description = HKC,
    mode        = "dual profile",
})
check(monitor_control.match({ name = "DP-6", description = HKC }).mode == "dual profile",
    "dual profile must beat connector-only regardless of definition order")

monitor_control.define({
    connector   = "DP-7",
    description = HKC,
    mode        = "dual profile",
})
monitor_control.define({
    connector   = "DP-7",
    mode        = "connector profile",
})
check(monitor_control.match({ name = "DP-7", description = HKC }).mode == "dual profile",
    "dual profile must still beat a later connector-only profile")

-- 8. define() applies immediately in the Lua backend: profile rules plus
--    the auto-layout fallback for unmanaged monitors.  This is what makes a
--    rule created during config parsing visible to CConfigManager's
--    ensureVRR() pass at the end of the same reload.
monitors = {
    { name = "DP-2", description = HKC, height = 2160, enabled = true },
    { name = "DP-20", description = "UNMANAGED", height = 1080, enabled = true },
}
calls = {}
monitor_control.define({
    connector   = "DP-2",
    description = HKC,
    mode        = "1920x1080@60",
    scale       = 1,
})
check(#calls == 2, "define must apply the profile and the unmanaged default")
check(calls[1].output == "DP-2", "profile output must be the concrete connector")
check(calls[2].output == "desc:UNMANAGED", "unmanaged default must keep the desc: key")
check(calls[2].scale == 1, "unmanaged 1080p default scale")

-- 9. apply_all() covers disabled monitors too (all=true), and a
--    description-only profile is applied to every matching monitor
monitors = {
    { name = "DP-9", description = SHARED, height = 720, enabled = true },
    { name = "DP-10", description = SHARED, height = 720, enabled = true },
    { name = "DP-11", description = SHARED, height = 720, enabled = false },
    { name = "FALLBACK", description = "FALLBACK", height = 1080, enabled = true },
}
calls = {}
local applied = monitor_control.apply_all()
check(applied == 3, "apply_all should include the disabled matching monitor, got " .. tostring(applied))
check(#calls == 3, "description-only profile must apply to all three monitors, got " .. tostring(#calls))

-- 9b. unmanaged monitors get the auto-layout default (legacy desc: key);
--     disabled unmanaged monitors are left alone
monitors = {
    { name = "DP-21", description = "UNMANAGED2", height = 2160, enabled = true },
}
calls = {}
applied = monitor_control.apply_all()
check(applied == 1, "unmanaged enabled monitor must get a default rule")
check(calls[1].output == "desc:UNMANAGED2", "default rule must use the desc: key")
check(calls[1].scale == 2, "4K unmanaged monitor must default to 2x")

monitors = {
    { name = "DP-22", description = "OFF", height = 1080, enabled = false },
}
calls = {}
applied = monitor_control.apply_all()
check(applied == 0 and #calls == 0, "disabled unmanaged monitor must be left alone")

-- 10. status/mode helpers expose the match mode and effective scale
monitors = {
    { name = "DP-9", description = SHARED, height = 720, enabled = true },
    { name = "DP-22", description = "OFF", height = 1080, enabled = false },
}
local status = monitor_control.status()
check(#status.profiles >= 8, "status profile count")
check(status.monitors[1].mode == "description", "status must report the description match mode")
check(status.monitors[1].scale == 1, "status must report the effective scale")
check(status.monitors[2].scale == nil, "disabled unmanaged monitor has no effective scale")
check(monitor_control.is_managed({ name = "DP-9", description = SHARED }) == true, "is_managed true")
check(monitor_control.is_managed({ name = "DP-9", description = "NOPE" }) == false, "is_managed false")
check(monitor_control.match_mode({ name = "DP-9", description = SHARED }) == "description", "match_mode")

-- 11. a single profile table is accepted too
calls = {}
monitor_control.define({
    connector   = "DP-12",
    description = HKC,
    mode        = "1920x1080@60",
})
check(monitor_control.match({ name = "DP-12", description = HKC }) ~= nil, "single profile table must be accepted")

print("ok: monitor_control")
