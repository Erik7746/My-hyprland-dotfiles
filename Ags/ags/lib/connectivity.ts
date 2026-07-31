import { execAsync } from "ags/process"
import { createPoll, interval } from "ags/time"
import { createState } from "gnim"
import { panelVisible } from "./state"

const SHELL = ["sh", "-c"]

export const wifiEnabled = createPoll("enabled", 3000, async (prev) => {
  if (!panelVisible()) return prev
  try {
    const out = await execAsync([...SHELL, "LC_ALL=C.UTF-8 nmcli radio wifi"])
    return out.trim()
  } catch {
    return prev
  }
})
  .as((v: string) => v === "enabled")

export const btPowered = createPoll("no", 3000, async (prev) => {
  if (!panelVisible()) return prev
  try {
    const out = await execAsync([
      ...SHELL,
      "LC_ALL=C.UTF-8 bluetoothctl show 2>/dev/null | grep Powered | awk '{print $2}'",
    ])
    return out.trim()
  } catch {
    return prev
  }
})
  .as((v: string) => v === "yes")

const [currentSsid, setCurrentSsid] = createState("Sin conexión")
export { currentSsid }

export async function refreshCurrentSsid() {
  try {
    const radioOut = await execAsync([...SHELL, "LC_ALL=C.UTF-8 nmcli radio wifi"])
    if (radioOut.trim() !== "enabled") {
      if (currentSsid() !== "Apagado") setCurrentSsid("Apagado")
      return
    }

    const out = await execAsync([
      ...SHELL,
      "LC_ALL=C.UTF-8 nmcli -t -f SSID,ACTIVE dev wifi list --rescan no",
    ])
    const lines = out.trim().split("\n")
    let ssid: string | null = null

    for (const line of lines) {
      const idx = line.lastIndexOf(":")
      if (idx < 0) continue
      const active = line.slice(idx + 1)
      if (active === "yes") {
        ssid = line.slice(0, idx) || null
        break
      }
    }

    const next = ssid || "Sin conexión"
    if (currentSsid() !== next) setCurrentSsid(next)
  } catch {
    // conservar valor anterior
  }
}

/* Actualiza el SSID mientras el panel esté visible */
interval(3000, () => {
  if (panelVisible()) refreshCurrentSsid()
})

export const currentBtDevice = createPoll("Apagado", 3000, async (prev) => {
  if (!panelVisible()) return prev
  try {
    const out = await execAsync([...SHELL, "LC_ALL=C.UTF-8 bluetoothctl devices Connected"])
    const line = out.trim().split("\n")[0]
    if (!line) return "Apagado"
    const match = line.match(/^Device\s+[\w:]+\s+(.+)$/)
    return match?.[1]?.trim() || "Conectado"
  } catch {
    return prev
  }
})
