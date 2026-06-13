import Gdk from "gi://Gdk?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import AstalHyprland from "gi://AstalHyprland"
import { For, With, createBinding, createComputed, createState } from "ags"
import { execAsync } from "ags/process"

interface WsState {
  label: string
  id: number
  active: boolean
  mapped: boolean
}

function makeFallback(): WsState[] {
  return Array.from({ length: 10 }, (_, i) => ({
    label: i === 9 ? "0" : String(i + 1),
    id: i + 1,
    active: false,
    mapped: false,
  }))
}

export default function Workspaces({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const hypr = AstalHyprland.get_default()
  const [wsStates, setWsStates] = createState<WsState[]>(makeFallback())

  const wsBinding = createComputed(() => wsStates())

  const monitorBinding = createBinding(hypr, "monitors").as((monitors) => {
    const monitor = gdkmonitor.connector
      ? monitors.find((m: AstalHyprland.Monitor) => m.name === gdkmonitor.connector) ?? null
      : null
    if (!monitor) {
      setWsStates(makeFallback())
      return null
    }
    const baseId = monitor.id * 10
    setWsStates((prev) =>
      prev.map((_, i) => {
        const n = i + 1
        const id = baseId + n
        const active = monitor.activeWorkspace?.id === id
        return { label: n === 10 ? "0" : String(n), id, active, mapped: true }
      }),
    )
    return monitor
  })

  return (
    <With value={monitorBinding}>
      {(monitor) => {
        if (monitor) {
          createBinding(monitor, "activeWorkspace").as((active) => {
            setWsStates((prev) =>
              prev.map((s) => ({ ...s, active: active?.id === s.id })),
            )
            return active
          })
        }

        return (
          <box>
            <For each={wsBinding}>
              {(state: WsState) => (
                <box
                  class={`workspace-entry${state.active ? " current" : ""} fs-md`}
                  $={state.mapped
                    ? (self: Gtk.Box) => {
                        const click = new Gtk.GestureClick()
                        click.connect("pressed", () =>
                          execAsync(`hyprctl dispatch "hl.dsp.focus({ workspace = ${state.id} })"`).catch(console.error),
                        )
                        self.add_controller(click)
                      }
                    : undefined}
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
