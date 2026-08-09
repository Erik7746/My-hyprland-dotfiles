import { createState } from "gnim"
import Gio from "gi://Gio"
import Gdk from "gi://Gdk"
import GdkPixbuf from "gi://GdkPixbuf"
import GLib from "gi://GLib"
import { execAsync } from "ags/process"

/* ── Estados ── */

const [title, setTitle] = createState("Sin reproducción")
const [artist, setArtist] = createState("")
const [coverPaintable, _setCoverPaintableRaw] = createState<Gdk.Paintable | null>(null)
const [position, setPosition] = createState(0)
const [length, setLength] = createState(0)
const [isPlaying, _setIsPlayingRaw] = createState(false)

let _lastIsPlaying = false
const _isPlayingListeners: ((v: boolean) => void)[] = []

export function onIsPlayingChange(cb: (v: boolean) => void) {
  _isPlayingListeners.push(cb)
  return () => {
    const idx = _isPlayingListeners.indexOf(cb)
    if (idx !== -1) _isPlayingListeners.splice(idx, 1)
  }
}

export function setIsPlaying(v: boolean | ((prev: boolean) => boolean)) {
  _setIsPlayingRaw(v)
  const next = isPlaying()
  if (next !== _lastIsPlaying) {
    _lastIsPlaying = next
    for (const listener of _isPlayingListeners) {
      try { listener(next) } catch (e) { console.error(e) }
    }
  }
}

let _lastCover: Gdk.Paintable | null = null
const _coverListeners: ((v: Gdk.Paintable | null) => void)[] = []

export function onCoverChange(cb: (v: Gdk.Paintable | null) => void) {
  _coverListeners.push(cb)
  return () => {
    const idx = _coverListeners.indexOf(cb)
    if (idx !== -1) _coverListeners.splice(idx, 1)
  }
}

export function setCoverPaintable(v: Gdk.Paintable | null | ((prev: Gdk.Paintable | null) => Gdk.Paintable | null)) {
  _setCoverPaintableRaw(v)
  const next = coverPaintable()
  if (next !== _lastCover) {
    _lastCover = next
    for (const listener of _coverListeners) {
      try { listener(next) } catch (e) { console.error(e) }
    }
  }
}

/* 0=Lista, 1=Random, 2=Single */
const [repeatMode, setRepeatMode] = createState(0)
export { repeatMode }

export { title, artist, coverPaintable, position, length, isPlaying }

/* ── Helpers ── */

function unpackVariant(v: any): any {
  if (v === null || v === undefined) return v
  if (typeof v === "object" && v.deep_unpack !== undefined) {
    return v.deep_unpack()
  }
  return v
}

function getMprisProperty(player: string, property: string): any {
  const proxy = Gio.DBusProxy.new_for_bus_sync(
    Gio.BusType.SESSION,
    Gio.DBusProxyFlags.NONE,
    null,
    player,
    "/org/mpris/MediaPlayer2",
    "org.freedesktop.DBus.Properties",
    null,
  )
  const result = proxy.call_sync(
    "Get",
    GLib.Variant.new("(ss)", ["org.mpris.MediaPlayer2.Player", property]),
    Gio.DBusCallFlags.NONE,
    -1,
    null,
  )
  return unpackVariant(result.deep_unpack()[0])
}

function callMprisMethod(player: string, method: string, params?: GLib.Variant) {
  const proxy = Gio.DBusProxy.new_for_bus_sync(
    Gio.BusType.SESSION,
    Gio.DBusProxyFlags.NONE,
    null,
    player,
    "/org/mpris/MediaPlayer2",
    "org.mpris.MediaPlayer2.Player",
    null,
  )
  proxy.call_sync(
    method,
    params || null,
    Gio.DBusCallFlags.NONE,
    -1,
    null,
  )
}

/* ── Detección de reproductor ── */

let currentPlayer: string | null = null

function findMprisPlayer(): string | null {
  try {
    const proxy = Gio.DBusProxy.new_for_bus_sync(
      Gio.BusType.SESSION,
      Gio.DBusProxyFlags.NONE,
      null,
      "org.freedesktop.DBus",
      "/org/freedesktop/DBus",
      "org.freedesktop.DBus",
      null,
    )
    const result = proxy.call_sync(
      "ListNames",
      null,
      Gio.DBusCallFlags.NONE,
      -1,
      null,
    )
    const names: string[] = unpackVariant(result.deep_unpack()[0])
    for (const name of names) {
      if (name.startsWith("org.mpris.MediaPlayer2.")) {
        return name
      }
    }
  } catch (e) {
    console.error("findMprisPlayer error:", e)
  }
  return null
}

