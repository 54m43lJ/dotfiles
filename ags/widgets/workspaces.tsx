import Gdk from "gi://Gdk?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import AstalHyprland from "gi://AstalHyprland"
import { For, With, createBinding } from "ags"
import { execAsync } from "ags/process"

export default function Workspaces({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const hypr = AstalHyprland.get_default()

  const monitorBinding = createBinding(hypr, "monitors")((monitors) =>
    monitors.find((m: AstalHyprland.Monitor) => m.name === gdkmonitor.connector) ?? null,
  )

  return (
    <With value={monitorBinding}>
      {(monitor: AstalHyprland.Monitor | null) => {
        if (!monitor) return <box />

        const wsStates = createBinding(hypr, "workspaces")((all) => {
          const activeId = monitor.activeWorkspace?.id ?? -1
          return Array.from({ length: 10 }, (_, i) => {
            const n = i + 1
            const id = monitor.id * 10 + n
            return { label: n === 10 ? "0" : String(n), id, active: activeId === id }
          })
        })

        return (
          <box>
            <For each={wsStates}>
              {(state: { label: string; id: number; active: boolean }) => (
                <box
                  class={`workspace-entry${state.active ? " current" : ""}`}
                  $={(self: Gtk.Box) => {
                    const click = new Gtk.GestureClick()
                    click.connect("pressed", () =>
                      execAsync(`hyprctl dispatch "hl.dsp.focus({ workspace = ${state.id} })"`).catch(console.error),
                    )
                    self.add_controller(click)
                  }}
                >
                  <label label={state.label} />
                </box>
              )}
            </For>
          </box>
        )
      }}
    </With>
  )
}
