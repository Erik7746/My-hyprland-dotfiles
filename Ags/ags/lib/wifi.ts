import { execAsync } from "ags/process"

export interface Network {
  ssid: string
  active: boolean
  security: boolean
  signal: number
}

/* Cache para evitar re-escaneos constantes */
let cachedNetworks: Network[] = []
let lastScan = 0
const CACHE_TTL_MS = 2000

/** Ejecuta un comando en shell de forma segura (array argv) */
function sh(cmd: string): Promise<string> {
  return execAsync(["sh", "-c", `LC_ALL=C.UTF-8 ${cmd}`])
}

export async function getCurrentSsid(): Promise<string | null> {
  try {
    const out = await sh("nmcli -g SSID -a dev wifi")
    const ssid = out.trim().split("\n")[0]
    return ssid || null
  } catch {
    return null
  }
}

/**
 * Escanea redes Wi-Fi disponibles.
 * @param force  Si es true, fuerza un rescan completo. Si es false, usa cache y evita rescan.
 */
export async function scanNetworks(force = false): Promise<Network[]> {
  const now = Date.now()
  if (!force && now - lastScan < CACHE_TTL_MS) {
    return cachedNetworks
  }

  try {
    const rescanFlag = force ? "" : "--rescan no"
    const out = await sh(
      `nmcli -t -f SSID,ACTIVE,SECURITY,SIGNAL dev wifi list ${rescanFlag}`,
    )
    const lines = out.trim().split("\n")
    const seen = new Set<string>()
    const networks: Network[] = []

    for (const line of lines) {
      const parts = line.split(":")
      if (parts.length < 4) continue
      const ssid = parts[0]
      const active = parts[1] === "yes"
      const security = parts[2] !== ""
      const signal = parseInt(parts[3], 10) || 0

      if (!ssid || seen.has(ssid)) continue
      seen.add(ssid)
      networks.push({ ssid, active, security, signal })
    }

    /* Ordenar: activa primero, luego por señal descendente */
    networks.sort((a, b) => {
      if (a.active && !b.active) return -1
      if (!a.active && b.active) return 1
      return b.signal - a.signal
    })

    cachedNetworks = networks
    lastScan = now
    return networks
  } catch (e) {
    console.error("Failed to scan networks:", e)
    return cachedNetworks
  }
}

export interface KnownNetwork {
  ssid: string
  connectionName: string
}

/** Obtiene las redes Wi-Fi guardadas con su SSID real */
export async function getKnownNetworks(): Promise<KnownNetwork[]> {
  try {
    const out = await sh("nmcli -t -f NAME,TYPE connection show")
    const profiles = out
      .trim()
      .split("\n")
      .map((line) => line.split(":"))
      .filter(([_, type]) => type === "802-11-wireless")
      .map(([name]) => name)

    const networks = await Promise.all(
      profiles.map(async (name) => {
        try {
          const ssidOut = await sh(
            `nmcli -g 802-11-wireless.ssid connection show '${escapeShell(name)}'`,
          )
          const ssid = ssidOut.trim()
          if (!ssid) return null
          return { ssid, connectionName: name }
        } catch {
          return null
        }
      }),
    )

    return networks.filter((n): n is KnownNetwork => n !== null)
  } catch (e) {
    console.error("Failed to get known networks:", e)
    return []
  }
}

/** Devuelve los SSIDs reales de las conexiones guardadas */
export async function getKnownSsids(): Promise<Set<string>> {
  const networks = await getKnownNetworks()
  return new Set(networks.map((n) => n.ssid))
}

/** Busca el nombre del perfil guardado por SSID real */
export async function findConnectionNameBySsid(
  ssid: string,
): Promise<string | null> {
  const networks = await getKnownNetworks()
  return networks.find((n) => n.ssid === ssid)?.connectionName || null
}

/** Olvida (elimina) una red guardada buscando por SSID real */
export async function forgetNetwork(ssid: string) {
  const name = await findConnectionNameBySsid(ssid)
  if (!name) throw new Error(`No saved profile found for ${ssid}`)
  await sh(`nmcli connection delete id '${escapeShell(name)}'`)
}

/** Escapa comillas simples para shell: ' -> '"'"' */
function escapeShell(value: string): string {
  return value.replace(/'/g, "'\"'\"'")
}

export async function connectToNetwork(ssid: string, password?: string) {
  const safeSsid = escapeShell(ssid)
  if (password) {
    const safePwd = escapeShell(password)
    await sh(`nmcli dev wifi connect '${safeSsid}' password '${safePwd}'`)
  } else {
    await sh(`nmcli dev wifi connect '${safeSsid}'`)
  }
}

export async function disconnectNetwork() {
  try {
    const out = await sh("nmcli -t -f DEVICE,TYPE,STATE dev status")
    const device = out
      .trim()
      .split("\n")
      .map((line) => line.split(":"))
      .find(([_, type, state]) => type === "wifi" && state === "connected")?.[0]

    if (!device) return
    await sh(`nmcli dev disconnect '${escapeShell(device)}'`)
  } catch (e) {
    console.error("Failed to disconnect network:", e)
  }
}

export async function setWifiEnabled(enabled: boolean) {
  await sh(`nmcli radio wifi ${enabled ? "on" : "off"}`)
}
