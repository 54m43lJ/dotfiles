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
            <button
              visible={createBinding(player, "canGoPrevious")}
              onClicked={() => player.previous()}
            >
              <label label="󰒮" />
            </button>
            <button onClicked={() => player.play_pause()}>
              <label label={isPlaying((p: boolean) => (p ? "󰏤" : "󰐊"))} />
            </button>
            <button
              visible={createBinding(player, "canControl")}
              onClicked={() => player.stop()}
            >
              <label label="󰓛" />
            </button>
            <button
              visible={createBinding(player, "canGoNext")}
              onClicked={() => player.next()}
            >
              <label label="󰒭" />
            </button>
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