function ensurePlayer(): string | null {
  if (!currentPlayer) {
    currentPlayer = findMprisPlayer()
  }
  return currentPlayer
}

/* ── Actualizaciones ── */

function updateMetadata(player: string) {
  try {
    const metadata = getMprisProperty(player, "Metadata") as Record<string, any>

    const titleVar = metadata?.["xesam:title"]
    const newTitle = titleVar ? String(unpackVariant(titleVar)) : ""

    /* Si no hay título real, es metadata vacía intermedia —
       no tocar title, artist ni cover para evitar flash visual */
    if (!newTitle) return

    if (title() !== newTitle) setTitle(newTitle)

    const artistVar = metadata?.["xesam:artist"]
    let newArtist = ""
    if (artistVar) {
      const unpacked = unpackVariant(artistVar)
      if (Array.isArray(unpacked)) {
        newArtist = unpacked.map((a: any) => String(unpackVariant(a))).join(", ")
      } else {
        newArtist = String(unpacked)
      }
    }
    if (artist() !== newArtist) setArtist(newArtist)

    const artVar = metadata?.["mpris:artUrl"]
    const mprisArt = artVar ? String(unpackVariant(artVar)) : ""

    if (mprisArt && mprisArt.startsWith("file://")) {
      const path = decodeURIComponent(mprisArt.slice(7))
      loadCoverPaintable(path)
    } else {
      extractCoverFromMpd().catch(() => {})
    }

    const lengthVar = metadata?.["mpris:length"]
    const newLength = lengthVar ? Math.round(Number(unpackVariant(lengthVar)) / 1000000) : 0
    if (length() !== newLength) setLength(newLength)
  } catch (e) {
    console.error("updateMetadata error:", e)
  }
}

function loadCoverPaintable(path: string) {
  try {
    const original = GdkPixbuf.Pixbuf.new_from_file(path)
    if (!original) {
      setCoverPaintable(null)
      return
    }

    const origW = original.width
    const origH = original.height
    const size = Math.min(origW, origH)
    const offsetX = Math.floor((origW - size) / 2)
    const offsetY = Math.floor((origH - size) / 2)

    const cropped = original.new_subpixbuf(offsetX, offsetY, size, size)
    const scaled = cropped.scale_simple(120, 120, GdkPixbuf.InterpType.BILINEAR)

    if (scaled) {
      const texture = Gdk.Texture.new_for_pixbuf(scaled)
      if (texture) {
        setCoverPaintable(texture)
        return
      }
    }
  } catch {
    // fallthrough
  }
  setCoverPaintable(null)
}

async function extractCoverFromMpd() {
  try {
    const relativePath = await execAsync(
      "mpc -h /home/erik/.config/mpd/socket -f '%file%' current",
    )
    const cleanPath = relativePath.trim()
    if (!cleanPath) {
      setCoverPaintable(null)
      return
    }

    const fullPath = GLib.build_filenamev(["/home/erik/Música", cleanPath])
    const coverPath = "/tmp/ags-album-art.jpg"

    await execAsync(
      `ffmpeg -nostdin -i "${fullPath}" -an -vcodec copy "${coverPath}" -y 2>/dev/null`,
    )

    const file = Gio.File.new_for_path(coverPath)
    if (file.query_exists(null)) {
      const info = file.query_info("standard::size", Gio.FileQueryInfoFlags.NONE, null)
      if (info && info.get_size() > 0) {
        loadCoverPaintable(coverPath)
        return
      }
    }
    setCoverPaintable(null)
  } catch {
    setCoverPaintable(null)
  }
}

function updatePosition(player: string) {
  try {
    const pos = getMprisProperty(player, "Position")
    const posSec = Math.round(Number(pos) / 1000000)
    if (position() !== posSec) setPosition(posSec)
  } catch (e) {
    console.error("updatePosition error:", e)
  }
}

/* ── Timer de posición ── */

let positionTimerId: number | null = null

function startPositionTimer(player: string) {
  if (positionTimerId !== null) return
  positionTimerId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT_IDLE, 1, () => {
    if (!isPlaying()) {
      stopPositionTimer()
      return GLib.SOURCE_REMOVE
    }
    updatePosition(player)
    return GLib.SOURCE_CONTINUE
  })
}

function stopPositionTimer() {
  if (positionTimerId !== null) {
    GLib.source_remove(positionTimerId)
    positionTimerId = null
  }
}

/* ── Watcher D-Bus ── */

