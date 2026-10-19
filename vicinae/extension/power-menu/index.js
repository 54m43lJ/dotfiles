// Power Menu — vicinae extension (Raycast-compatible API, CommonJS).
// Commands mirror the old wofi power menu: run everything through hyprctl so
// Hyprland owns the child process and it survives Vicinae closing; destructive
// actions use hyprshutdown.
const React = require("react");
const { execFile } = require("child_process");
const {
	List,
	Action,
	ActionPanel,
	Image,
	confirmAlert,
	closeMainWindow,
} = require("@vicinae/api");

const BREEZE = "/usr/share/icons/breeze/actions/22";

// Pass the Lua expression as a single argv entry (no shell quoting games).
// JSON.stringify gives a valid double-quoted Lua string.
const hyprDispatch = (lua) =>
	new Promise((resolve, reject) => {
		execFile(
			"hyprctl",
			["dispatch", `hl.dsp.exec_cmd(${JSON.stringify(lua)})`],
			(err) => (err ? reject(err) : resolve()),
		);
	});

const ACTIONS = [
	{
		title: "Lock",
		subtitle: "hyprlock",
		icon: `${BREEZE}/system-lock-screen.svg`,
		confirm: null,
		run: () => hyprDispatch("loginctl lock-session"),
	},
	{
		title: "Logout",
		subtitle: "hyprshutdown",
		icon: `${BREEZE}/system-log-out.svg`,
		confirm: "Logout",
		run: () => hyprDispatch("hyprshutdown"),
	},
	{
		title: "Reboot",
		subtitle: "hyprshutdown -p 'systemctl reboot'",
		icon: `${BREEZE}/system-reboot.svg`,
		confirm: "Reboot",
		run: () => hyprDispatch("hyprshutdown -p 'systemctl reboot'"),
	},
	{
		title: "Shutdown",
		subtitle: "hyprshutdown -p 'systemctl -i poweroff'",
		icon: `${BREEZE}/system-shutdown.svg`,
		confirm: "Shutdown",
		run: () => hyprDispatch("hyprshutdown -p 'systemctl -i poweroff'"),
	},
	{
		title: "Suspend",
		subtitle: "/usr/local/bin/suspend.sh",
		icon: `${BREEZE}/system-suspend.svg`,
		confirm: null,
		run: () => hyprDispatch("/usr/local/bin/suspend.sh"),
	},
];

async function runAction(a) {
	if (a.confirm) {
		const ok = await confirmAlert({
			title: `${a.confirm}?`,
			message: `Confirm ${a.confirm}`,
			primaryAction: { title: "Confirm" },
		});
		if (!ok) return;
	}
	// Dispatch before closing: closing unloads the extension worker, and
	// hyprctl needs to hand the command to Hyprland first.
	try {
		await a.run();
	} catch (err) {
		console.error(`Power action failed: ${err}`);
	}
	await closeMainWindow();
}

function Command() {
	return React.createElement(
		List,
		{ navigationTitle: "Power" },
		ACTIONS.map((a) =>
			React.createElement(List.Item, {
				key: a.title,
				title: a.title,
				subtitle: a.subtitle,
				icon: { source: a.icon, mask: Image.Mask.RoundedRectangle },
				actions: React.createElement(
					ActionPanel,
					null,
					React.createElement(Action, {
						title: a.title,
						icon: a.icon,
						onAction: () => runAction(a),
					}),
				),
			}),
		),
	);
}

module.exports.default = Command;
