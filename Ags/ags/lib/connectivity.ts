import { createState } from "gnim"
import Gio from "gi://Gio"
import GLib from "gi://GLib"

/* ── D-Bus helpers ── */

function getSystemProperty(
  busName: string,
  objectPath: string,
  iface: string,
  property: string,
): any {
  const proxy = Gio.DBusProxy.new_for_bus_sync(
    Gio.BusType.SYSTEM,
    Gio.DBusProxyFlags.NONE,
    null,
    busName,
    objectPath,
    "org.freedesktop.DBus.Properties",
    null,
  )
  const result = proxy.call_sync(
    "Get",
    GLib.Variant.new("(ss)", [iface, property]),
    Gio.DBusCallFlags.NONE,
    -1,
    null,
  )
  return result.deep_unpack()[0].deep_unpack()
}

/* ── WiFi ── */

const [wifiEnabled, setWifiEnabled] = createState(false)
export { wifiEnabled }

const [currentSsid, setCurrentSsid] = createState("Sin conexión")
export { currentSsid }

function updateWifiEnabled() {
  try {
    const enabled = getSystemProperty(
      "org.freedesktop.NetworkManager",
      "/org/freedesktop/NetworkManager",
      "org.freedesktop.NetworkManager",
      "WirelessEnabled",
    )
    if (wifiEnabled() !== enabled) {
      setWifiEnabled(enabled)
    }
  } catch (e) {
    console.error("updateWifiEnabled error:", e)
  }
}

function updateCurrentSsid() {
  try {
    const enabled = getSystemProperty(
      "org.freedesktop.NetworkManager",
      "/org/freedesktop/NetworkManager",
      "org.freedesktop.NetworkManager",
      "WirelessEnabled",
    )

    if (!enabled) {
      if (currentSsid() !== "Apagado") {
        setCurrentSsid("Apagado")
      }
      return
    }

    const activeConns = getSystemProperty(
      "org.freedesktop.NetworkManager",
      "/org/freedesktop/NetworkManager",
      "org.freedesktop.NetworkManager",
      "ActiveConnections",
    ) as string[]

    let foundSsid: string | null = null

    for (const path of activeConns) {
      const type = getSystemProperty(
        "org.freedesktop.NetworkManager",
        path,
        "org.freedesktop.NetworkManager.Connection.Active",
        "Type",
      ) as string

      if (type === "802-11-wireless") {
        const devices = getSystemProperty(
          "org.freedesktop.NetworkManager",
          path,
          "org.freedesktop.NetworkManager.Connection.Active",
          "Devices",
        ) as string[]

        for (const devPath of devices) {
          const devType = getSystemProperty(
            "org.freedesktop.NetworkManager",
            devPath,
            "org.freedesktop.NetworkManager.Device",
            "DeviceType",
          ) as number

          if (devType === 2) {
            const apPath = getSystemProperty(
              "org.freedesktop.NetworkManager",
              devPath,
              "org.freedesktop.NetworkManager.Device.Wireless",
              "ActiveAccessPoint",
            ) as string

            if (apPath && apPath !== "/") {
              const ssidBytes = getSystemProperty(
                "org.freedesktop.NetworkManager",
                apPath,
                "org.freedesktop.NetworkManager.AccessPoint",
                "Ssid",
              ) as number[]

              if (ssidBytes && ssidBytes.length > 0) {
                foundSsid = String.fromCharCode(...ssidBytes)
                break
              }
            }
          }
        }
      }

      if (foundSsid) break
    }

    const next = foundSsid || "Sin conexión"
    if (currentSsid() !== next) {
      setCurrentSsid(next)
    }
  } catch (e) {
    console.error("updateCurrentSsid error:", e)
  }
}

