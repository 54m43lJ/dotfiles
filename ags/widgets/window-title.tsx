import Gtk from "gi://Gtk?version=4.0"
import Pango from "gi://Pango"
import AstalHyprland from "gi://AstalHyprland"
import { createBinding } from "ags"

export default function WindowTitle() {
  const hypr = AstalHyprland.get_default()
  const client = createBinding(hypr, "focusedClient")

  return (
    <box class="title-box fs-lg" halign={Gtk.Align.CENTER}>
      <label
        $={(self: Gtk.Label) => {
          self.ellipsize = Pango.EllipsizeMode.END
          self.max_width_chars = 40
        }}
        label={client((c: AstalHyprland.Client | null) => c?.title || "")}
        tooltipText={client((c: AstalHyprland.Client | null) => c?.title || "")}
      />
    </box>
  )
}
