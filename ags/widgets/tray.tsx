import Gtk from "gi://Gtk?version=4.0"
import AstalTray from "gi://AstalTray"
import { For, createBinding } from "ags"

export default function Tray() {
  const tray = AstalTray.get_default()
  const items = createBinding(tray, "items")

  return (
    <box>
      <For each={items}>
        {(item: AstalTray.TrayItem) => (
          <box
            $={(self: Gtk.Box) => {
              const popover = new Gtk.PopoverMenu()
              popover.set_parent(self)
              popover.set_menu_model(item.menuModel)
              popover.insert_action_group("dbusmenu", item.actionGroup)

              item.connect("notify::action-group", () => {
                popover.insert_action_group("dbusmenu", item.actionGroup)
              })

              const click = new Gtk.GestureClick()
              click.connect("pressed", () => popover.popup())
              self.add_controller(click)
            }}
          >
            <image gicon={createBinding(item, "gicon")} />
          </box>
        )}
      </For>
    </box>
  )
}
