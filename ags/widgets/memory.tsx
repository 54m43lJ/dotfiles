import GLib from "gi://GLib"
import Gtk from "gi://Gtk?version=4.0"
import { createPoll } from "ags/time"

export default function Memory() {
  const memPct = createPoll("0", 3000, () => {
    try {
      const raw = GLib.file_get_contents("/proc/meminfo")
      const total = Number(raw.match(/MemTotal:\s+(\d+)/)?.[1]) || 1
      const avail = Number(raw.match(/MemAvailable:\s+(\d+)/)?.[1]) || 0
      return String(Math.round(((total - avail) / total) * 100))
    } catch {
      return "0"
    }
  })

  let revealer: Gtk.Revealer | null = null

  return (
    <box
      class="metric"
      $={(self: Gtk.Box) => {
        const motion = new Gtk.EventControllerMotion()
        motion.connect("enter", () => {
          if (revealer) revealer.revealChild = true
        })
        motion.connect("leave", () => {
          if (revealer) revealer.revealChild = false
        })
        self.add_controller(motion)
      }}
    >
      <revealer
        $={(self: Gtk.Revealer) => {
          revealer = self
          self.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
          self.transition_duration = 300
        }}
      >
        <slider
          min={0}
          max={100}
          value={memPct((v: string) => Number(v))}
          sensitive={false}
        />
      </revealer>
      <label label="󰍛" class="fs-xl" />
    </box>
  )
}
