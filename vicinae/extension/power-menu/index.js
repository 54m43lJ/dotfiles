// Power Menu — vicinae extension (Raycast-compatible API, CommonJS).
// Icons: breeze system action icons; destructive actions confirm via
// confirmAlert; Lock/Suspend are dispatched through hyprctl so Hyprland
// runs them (same pattern as the old dmenu power-menu.sh / hypridle).
const React = require("react");
const { exec } = require("child_process");
const {
	List,
	Action,
	ActionPanel,
	Image,
	confirmAlert,
	closeMainWindow,
} = require("@vicinae/api");

const BREEZE = "/usr/share/icons/breeze/actions/22";

const hyprDispatch = (lua) => exec(`hyprctl dispatch 'hl.dsp.exec_cmd("${lua}")'`);

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
		run: () => exec("hyprshutdown"),
	},
	{
		title: "Reboot",
		subtitle: "systemctl reboot",
		icon: `${BREEZE}/system-reboot.svg`,
		confirm: "Reboot",
		run: () => exec("hyprshutdown -p 'systemctl reboot'"),
	},
	{
		title: "Shutdown",
		subtitle: "systemctl -i poweroff",
		icon: `${BREEZE}/system-shutdown.svg`,
		confirm: "Shutdown",
		run: () => exec("hyprshutdown -p 'systemctl -i poweroff'"),
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
	await closeMainWindow();
	a.run();
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
