import { Gtk } from "ags/gtk4"
import { createState, For } from "gnim"
import GLib from "gi://GLib"
import { wifiEnabled, refreshCurrentSsid } from "../../lib/connectivity"
import {
  scanNetworks,
  connectToNetwork,
  disconnectNetwork,
  setWifiEnabled,
  getKnownSsids,
  forgetNetwork,
  type Network,
} from "../../lib/wifi"

export default function WifiMenu({ onBack }: { onBack: () => void }) {
  const [networks, setNetworks] = createState<Network[]>([])
  const [selectedSsid, setSelectedSsid] = createState<string | null>(null)
  const [password, setPassword] = createState("")
  const [status, setStatus] = createState("")
  const [knownSsids, setKnownSsids] = createState<Set<string>>(new Set())

  async function refresh(force = false) {
    try {
      const list = await scanNetworks(force)
      setNetworks(list)
    } catch (e) {
      console.error("Failed to scan networks:", e)
    }
  }

  async function loadKnownSsids() {
    try {
      setKnownSsids(await getKnownSsids())
    } catch (e) {
      console.error("Failed to load known SSIDs:", e)
    }
  }

  function runConnection(ssid: string, pwd?: string) {
    setStatus("Conectando...")
    connectToNetwork(ssid, pwd)
      .then(() => {
        setStatus("Conectado")
        refreshCurrentSsid()
        refresh(true)
        loadKnownSsids()
        setSelectedSsid(null)
        setPassword("")
        setTimeout(() => setStatus(""), 2000)
      })
      .catch((e: any) => {
        setStatus(pwd ? "Contraseña incorrecta" : "Error al conectar")
        console.error(e)
      })
  }

  function onSelectNetwork(n: Network) {
    /* Toggle panel para red activa */
    if (n.active) {
      if (selectedSsid() === n.ssid) {
        setSelectedSsid(null)
        setStatus("")
        return
      }
      setSelectedSsid(n.ssid)
      setPassword("")
      setStatus("")
      return
    }
    if (!n.security) {
      runConnection(n.ssid)
      return
    }
    /* Toggle: si ya está seleccionada, deseleccionar */
    if (selectedSsid() === n.ssid) {
      setSelectedSsid(null)
      setStatus("")
      return
    }
    setSelectedSsid(n.ssid)
    setPassword("")
    setStatus("")
  }

  function onConnect() {
    const ssid = selectedSsid()
    if (!ssid) return
    const pwd = password()
    runConnection(ssid, pwd || undefined)
  }

  function onConnectKnown(n: Network) {
    setSelectedSsid(null)
    runConnection(n.ssid)
  }

  function onForget(n: Network) {
    setStatus("Olvidando...")
    forgetNetwork(n.ssid)
      .then(() => {
        setSelectedSsid(null)
        setStatus("Red olvidada")
        loadKnownSsids()
        refresh(true)
        setTimeout(() => setStatus(""), 2000)
      })
      .catch((e: any) => {
        setStatus("Error al olvidar")
        console.error(e)
      })
  }

  function onCancel() {
    setSelectedSsid(null)
    setPassword("")
    setStatus("")
  }

  return (
    <box
      orientation={Gtk.Orientation.VERTICAL}
      spacing={12}
      $={self => {
        self.connect("map", () => {
          refresh(false)
          loadKnownSsids()
        })
      }}
    >
      {/* Header */}
      <box spacing={8}>
        <button onClicked={() => onBack()}>
          <image iconName="go-previous-symbolic" pixelSize={16} />
        </button>
        <label label="Redes Wi-Fi" hexpand halign={Gtk.Align.CENTER} />
        <button
          class="wifi-refresh-icon-btn"
          onClicked={() => refresh(true)}
        >
          <image iconName="view-refresh-symbolic" pixelSize={14} />
        </button>
        <switch
          class="wifi-switch"
          active={wifiEnabled}
          $={self => {
            self.connect("state-set", (_self, state) => {
              setWifiEnabled(state)
              return false
            })
          }}
        />
      </box>

      {/* Lista de redes */}
      <scrolledwindow vexpand heightRequest={260}>
        <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
          <For each={networks}>
            {(n: Network) => (
              <box
                orientation={Gtk.Orientation.VERTICAL}
                spacing={4}
                class={selectedSsid.as((s: string | null) => s === n.ssid ? "wifi-selected-row" : "")}
              >
                {/* Botón de la red */}
                <button
                  class={selectedSsid.as((s: string | null) => s === n.ssid ? "wifi-network-btn no-hover" : "wifi-network-btn")}
                  onClicked={() => onSelectNetwork(n)}
                >
                  <box spacing={10}>
                    <image
                      iconName={n.active
                        ? (n.signal > 75 ? "network-wireless-signal-excellent-symbolic"
                          : n.signal > 50 ? "network-wireless-signal-good-symbolic"
                          : n.signal > 25 ? "network-wireless-signal-ok-symbolic"
                          : "network-wireless-signal-weak-symbolic")
                        : (n.signal > 75 ? "network-wireless-signal-excellent-symbolic"
                          : n.signal > 50 ? "network-wireless-signal-good-symbolic"
                          : n.signal > 25 ? "network-wireless-signal-ok-symbolic"
                          : "network-wireless-signal-weak-symbolic")}
                      pixelSize={16}
                    />
                    <label label={n.ssid} hexpand halign={Gtk.Align.START} />
                    {n.security && (
                      <image iconName="channel-secure-symbolic" pixelSize={14} />
                    )}
                    {n.active && (
                      <image iconName="object-select-symbolic" pixelSize={14} />
                    )}
                  </box>
                </button>

                {/* Panel de acciones (inline, solo para esta red) */}
                <box
                  orientation={Gtk.Orientation.VERTICAL}
                  spacing={8}
                  visible={selectedSsid.as((s: string | null) => s === n.ssid)}
                >
                  {/* Panel contraseña - redes desconocidas */}
                  <box
                    orientation={Gtk.Orientation.VERTICAL}
                    spacing={8}
                    visible={knownSsids.as((ks: Set<string>) => !ks.has(n.ssid) && !n.active)}
                  >
                    <entry
                      $constructor={() => new Gtk.PasswordEntry()}
                      class="wifi-password-entry"
                      hexpand
                      $={self => {
                        self.focusable = true
                        self.show_peek_icon = true
                        self.placeholder_text = "Contraseña"
                        self.connect("changed", () => {
                          setPassword(self.text)
                        })
                        self.connect("map", () => {
                          GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
                            self.grab_focus()
                            return GLib.SOURCE_REMOVE
                          })
                        })
                      }}
                    />
                    <box spacing={8} halign={Gtk.Align.END}>
                      <button
                        class="wifi-form-btn"
                        onClicked={() => onCancel()}
                      >
                        <label label="Cancelar" />
                      </button>
                      <button
                        class="wifi-form-btn primary"
                        onClicked={() => onConnect()}
                      >
                        <label label="Conectar" />
                      </button>
                    </box>
                  </box>

                  {/* Panel conocida - olvidar / conectar */}
                  <box
                    orientation={Gtk.Orientation.VERTICAL}
                    spacing={8}
                    visible={knownSsids.as((ks: Set<string>) => ks.has(n.ssid) || n.active)}
                  >
                    <box spacing={8} halign={Gtk.Align.END}>
                      <button
                        class="wifi-form-btn"
                        onClicked={() => onForget(n)}
                      >
                        <label label="Olvidar" />
                      </button>
                      <button
                        class="wifi-form-btn primary"
                        onClicked={() => {
                          if (n.active) {
                            disconnectNetwork()
                              .then(() => {
                                refreshCurrentSsid()
                                refresh(true)
                              })
                              .catch((e: any) => console.error(e))
                          } else {
                            onConnectKnown(n)
                          }
                        }}
                      >
                        <label label={n.active ? "Desconectar" : "Conectar"} />
                      </button>
                    </box>
                  </box>
                </box>
              </box>
            )}
          </For>
        </box>
      </scrolledwindow>

      {/* Mensaje de estado */}
      <label
        class="wifi-status-label"
        label={status}
        visible={status.as((s: string) => s !== "")}
        halign={Gtk.Align.CENTER}
      />
    </box>
  )
}
