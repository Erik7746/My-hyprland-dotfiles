import Gio from "gi://Gio"
import GLib from "gi://GLib"

/* ── Configuración ── */

export const CONFIG = {
  barCount: 64,
  baseRadius: 112,
  minBarLength: 1,
  maxBarLength: 52,
  barWidth: 6,
  attackTime: 0.04,
  decayTime: 0.10,
  rotationSpeed: 0,
  gain: 1,
  canvasSize: 340,
}

/* ── Tablas precalculadas ── */

const cosTable = new Float32Array(CONFIG.barCount)
const sinTable = new Float32Array(CONFIG.barCount)

function initTables() {
  for (let i = 0; i < CONFIG.barCount; i++) {
    const angle = (i / CONFIG.barCount) * 2 * Math.PI - Math.PI / 2
    cosTable[i] = Math.cos(angle)
    sinTable[i] = Math.sin(angle)
  }
}
initTables()

export { cosTable, sinTable }

/* ── Estado del espectro ── */

const targetValues = new Float32Array(CONFIG.barCount)
const currentValues = new Float32Array(CONFIG.barCount)

export function getCurrentValues(): Float32Array {
  return currentValues
}

export function updateBars(deltaMs: number) {
  const dt = deltaMs / 1000
  const attack = 1.0 - Math.exp(-dt / CONFIG.attackTime)
  const decay = 1.0 - Math.exp(-dt / CONFIG.decayTime)

  for (let i = 0; i < CONFIG.barCount; i++) {
    const target = targetValues[i] * CONFIG.gain
    const clampedTarget = Math.min(target, 1.0)
    const current = currentValues[i]

    if (clampedTarget > current) {
      currentValues[i] = current + (clampedTarget - current) * attack
    } else {
      currentValues[i] = current + (clampedTarget - current) * decay
    }
  }
}

/* ── Proceso CAVA ── */

let cavaProc: Gio.Subprocess | null = null
let readCancellable: Gio.Cancellable | null = null

const FIFO_PATH = "/tmp/ags-cava.fifo"
const CONFIG_PATH = "/tmp/ags-cava.conf"

function writeCavaConfig() {
  const content = `[general]
bars = ${CONFIG.barCount}
framerate = 60
sensitivity = 100
autosens = 1

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = ${FIFO_PATH}
data_format = binary
bit_format = 8bit
channels = mono
`
  GLib.file_set_contents(CONFIG_PATH, new TextEncoder().encode(content))
}

function openFifo(): Gio.InputStream | null {
  try {
    const file = Gio.File.new_for_path(FIFO_PATH)
    return file.read(null)
  } catch (e) {
    return null
  }
}

function startCava() {
  writeCavaConfig()

  /* Eliminar FIFO anterior si existe, para evitar lectura de datos viejos */
  try {
    const file = Gio.File.new_for_path(FIFO_PATH)
    if (file.query_exists(null)) {
      file.delete(null)
    }
  } catch {
    /* ignorar */
  }

  try {
    cavaProc = Gio.Subprocess.new(
      ["cava", "-p", CONFIG_PATH],
      Gio.SubprocessFlags.NONE,
    )

  } catch (e) {
    console.error("[cava] failed to start:", e)
    return
  }

  /* CAVA crea la FIFO automáticamente. Esperamos a que la abra para escribir. */
  GLib.usleep(800 * 1000)

  let stream: Gio.InputStream | null = null
  const startTime = Date.now()
  while (!stream && Date.now() - startTime < 3000) {
    stream = openFifo()
    if (!stream) {
      GLib.usleep(100 * 1000)
    }
  }

  if (!stream) {
    console.error("[cava] could not open fifo for reading after 3s")
    return
  }

  readCancellable = new Gio.Cancellable()

  function readFrame() {
    if (readCancellable?.is_cancelled()) return

    stream.read_bytes_async(
      CONFIG.barCount,
      GLib.PRIORITY_DEFAULT,
      readCancellable,
      (source, res) => {
        try {
          const bytes = source.read_bytes_finish(res)
          if (!bytes || bytes.get_size() === 0) {
            return
          }

          const data = bytes.get_data()
          const len = Math.min(data.length, CONFIG.barCount)
          let maxVal = 0
          let sum = 0
          for (let i = 0; i < len; i++) {
            const v = data[i] / 255.0
            targetValues[i] = v
            if (v > maxVal) maxVal = v
            sum += v
          }

          readFrame()
        } catch (e) {
          if ((e as any).matches?.(Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED)) {
            return
          }
          console.error("[cava] read error:", e)
        }
      },
    )
  }

  readFrame()
}

export function stopCava() {
  if (readCancellable) {
    readCancellable.cancel()
    readCancellable = null
  }
  if (cavaProc) {
    try {
      cavaProc.send_signal(15) // SIGTERM
    } catch (e) {
      console.error("[cava] failed to stop:", e)
    }
    cavaProc = null
  }
}

/* ── Iniciar ── */
startCava()
