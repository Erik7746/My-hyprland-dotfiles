import { execAsync } from "ags/process"

export interface BtDevice {
  mac: string
  name: string
  connected: boolean
  paired: boolean
  trusted: boolean
}

/** Ejecuta comando en shell de forma segura */
function sh(cmd: string): Promise<string> {
  return execAsync(["sh", "-c", `LC_ALL=C.UTF-8 ${cmd}`])
}

/** Obtiene dispositivos Bluetooth conocidos */
export async function getKnownDevices(): Promise<BtDevice[]> {
  try {
    const out = await sh("bluetoothctl devices")
    const lines = out.trim().split("\n")
    const matches = lines
      .map((line) => line.match(/^Device\s+([\w:]+)\s+(.+)$/))
      .filter((m): m is RegExpMatchArray => m !== null)
      .filter((m) => m[1] && m[2]?.trim())

    const infos = await Promise.all(
      matches.map((m) =>
        getDeviceInfo(m[1]).catch(() => ({
          connected: false,
          paired: false,
          trusted: false,
        })),
      ),
    )

    return matches.map((m, i) => ({
      mac: m[1],
      name: m[2].trim(),
      connected: infos[i].connected,
      paired: infos[i].paired,
      trusted: infos[i].trusted,
    }))
  } catch (e) {
    console.error("Failed to get known devices:", e)
    return []
  }
}

/** Obtiene info detallada de un dispositivo */
async function getDeviceInfo(mac: string): Promise<{ connected: boolean; paired: boolean; trusted: boolean }> {
  try {
    const out = await sh(`bluetoothctl info ${mac}`)
    return {
      connected: out.includes("Connected: yes"),
      paired: out.includes("Paired: yes"),
      trusted: out.includes("Trusted: yes"),
    }
  } catch {
    return { connected: false, paired: false, trusted: false }
  }
}

/** Escanea dispositivos nuevos */
export async function scanDevices(scanDuration = 8): Promise<BtDevice[]> {
  try {
    /* Primero obtenemos los conocidos */
    const known = await getKnownDevices()
    const knownMacs = new Set(known.map(d => d.mac))

    /* Escanear durante N segundos */
    await sh(`bluetoothctl --timeout ${scanDuration} scan on`)

    /* Obtener todos los dispositivos visibles ahora */
    const out = await sh("bluetoothctl devices")
    const lines = out.trim().split("\n")
    const matches = lines
      .map((line) => line.match(/^Device\s+([\w:]+)\s+(.+)$/))
      .filter((m): m is RegExpMatchArray => m !== null)
      .filter((m) => m[1] && m[2]?.trim() && !knownMacs.has(m[1]))

    const infos = await Promise.all(
      matches.map((m) =>
        getDeviceInfo(m[1]).catch(() => ({
          connected: false,
          paired: false,
          trusted: false,
        })),
      ),
    )

    const devices: BtDevice[] = []
    for (let i = 0; i < matches.length; i++) {
      const mac = matches[i][1]
      const name = matches[i][2].trim()
      const info = infos[i]
      if (!info.paired) {
        devices.push({ mac, name, connected: info.connected, paired: false, trusted: info.trusted })
      }
    }

    return devices
  } catch (e) {
    console.error("Failed to scan devices:", e)
    return []
  }
}

export async function connectDevice(mac: string) {
  await sh(`bluetoothctl connect ${mac}`)
}

export async function disconnectDevice(mac: string) {
  await sh(`bluetoothctl disconnect ${mac}`)
}

export async function pairDevice(mac: string) {
  await sh(`bluetoothctl pair ${mac}`)
}

export async function trustDevice(mac: string) {
  await sh(`bluetoothctl trust ${mac}`)
}

export async function removeDevice(mac: string) {
  await sh(`bluetoothctl remove ${mac}`)
}

export async function setBluetoothEnabled(enabled: boolean) {
  await sh(`bluetoothctl power ${enabled ? "on" : "off"}`)
}
