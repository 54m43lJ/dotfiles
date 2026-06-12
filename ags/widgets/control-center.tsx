import GLib from "gi://GLib"
import Gtk from "gi://Gtk?version=4.0"
import AstalBattery from "gi://AstalBattery"
import AstalWp from "gi://AstalWp"
import AstalNetwork from "gi://AstalNetwork"
import { For, With, createBinding } from "ags"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"

const batIconFn= (p: number, ch: boolean): string =>
  ch
    ? p < 0.15 ? "󰢜" : p < 0.25 ? "󰂆" : p < 0.35 ? "󰂇" : p < 0.45 ? "󰂈" : p < 0.55 ? "󰢝" : p < 0.65 ? "󰂉" : p < 0.75 ? "󰢞" : p < 0.85 ? "󰂊" : p < 0.95 ? "󰂋" : "󰂅"
    : p < 0.05 ? "󰂎" : p < 0.15 ? "󰁺" : p < 0.25 ? "󰁻" : p < 0.35 ? "󰁼" : p < 0.45 ? "󰁽" : p < 0.55 ? "󰁾" : p < 0.65 ? "󰁿" : p < 0.75 ? "󰂀" : p < 0.85 ? "󰂁" : p < 0.95 ? "󰂂" : "󰁹"

function VolumeSlider() {
  const { defaultSpeaker: speaker } = AstalWp.get_default()!

  const volIcon = createBinding(speaker, "mute")((m: boolean) =>
    m ? "󰝟"
      : speaker.volume <= 0 ? ""
      : speaker.volume <= 0.33 ? ""
      : speaker.volume <= 0.66 ? "󰕾"
      : "",
  )

  return (
    <box class="cc-section">
      <box
        class="clickable"
        $={(self: Gtk.Box) => {
          const click = new Gtk.GestureClick()
          click.connect("pressed", () => speaker.set_mute(!speaker.mute))
          self.add_controller(click)
        }}
      >
        <label label={volIcon} class="fs-xl" />
      </box>
      <slider
        hexpand
        min={0}
        max={1}
        value={createBinding(speaker, "volume")}
        onChangeValue={({ value }: { value: number }) => speaker.set_volume(value)}
      />
      <label
        class="fs-lg"
        label={createBinding(speaker, "volume")((v: number) => `${Math.round(v * 100)}%`)}
      />
    </box>
  )
}

function CCNetwork() {
  const network = AstalNetwork.get_default()
  const wifi = createBinding(network, "wifi")

  async function connect(ap: AstalNetwork.AccessPoint) {
    try { await execAsync(`nmcli d wifi connect ${ap.bssid}`) } catch (error) { console.error(error) }
  }

  const sorted = (arr: Array<AstalNetwork.AccessPoint>) =>
    arr.filter((ap) => !!ap.ssid).sort((a, b) => b.strength - a.strength)

  const signalIcon = (strength: number) =>
    strength >= 80 ? "󰤨" : strength >= 60 ? "󰤥" : strength >= 40 ? "󰤢" : strength >= 20 ? "󰤟" : "󰤯"

  return (
    <box class="cc-section" orientation={Gtk.Orientation.VERTICAL}>
      <box class="cc-header" hexpand>
        <label label="󰈀 Network  ▾" class="fs-lg" />
      </box>
      <With value={wifi}>
        {(wifi: AstalNetwork.Wifi | null) =>
          wifi && (
            <box orientation={Gtk.Orientation.VERTICAL}>
              <label
                class="cc-info"
                label={createBinding(wifi, "ssid")((ssid: string) => `Connected: ${ssid}`)}
                wrap
              />
              <label class="cc-subtitle fs-sm" label="Wi-Fi Networks" />
              <scrolledwindow
                $={(self: Gtk.ScrolledWindow) => { self.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC }}
                class="cc-wifi-scroll"
              >
                <box orientation={Gtk.Orientation.VERTICAL}>
                  <For each={createBinding(wifi, "accessPoints")(sorted)}>
                    {(ap: AstalNetwork.AccessPoint) => (
                      <box
                        class="cc-wifi-entry"
                        $={(self: Gtk.Box) => {
                          const click = new Gtk.GestureClick()
                          click.connect("pressed", () => connect(ap))
                          self.add_controller(click)
                        }}
                      >
                        <box>
                          <label label={signalIcon(ap.strength)} />
                          <box hexpand>
                            <label label={createBinding(ap, "ssid")} />
                          </box>
                          <label
                            class="fs-sm"
                            label={createBinding(wifi, "activeAccessPoint")(
                              (active) => active === ap ? "connected" : "",
                            )}
                          />
                        </box>
                      </box>
                    )}
                  </For>
                </box>
              </scrolledwindow>
            </box>
          )
        }
      </With>
    </box>
  )
}

