import Gtk from "gi://Gtk?version=4.0"
import Pango from "gi://Pango"
import AstalMpris from "gi://AstalMpris"
import { With, createBinding } from "ags"

export default function Music() {
  const mpris = AstalMpris.get_default()
  const players = createBinding(mpris, "players")

  const activePlayer = players((list: AstalMpris.Player[]) => {
    if (!list || list.length === 0) return null
    return (
      list.find(
        (p: AstalMpris.Player) =>
          p.playbackStatus === AstalMpris.PlaybackStatus.PLAYING,
      ) || list[0]
    )
  })

  return (
    <With value={activePlayer}>
      {(player: AstalMpris.Player | null) => {
        if (!player) return <box />

        const isPlaying = createBinding(player, "playbackStatus")(
          (s: AstalMpris.PlaybackStatus) =>
            s === AstalMpris.PlaybackStatus.PLAYING,
        )

        return (
          <box class="music-box">
            <box
              class="clickable"
              visible={createBinding(player, "canGoPrevious")}
              $={(self: Gtk.Box) => {
                const click = new Gtk.GestureClick()
                click.connect("pressed", () => player.previous())
                self.add_controller(click)
              }}
            >
              <label label="󰒮" />
            </box>
            <box
              class="clickable"
              $={(self: Gtk.Box) => {
                const click = new Gtk.GestureClick()
                click.connect("pressed", () => player.play_pause())
                self.add_controller(click)
              }}
            >
              <label label={isPlaying((p: boolean) => (p ? "󰏤" : "󰐊"))} />
            </box>
            <box
              class="clickable"
              visible={createBinding(player, "canControl")}
              $={(self: Gtk.Box) => {
                const click = new Gtk.GestureClick()
                click.connect("pressed", () => player.stop())
                self.add_controller(click)
              }}
            >
              <label label="󰓛" />
            </box>
            <box
              class="clickable"
              visible={createBinding(player, "canGoNext")}
              $={(self: Gtk.Box) => {
                const click = new Gtk.GestureClick()
                click.connect("pressed", () => player.next())
                self.add_controller(click)
              }}
            >
              <label label="󰒭" />
            </box>
            <box visible={isPlaying} class="fs-md">
              <label
                $={(self: Gtk.Label) => {
                  self.ellipsize = Pango.EllipsizeMode.END
                  self.max_width_chars = 20
                }}
                label={createBinding(player, "title")}
                tooltipText={`${player.artist} - ${player.title}`}
              />
            </box>
          </box>
        )
      }}
    </With>
  )
}
