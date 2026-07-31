import { Gtk } from "ags/gtk4"
import { safeExec } from "../../lib/utils"
import { wifiEnabled, btPowered, currentSsid, currentBtDevice } from "../../lib/connectivity"

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
      <button
        class={wifiEnabled.as((v: boolean) => `toggle-btn wifi-toggle ${v ? "active" : ""}`)}
        onClicked={() => onWifiExpand()}
      >
        <box>
          <box orientation={Gtk.Orientation.VERTICAL} spacing={4} hexpand halign={Gtk.Align.START}>
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
          <image iconName="go-down-symbolic" pixelSize={14} valign={Gtk.Align.CENTER} />
        </box>
      </button>

      {/* Bluetooth */}
      <button
        class={btPowered.as((v: boolean) => `toggle-btn bt-toggle ${v ? "active" : ""}`)}
        onClicked={() => onBtExpand()}
      >
        <box>
          <box orientation={Gtk.Orientation.VERTICAL} spacing={4} hexpand halign={Gtk.Align.START}>
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
          <image iconName="go-down-symbolic" pixelSize={14} valign={Gtk.Align.CENTER} />
        </box>
      </button>
    </box>
  )
}