function CCBattery() {
  const battery = AstalBattery.get_default()
  const pct = createBinding(battery, "percentage")

  return (
    <box class="cc-section">
      <label
        class="fs-md"
        label={pct((p: number) => batIconFn(p, battery.charging))}
      />
      <Gtk.ProgressBar hexpand valign={Gtk.Align.CENTER} fraction={pct} />
      <label class="fs-lg" label={pct((p: number) => `${Math.round(p * 100)}%`)} />
    </box>
  )
}

function CCPower() {
  const actions = [
    { icon: "", label: "Lock", cmd: "loginctl lock-session" },
    { icon: "󰗽", label: "Logout", cmd: "hyprshutdown" },
    { icon: "󰜉", label: "Reboot", cmd: "hyprshutdown -p reboot" },
    { icon: "⏻", label: "Shutdown", cmd: "hyprshutdown -p poweroff" },
  ]

  return (
    <box class="cc-section" orientation={Gtk.Orientation.VERTICAL}>
      <box class="cc-header" hexpand>
        <label label="⏻ Power  ▾" class="fs-lg" />
      </box>
      <box orientation={Gtk.Orientation.VERTICAL}>
        {actions.map(({ icon, label, cmd }) => (
          <box
            class="cc-power-btn"
            $={(self: Gtk.Box) => {
              const click = new Gtk.GestureClick()
              click.connect("pressed", () => execAsync(cmd).catch(console.error))
              self.add_controller(click)
            }}
          >
            <box>
              <label label={icon} />
              <label label={`  ${label}`} />
            </box>
          </box>
        ))}
      </box>
    </box>
  )
}

export function ControlCenter() {
  return (
    <box class="control-center" orientation={Gtk.Orientation.VERTICAL}>
      <box class="cc-section" halign={Gtk.Align.CENTER}>
        <label
          class="fs-lg"
          label={createPoll("", 1000, () => GLib.DateTime.new_now_local().format("%c")!)}
          wrap
        />
      </box>
      <VolumeSlider />
      <box class="cc-section">
        <label label="󰃟" class="fs-xl" />
        <slider hexpand min={0} max={100} value={50} sensitive={false} />
        <label label="--" class="cc-placeholder fs-lg" />
      </box>
      <CCNetwork />
      <CCBattery />
      <CCPower />
    </box>
  )
}

export default function CCTrigger() {
  const { defaultSpeaker: speaker } = AstalWp.get_default()!
  const battery = AstalBattery.get_default()

  return (
    <box
      class="cc-trigger"
      $={(self: Gtk.Box) => {
        const ccWindow = new Gtk.Window()
        ccWindow.set_title("ags-cc")
        ccWindow.set_decorated(false)
        ccWindow.set_resizable(false)
        ccWindow.set_hide_on_close(true)
        ccWindow.set_child(ControlCenter() as Gtk.Widget)

        const root = self.get_root()
        if (root instanceof Gtk.Window) ccWindow.set_transient_for(root)

        const focusCtrl = new Gtk.EventControllerFocus()
        focusCtrl.connect("leave", () => {
          if (ccWindow.visible) {
            ccWindow.close()
          }
        })
        ccWindow.add_controller(focusCtrl)

        const click = new Gtk.GestureClick()
        click.connect("pressed", () => {
          if (ccWindow.visible) {
            ccWindow.close()
          } else {
            ccWindow.present()
          }
        })
        self.add_controller(click)
      }}
    >
      <box>
        <label label="󰈀" class="fs-xl" />
        <label
          class="fs-xl"
          label={createBinding(speaker, "mute")((m: boolean) =>
            m ? "󰝟"
              : speaker.volume <= 0 ? ""
              : speaker.volume <= 0.33 ? ""
              : speaker.volume <= 0.66 ? "󰕾"
              : "",
          )}
        />
        <label
          class="fs-md"
          visible={createBinding(battery, "isPresent")}
          label={createBinding(battery, "percentage")((p: number) =>
            batIconFn(p, battery.charging),
          )}
        />
        <label
          class="fs-md"
          label={createPoll("", 1000, () => GLib.DateTime.new_now_local().format("%H:%M")!)}
        />
      </box>
    </box>
  )
}