try {
  Gio.DBus.system.signal_subscribe(
    "org.freedesktop.NetworkManager",
    "org.freedesktop.DBus.Properties",
    "PropertiesChanged",
    "/org/freedesktop/NetworkManager",
    null,
    Gio.DBusSignalFlags.NONE,
    (_conn: any, _sender: string, _path: string, _iface: string, _signal: string, params: any) => {
      const [interfaceName, changed] = params.deep_unpack()
      if (interfaceName !== "org.freedesktop.NetworkManager") return

      if (changed["WirelessEnabled"] !== undefined) {
        updateWifiEnabled()
      }
      if (changed["ActiveConnections"] !== undefined) {
        updateCurrentSsid()
      }
    },
  )
} catch (e) {
  console.error("Failed to subscribe to NM signals:", e)
}

updateWifiEnabled()
updateCurrentSsid()

/* ── Bluetooth ── */

const [btPowered, setBtPowered] = createState(false)
export { btPowered }

const [currentBtDevice, setCurrentBtDevice] = createState("Apagado")
export { currentBtDevice }

function updateBtPowered() {
  try {
    const powered = getSystemProperty(
      "org.bluez",
      "/org/bluez/hci0",
      "org.bluez.Adapter1",
      "Powered",
    )
    if (btPowered() !== powered) {
      setBtPowered(powered)
    }
  } catch (e) {
    console.error("updateBtPowered error:", e)
  }
}

function updateBtDevice() {
  try {
    const powered = getSystemProperty(
      "org.bluez",
      "/org/bluez/hci0",
      "org.bluez.Adapter1",
      "Powered",
    )

    if (!powered) {
      if (currentBtDevice() !== "Apagado") {
        setCurrentBtDevice("Apagado")
      }
      return
    }

    const proxy = Gio.DBusProxy.new_for_bus_sync(
      Gio.BusType.SYSTEM,
      Gio.DBusProxyFlags.NONE,
      null,
      "org.bluez",
      "/",
      "org.freedesktop.DBus.ObjectManager",
      null,
    )

    const result = proxy.call_sync(
      "GetManagedObjects",
      null,
      Gio.DBusCallFlags.NONE,
      -1,
      null,
    )

    const objects = result.deep_unpack()[0]
    let connectedDevice: string | null = null

    for (const path in objects) {
      const ifaces = objects[path]
      const device = ifaces["org.bluez.Device1"]
      if (!device) continue

      const connectedVar = device.Connected
      if (connectedVar === undefined) continue

      const isConnected =
        typeof connectedVar === "object" && connectedVar.deep_unpack
          ? connectedVar.deep_unpack()
          : connectedVar

      if (isConnected === true) {
        const nameVar = device.Name
        if (nameVar !== undefined) {
          const deviceName =
            typeof nameVar === "object" && nameVar.deep_unpack
              ? nameVar.deep_unpack()
              : nameVar
          if (deviceName) {
            connectedDevice = deviceName
            break
          }
        }
      }
    }

    const next = connectedDevice || "Sin conexión"
    if (currentBtDevice() !== next) {
      setCurrentBtDevice(next)
    }
  } catch (e) {
    console.error("updateBtDevice error:", e)
  }
}

try {
  Gio.DBus.system.signal_subscribe(
    "org.bluez",
    "org.freedesktop.DBus.Properties",
    "PropertiesChanged",
    null,
    null,
    Gio.DBusSignalFlags.NONE,
    (_conn: any, _sender: string, _path: string, _iface: string, _signal: string, params: any) => {
      const [interfaceName, changed] = params.deep_unpack()

      if (interfaceName === "org.bluez.Adapter1" && changed["Powered"] !== undefined) {
        updateBtPowered()
        updateBtDevice()
      }

      if (interfaceName === "org.bluez.Device1" && changed["Connected"] !== undefined) {
        updateBtDevice()
      }
    },
  )
} catch (e) {
  console.error("Failed to subscribe to BlueZ signals:", e)
}

updateBtPowered()
updateBtDevice()

/* ── Compatibilidad manual refresh ── */

export async function refreshCurrentSsid() {
  updateCurrentSsid()
}