function handlePropertiesChanged(player: string, _iface: string, changed: Record<string, any>) {
  if (changed["Metadata"] !== undefined) {
    updateMetadata(player)
  }

  if (changed["PlaybackStatus"] !== undefined) {
    const status = String(unpackVariant(changed["PlaybackStatus"]))
    const playing = status === "Playing"
    if (isPlaying() !== playing) {
      setIsPlaying(playing)
    }
    if (playing) {
      updatePosition(player)
      startPositionTimer(player)
    } else {
      stopPositionTimer()
      updatePosition(player)
    }
  }

  if (changed["Position"] !== undefined) {
    updatePosition(player)
  }
}

function startMprisWatcher() {
  currentPlayer = findMprisPlayer()
  if (!currentPlayer) {
    console.log("No MPRIS player found")
    return
  }

  /* Escuchar cambios de propiedades del reproductor actual */
  Gio.DBus.session.signal_subscribe(
    currentPlayer,
    "org.freedesktop.DBus.Properties",
    "PropertiesChanged",
    "/org/mpris/MediaPlayer2",
    null,
    Gio.DBusSignalFlags.NONE,
    (_conn: any, _sender: string, _path: string, _iface: string, _signal: string, params: any) => {
      const [interfaceName, changed] = params.deep_unpack()
      if (interfaceName !== "org.mpris.MediaPlayer2.Player") return
      handlePropertiesChanged(currentPlayer!, interfaceName, changed)
    },
  )

  /* Detectar cuando aparece un nuevo reproductor */
  Gio.DBus.session.signal_subscribe(
    "org.freedesktop.DBus",
    "org.freedesktop.DBus",
    "NameOwnerChanged",
    "/org/freedesktop/DBus",
    null,
    Gio.DBusSignalFlags.NONE,
    (_conn: any, _sender: string, _path: string, _iface: string, _signal: string, params: any) => {
      const [name] = params.deep_unpack()
      const playerName = String(unpackVariant(name))
      if (playerName.startsWith("org.mpris.MediaPlayer2.")) {
        currentPlayer = playerName
        updateMetadata(currentPlayer)
        const status = getMprisProperty(currentPlayer, "PlaybackStatus")
        const playing = String(status) === "Playing"
        setIsPlaying(playing)
        updatePosition(currentPlayer)
        if (playing) startPositionTimer(currentPlayer)
        else stopPositionTimer()
      }
    },
  )

  /* Estado inicial */
  updateMetadata(currentPlayer)
  const status = getMprisProperty(currentPlayer, "PlaybackStatus")
  const playing = String(status) === "Playing"
  setIsPlaying(playing)
  updatePosition(currentPlayer)
  if (playing) startPositionTimer(currentPlayer)

  /* Asegura modo Lista al iniciar */
  applyRepeatMode(0).catch(() => {})
}

startMprisWatcher()

/* ── Controles ── */

export function playPause() {
  const player = ensurePlayer()
  if (!player) return
  callMprisMethod(player, "PlayPause")
}

export function next() {
  const player = ensurePlayer()
  if (!player) return
  callMprisMethod(player, "Next")
}

export function previous() {
  const player = ensurePlayer()
  if (!player) return
  callMprisMethod(player, "Previous")
}

export function seekTo(seconds: number) {
  const player = ensurePlayer()
  if (!player) return

  try {
    const metadata = getMprisProperty(player, "Metadata") as Record<string, any>
    const trackIdVar = metadata?.["mpris:trackid"]
    const trackId = trackIdVar ? String(unpackVariant(trackIdVar)) : "/org/mpris/MediaPlayer2/TrackList/NoTrack"

    callMprisMethod(
      player,
      "SetPosition",
      GLib.Variant.new("(ox)", [trackId, seconds * 1000000]),
    )
  } catch {
    /* Fallback a mpc seek para MPD/mpDris2 */
    execAsync(`mpc -h /home/erik/.config/mpd/socket seek ${Math.round(seconds)}`).catch(() => {})
  }
}

/* ── Biblioteca ── */

export interface Song {
  name: string
  path: string
  mtime: number
}

const [librarySongs, setLibrarySongs] = createState<Song[]>([])
export { librarySongs }

const AUDIO_EXTS = new Set([".mp3", ".flac", ".ogg", ".wav", ".m4a", ".opus", ".wma", ".aac"])

function isAudioFile(name: string): boolean {
  const lower = name.toLowerCase()
  for (const ext of AUDIO_EXTS) {
    if (lower.endsWith(ext)) return true
  }
  return false
}

