import { Gtk } from "ags/gtk4"
import { safeExec } from "../../lib/utils"
import { wifiEnabled, btPowered, currentSsid, currentBtDevice } from "../../lib/connectivity"
import { setWifiEnabled } from "../../lib/wifi"
import { setBluetoothEnabled } from "../../lib/bluetooth"

export default function ToggleSection({
  onWifiExpand,
  onBtExpand,
}: {
  onWifiExpand: () => void
  onBtExpand: () => void
}) {
  return (
    <box class="section" spacing={12}>
      {/* WiFi */}
      <box
        class={wifiEnabled.as((v: boolean) => `toggle-btn wifi-toggle ${v ? "active" : ""}`)}
      >
        <button
          class="toggle-main"
          hexpand
          onClicked={() => setWifiEnabled(!wifiEnabled())}
        >
          <box orientation={Gtk.Orientation.VERTICAL} spacing={4} halign={Gtk.Align.START}>
            <box spacing={6}>
              <image iconName="network-wireless-symbolic" pixelSize={20} />
              <label class="toggle-label" label="Wi-Fi" />
            </box>
            <label
              class="toggle-sublabel"
              label={currentSsid}
              halign={Gtk.Align.START}
            />
          </box>
        </button>
        <button
          class="toggle-arrow"
          onClicked={() => onWifiExpand()}
        >
          <image iconName="go-down-symbolic" pixelSize={14} valign={Gtk.Align.CENTER} />
        </button>
      </box>

      {/* Bluetooth */}
      <box
        class={btPowered.as((v: boolean) => `toggle-btn bt-toggle ${v ? "active" : ""}`)}
      >
        <button
          class="toggle-main"
          hexpand
          onClicked={() => setBluetoothEnabled(!btPowered())}
        >
          <box orientation={Gtk.Orientation.VERTICAL} spacing={4} halign={Gtk.Align.START}>
            <box spacing={6}>
              <image iconName="bluetooth-symbolic" pixelSize={20} />
              <label class="toggle-label" label="Bluetooth" />
            </box>
            <label
              class="toggle-sublabel"
              label={currentBtDevice}
              halign={Gtk.Align.START}
            />
          </box>
        </button>
        <button
          class="toggle-arrow"
          onClicked={() => onBtExpand()}
        >
          <image iconName="go-down-symbolic" pixelSize={14} valign={Gtk.Align.CENTER} />
        </button>
      </box>
    </box>
  )
}
