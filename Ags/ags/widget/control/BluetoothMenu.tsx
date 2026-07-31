import { Gtk } from "ags/gtk4"
import { createState, For } from "gnim"
import { btPowered } from "../../lib/connectivity"
import { bumpVolume } from "../../lib/volume"
import {
  getKnownDevices,
  scanDevices,
  connectDevice,
  disconnectDevice,
  pairDevice,
  trustDevice,
  setBluetoothEnabled,
  type BtDevice,
} from "../../lib/bluetooth"

export default function BluetoothMenu({ onBack }: { onBack: () => void }) {
  const [pairedDevices, setPairedDevices] = createState<BtDevice[]>([])
  const [availableDevices, setAvailableDevices] = createState<BtDevice[]>([])
  const [selectedMac, setSelectedMac] = createState<string | null>(null)
  const [isScanning, setIsScanning] = createState(false)

  async function refreshPaired() {
    try {
      const all = await getKnownDevices()
      setPairedDevices(all.filter(d => d.paired || d.trusted))
    } catch (e) {
      console.error("Failed to refresh paired devices:", e)
    }
  }

  async function scan() {
    if (isScanning()) return
    setIsScanning(true)
    setAvailableDevices([])
    try {
      await refreshPaired()
      const found = await scanDevices(8)
      setAvailableDevices(found)
    } catch (e) {
      console.error("Failed to scan:", e)
    } finally {
      setIsScanning(false)
    }
  }

  function onSelectPaired(d: BtDevice) {
    if (d.connected) {
      disconnectDevice(d.mac).then(() => refreshPaired()).catch((e: any) => console.error(e))
    } else {
      connectDevice(d.mac)
        .then(() => bumpVolume())
        .then(() => refreshPaired())
        .catch((e: any) => console.error(e))
    }
  }

  function onSelectAvailable(d: BtDevice) {
    setSelectedMac(d.mac)
    pairDevice(d.mac)
      .then(() => {
        trustDevice(d.mac).catch(() => {})
        return connectDevice(d.mac)
      })
      .then(() => bumpVolume())
      .then(() => {
        setSelectedMac(null)
        refreshPaired()
        scan()
      })
      .catch((e: any) => {
        console.error("Failed to pair/connect:", e)
        setSelectedMac(null)
      })
  }

  return (
    <box
      orientation={Gtk.Orientation.VERTICAL}
      spacing={12}
      $={self => {
        self.connect("map", () => refreshPaired())
      }}
    >
      {/* Header */}
      <box spacing={8}>
        <button onClicked={() => onBack()}>
          <image iconName="go-previous-symbolic" pixelSize={16} />
        </button>
        <label label="Bluetooth" hexpand halign={Gtk.Align.CENTER} />
        <button
          class="wifi-refresh-icon-btn"
          onClicked={() => scan()}
        >
          <image
            iconName={isScanning.as((v: boolean) => v ? "content-loading-symbolic" : "view-refresh-symbolic")}
            pixelSize={14}
          />
        </button>
        <switch
          class="wifi-switch"
          active={btPowered}
          $={self => {
            self.connect("state-set", (_self, state) => {
              setBluetoothEnabled(state)
              return false
            })
          }}
        />
      </box>

      <scrolledwindow vexpand heightRequest={340}>
        <box orientation={Gtk.Orientation.VERTICAL} spacing={12}>

          {/* ── Emparejados ── */}
          <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
            <label
              class="section-label"
              label="Emparejados"
              halign={Gtk.Align.START}
            />
            <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
              <For each={pairedDevices}>
                {(d: BtDevice) => (
                  <button
                    class={selectedMac.as((m: string | null) => m === d.mac ? "bt-device-btn selected" : "bt-device-btn")}
                    onClicked={() => onSelectPaired(d)}
                  >
                    <box spacing={10}>
                      <image
                        iconName={d.connected
                          ? "bluetooth-active-symbolic"
                          : "bluetooth-symbolic"}
                        pixelSize={18}
                      />
                      <label label={d.name} hexpand halign={Gtk.Align.START} />
                      {d.connected && (
                        <label class="bt-status-label" label="Conectado" />
                      )}
                    </box>
                  </button>
                )}
              </For>
              <label
                label="Sin dispositivos emparejados"
                halign={Gtk.Align.CENTER}
                class="bt-empty-label"
                visible={pairedDevices.as((list: BtDevice[]) => list.length === 0)}
              />
            </box>
          </box>

          {/* ── Dispositivos disponibles ── */}
          <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
            <box spacing={8}>
              <label
                class="section-label"
                label="Dispositivos disponibles"
                halign={Gtk.Align.START}
                hexpand
              />
              <button
                class="wifi-refresh-icon-btn"
                onClicked={() => scan()}
              >
                <image
                  iconName={isScanning.as((v: boolean) => v ? "content-loading-symbolic" : "view-refresh-symbolic")}
                  pixelSize={14}
                />
              </button>
            </box>
            <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
              <For each={availableDevices}>
                {(d: BtDevice) => (
                  <button
                    class={selectedMac.as((m: string | null) => m === d.mac ? "bt-device-btn selected" : "bt-device-btn")}
                    onClicked={() => onSelectAvailable(d)}
                  >
                    <box spacing={10}>
                      <image
                        iconName="bluetooth-symbolic"
                        pixelSize={18}
                      />
                      <label label={d.name} hexpand halign={Gtk.Align.START} />
                      <label class="bt-status-label" label="Conectar" />
                    </box>
                  </button>
                )}
              </For>
              <label
                label={isScanning.as((v: boolean) => v ? "Buscando..." : "No se encontraron dispositivos")}
                halign={Gtk.Align.CENTER}
                class="bt-empty-label"
                visible={availableDevices.as((list: BtDevice[]) => list.length === 0)}
              />
            </box>
          </box>

        </box>
      </scrolledwindow>
    </box>
  )
}