export function scanMusicLibrary() {
  try {
    const dir = Gio.File.new_for_path("/home/erik/Música")
    if (!dir.query_exists(null)) {
      setLibrarySongs([])
      return
    }

    const enumerator = dir.enumerate_children(
      "standard::name,standard::type,time::modified",
      Gio.FileQueryInfoFlags.NONE,
      null,
    )

    const songs: Song[] = []
    let info: Gio.FileInfo | null = null
    while ((info = enumerator.next_file(null)) !== null) {
      const name = info.get_name()
      const type = info.get_file_type()
      if (type === Gio.FileType.REGULAR && isAudioFile(name)) {
        const mtime = info.get_modification_date_time()?.to_unix() || 0
        songs.push({ name, path: "/home/erik/Música/" + name, mtime })
      }
    }

    /* Ordenar por fecha de modificación descendente (más reciente primero) */
    songs.sort((a, b) => b.mtime - a.mtime)
    setLibrarySongs(songs)
  } catch (e) {
    console.error("scanMusicLibrary error:", e)
    setLibrarySongs([])
  }
}

/** Escapa comillas simples para shell: ' -> '"'"' */
function escapeShell(value: string): string {
  return value.replace(/'/g, "'\"'\"'")
}

const MPC = "mpc -h /home/erik/.config/mpd/socket"

/**
 * Reconstruye la playlist completa en el orden dado y
 * empieza a reproducir desde startIndex (0-based).
 */
export async function playSong(songs: Song[], startIndex: number) {
  try {
    /* Limpia y reconstruye la playlist en orden */
    await execAsync(`${MPC} clear`)

    for (const s of songs) {
      const safe = escapeShell(s.path)
      await execAsync(["sh", "-c", `${MPC} add '${safe}'`])
    }

    /* Reproduce desde la posición seleccionada (MPD es 1-based) */
    const pos = startIndex + 1
    await execAsync(`${MPC} play ${pos}`)

    /* Asegura que el modo activo se aplique a la nueva playlist */
    applyRepeatMode(repeatMode())
  } catch (e) {
    console.error("playSong error:", e)
  }
}

/** Escanear, reconstruir la playlist y preservar la canción actual */
export async function refreshLibrary() {
  try {
    /* 1. Guardar estado actual */
    let currentFile = ""
    let currentTime = 0
    try {
      const fileOut = await execAsync(`${MPC} -f '%file%' current`)
      currentFile = fileOut.trim()

      /* mpc status retorna tiempo transcurrido en formato "0:06/2:56 (3%)" */
      const statusOut = await execAsync(`${MPC} status`)
      const match = statusOut.match(/\s+(\d+):(\d+)\//)
      if (match) {
        currentTime = parseInt(match[1], 10) * 60 + parseInt(match[2], 10)
      }
    } catch {
      // Si no hay reproducción activa, currentFile queda vacío
    }

    /* 2. Rescanear biblioteca */
    scanMusicLibrary()

    let songs = librarySongs()
    if (songs.length === 0) {
      await execAsync(`${MPC} clear`)
      return
    }

    /* 3. Reconstruir playlist */
    await execAsync(`${MPC} clear`)
    for (const s of songs) {
      const safe = escapeShell(s.path)
      await execAsync(["sh", "-c", `${MPC} add '${safe}'`])
    }

    /* 4. Encontrar la nueva posición de la canción actual */
    let startPos = 0
    if (currentFile) {
      const idx = songs.findIndex((s: Song) => s.path.endsWith(currentFile) || currentFile.endsWith(s.name))
      if (idx >= 0) startPos = idx
    }

    /* 5. Reproducir desde la posición preservada */
    await execAsync(`${MPC} play ${startPos + 1}`)
    if (currentTime > 0) {
      await execAsync(`${MPC} seek ${currentTime}`)
    }

    /* 6. Aplicar modo activo */
    applyRepeatMode(repeatMode())
  } catch (e) {
    console.error("refreshLibrary error:", e)
  }
}

/* ── Modos de reproducción ── */

async function applyRepeatMode(mode: number) {
  switch (mode) {
    case 0: /* Lista (orden por fecha + bucle) */
      await execAsync(`${MPC} random off`)
      await execAsync(`${MPC} repeat on`)
      await execAsync(`${MPC} single off`)
      break
    case 1: /* Random */
      await execAsync(`${MPC} random on`)
      await execAsync(`${MPC} repeat on`)
      await execAsync(`${MPC} single off`)
      break
    case 2: /* Single */
      await execAsync(`${MPC} random off`)
      await execAsync(`${MPC} repeat on`)
      await execAsync(`${MPC} single on`)
      break
  }
}

export async function toggleRepeatMode() {
  try {
    const next = (repeatMode() + 1) % 3
    setRepeatMode(next)
    await applyRepeatMode(next)
  } catch (e) {
    console.error("toggleRepeatMode error:", e)
  }
}
