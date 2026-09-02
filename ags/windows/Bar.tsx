import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import { onCleanup } from "ags"
import Workspaces from "../widgets/workspaces"
import Music from "../widgets/music"
import WindowTitle from "../widgets/window-title"
import Tray from "../widgets/tray"
import Memory from "../widgets/memory"
import CCTrigger from "../widgets/control-center"

export default function Bar({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  let win: Astal.Window
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  onCleanup(() => {
    win.destroy()
  })

  return (
    <window
      $={(self: Astal.Window) => (win = self)}
      visible
      namespace="my-bar"
      name="bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox>
        <box $type="start">
          <Workspaces gdkmonitor={gdkmonitor} />
          <Music />
        </box>
        <box $type="center">
          <WindowTitle />
        </box>
        <box $type="end">
          <Tray />
          <Memory />
          <CCTrigger />
        </box>
      </centerbox>
    </window>
  )
}
