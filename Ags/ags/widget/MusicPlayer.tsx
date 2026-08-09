import { Gtk } from "ags/gtk4"
import { Astal, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import Gsk from "gi://Gsk"
import Graphene from "gi://Graphene"
import Cairo from "gi://cairo"
import { createState, For } from "gnim"
import { musicPlayerVisible } from "../lib/state"
import {
  title,
  artist,
  coverPaintable,
  position,
  length,
  isPlaying,
  onIsPlayingChange,
  onCoverChange,
  playPause,
  next,
  previous,
  seekTo,
  refreshLibrary,
  librarySongs,
  scanMusicLibrary,
  playSong,
  repeatMode,
  toggleRepeatMode,
  type Song,
} from "../lib/music"
import {
  CONFIG as CAVA,
  getCurrentValues,
  updateBars,
  cosTable,
  sinTable,
} from "../lib/cava"

function formatTime(totalSeconds: number): string {
  const m = Math.floor(totalSeconds / 60)
  const s = Math.floor(totalSeconds % 60)
  return `${m}:${s.toString().padStart(2, "0")}`
}

export default function MusicPlayer(gdkmonitor: Gdk.Monitor) {
  const { BOTTOM, RIGHT } = Astal.WindowAnchor
  const [view, setView] = createState<"player" | "library">("player")
  const [searchQuery, setSearchQuery] = createState("")

  function showLibrary() {
    scanMusicLibrary()
    setSearchQuery("")
    setView("library")
  }

  function showPlayer() {
    setView("player")
  }

  function onPlaySong(s: Song) {
    const all = librarySongs()
    const idx = all.findIndex((x: Song) => x.path === s.path)
    if (idx >= 0) playSong(all, idx)
    showPlayer()
  }

  /* Accessor computado: se re-evalúa automáticamente cuando cambia
     searchQuery o librarySongs */
  function filteredSongs(): Song[] {
    const q = searchQuery().toLowerCase().trim()
    const all = librarySongs()
    if (!q) return all
    return all.filter((s: Song) => s.name.toLowerCase().includes(q))
  }

  return (
    <window
      name="music-player"
      class="MusicPlayer"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      keymode={Astal.Keymode.ON_DEMAND}
      anchor={BOTTOM | RIGHT}
      visible={musicPlayerVisible}
      application={app}
      marginBottom={10}
      marginRight={15}
    >
      <box
        class="music-container"
        orientation={Gtk.Orientation.VERTICAL}
        spacing={16}
      >
        {/* Vista Player */}
        <box
          orientation={Gtk.Orientation.VERTICAL}
          spacing={16}
          visible={view.as((v: string) => v === "player")}
        >
          {/* Portada + Espectro circular */}
          <box
            widthRequest={CAVA.canvasSize}
            heightRequest={CAVA.canvasSize}
            halign={Gtk.Align.CENTER}
            valign={Gtk.Align.CENTER}
            $={self => {
              const fixed = new Gtk.Fixed()
              fixed.set_size_request(CAVA.canvasSize, CAVA.canvasSize)
              fixed.set_halign(Gtk.Align.CENTER)
              fixed.set_valign(Gtk.Align.CENTER)

              /* ── DrawingArea (espectro) ── */
              const da = new Gtk.DrawingArea()
              da.set_size_request(CAVA.canvasSize, CAVA.canvasSize)
              da.set_hexpand(true)
              da.set_vexpand(true)

              let tickId: number | null = null
              let lastTime = 0
              const color = { r: 1, g: 1, b: 1, a: 0.6 }

              da.set_draw_func((_area, cr, width, height) => {
                const cx = width / 2
                const cy = height / 2
                const values = getCurrentValues()

                /* Fondo debug 
                cr.setSourceRGBA(1, 0, 0, 0.05)
                cr.rectangle(0, 0, width, height)
                cr.fill() */


                cr.setLineCap(Cairo.LineCap.BUTT)

                /* Glow */
                cr.setLineWidth(CAVA.barWidth + 3)
                cr.setSourceRGBA(color.r, color.g, color.b, color.a * 0.25)
                for (let i = 0; i < CAVA.barCount; i++) {
                  const val = values[i]
                  const barLen = CAVA.minBarLength + val * (CAVA.maxBarLength - CAVA.minBarLength)
                  const x1 = cx + cosTable[i] * CAVA.baseRadius
                  const y1 = cy + sinTable[i] * CAVA.baseRadius
                  const x2 = cx + cosTable[i] * (CAVA.baseRadius + barLen)
                  const y2 = cy + sinTable[i] * (CAVA.baseRadius + barLen)
                  cr.moveTo(x1, y1)
                  cr.lineTo(x2, y2)
                }
                cr.stroke()

                /* Barras */
                cr.setLineWidth(CAVA.barWidth)
                cr.setSourceRGBA(color.r, color.g, color.b, color.a)
                for (let i = 0; i < CAVA.barCount; i++) {
                  const val = values[i]
                  const barLen = CAVA.minBarLength + val * (CAVA.maxBarLength - CAVA.minBarLength)
                  const x1 = cx + cosTable[i] * CAVA.baseRadius
                  const y1 = cy + sinTable[i] * CAVA.baseRadius
                  const x2 = cx + cosTable[i] * (CAVA.baseRadius + barLen)
                  const y2 = cy + sinTable[i] * (CAVA.baseRadius + barLen)
                  cr.moveTo(x1, y1)
                  cr.lineTo(x2, y2)
                }
                cr.stroke()
              })

              function onTick(widget: Gtk.Widget, frameClock: Gdk.FrameClock): boolean {
                const now = frameClock.get_frame_time()
                if (lastTime === 0) lastTime = now
                const deltaMs = (now - lastTime) / 1000
                lastTime = now
                updateBars(deltaMs)
                widget.queue_draw()
                return true
              }

              function startTick() {
                if (tickId !== null) return
                lastTime = 0
                tickId = da.add_tick_callback(onTick)
              }

              function stopTick() {
                if (tickId === null) return
                da.remove_tick_callback(tickId)
                tickId = null
                lastTime = 0
              }

              const unsub1 = onIsPlayingChange((playing: boolean) => {
                if (playing) startTick()
                else stopTick()
              })
              if (isPlaying()) startTick()

              da.connect("destroy", () => {
                stopTick()
                unsub1()
              })

              fixed.put(da, 0, 0)
              da.show()

              /* ── Portada centrada ── */
              const artBox = new Gtk.Box({
                width_request: 220,
                height_request: 220,
                halign: Gtk.Align.CENTER,
                valign: Gtk.Align.CENTER,
                overflow: Gtk.Overflow.HIDDEN,
              })
              artBox.add_css_class("album-art-wrapper")

              const img = new Gtk.Image({
                pixel_size: 220,
                paintable: coverPaintable(),
                hexpand: true,
                vexpand: true,
              })
              img.add_css_class("album-art")

              let imgTickId: number | null = null
              let lastFrameTime = 0
              let accumulatedAngle = 0
              const SPEED = 6
              const SIZE = 220
              const CX = SIZE / 2
              const CY = SIZE / 2

              function onImgTick(widget: Gtk.Widget, frameClock: Gdk.FrameClock): boolean {
                const frameTime = frameClock.get_frame_time()
                if (lastFrameTime === 0) {
                  lastFrameTime = frameTime
                  return true
                }
                const deltaMs = frameTime - lastFrameTime
                lastFrameTime = frameTime

                if (isPlaying()) {
                  const deltaSec = deltaMs / 1_000_000
                  accumulatedAngle = (accumulatedAngle + deltaSec * SPEED) % 360

                  let transform = new Gsk.Transform()
                  transform = transform.translate(new Graphene.Point({ x: CX, y: CY }))
                  transform = transform.rotate(accumulatedAngle)
                  transform = transform.translate(new Graphene.Point({ x: -CX, y: -CY }))

                  widget.allocate(SIZE, SIZE, -1, transform)
                }
                return true
              }

              function startImgTick() {
                if (imgTickId !== null) return
                lastFrameTime = 0
                imgTickId = img.add_tick_callback(onImgTick)
              }

              function stopImgTick() {
                if (imgTickId === null) return
                img.remove_tick_callback(imgTickId)
                imgTickId = null
                lastFrameTime = 0
              }

              const unsub2 = onIsPlayingChange((playing: boolean) => {
                if (playing) startImgTick()
                else stopImgTick()
              })
              if (isPlaying()) startImgTick()

              img.connect("destroy", () => {
                stopImgTick()
                unsub2()
              })

              const unsubCover = onCoverChange((p) => {
                ;(img as any).paintable = p
              })
              img.connect("destroy", () => {
                unsubCover()
              })

              artBox.append(img)
              artBox.show()
              img.show()
              const artX = (CAVA.canvasSize - 220) / 2
              const artY = (CAVA.canvasSize - 220) / 2
              fixed.put(artBox, artX, artY)

              fixed.show()
              self.append(fixed)
            }}
          />

          {/* Info */}
          <box
            orientation={Gtk.Orientation.VERTICAL}
            spacing={4}
            halign={Gtk.Align.CENTER}
          >
            <label class="music-title" label={title} maxWidthChars={20} ellipsize={3} />
            <label class="music-artist" label={artist} maxWidthChars={24} ellipsize={3} />
          </box>

          {/* Slider + tiempos */}
          <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
            <slider
              class="music-slider"
              hexpand
              value={position.as((p: number) =>
                length() > 0 ? p / length() : 0
              )}
              $={self => {
                let debounceId: number | null = null
                self.connect("change-value", (_slider, _scroll, value) => {
                  if (debounceId !== null) {
                    GLib.source_remove(debounceId)
                  }
                  debounceId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 200, () => {
                    const newPos = Math.round(value * length())
                    seekTo(newPos)
                    debounceId = null
                    return GLib.SOURCE_REMOVE
                  })
                  return false
                })
              }}
            />
            <box>
              <label class="music-time" label={position.as(formatTime)} />
              <box hexpand />
              <label class="music-time" label={length.as(formatTime)} />
            </box>
          </box>

          {/* Controles */}
          <box spacing={20} halign={Gtk.Align.CENTER}>
            <button
              class={repeatMode.as((m: number) =>
                m === 0 ? "music-mode-btn" : "music-mode-btn active"
              )}
              onClicked={() => toggleRepeatMode()}
            >
              <image
                iconName={repeatMode.as((m: number) => {
                  switch (m) {
                    case 1: return "media-playlist-shuffle-symbolic"
                    case 2: return "media-playlist-repeat-song-symbolic"
                    default: return "media-playlist-repeat-symbolic"
                  }
                })}
                pixelSize={20}
              />
            </button>
            <button class="music-control-btn" onClicked={() => previous()}>
              <image
                iconName="media-skip-backward-symbolic"
                pixelSize={24}
              />
            </button>
            <button class="music-control-btn play-btn" onClicked={() => playPause()}>
              <image
                iconName={isPlaying.as((v: boolean) =>
                  v ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                )}
                pixelSize={32}
              />
            </button>
            <button class="music-control-btn" onClicked={() => next()}>
              <image
                iconName="media-skip-forward-symbolic"
                pixelSize={24}
              />
            </button>
            <button class="music-control-btn" onClicked={() => showLibrary()}>
              <image
                iconName="view-list-symbolic"
                pixelSize={24}
              />
            </button>
          </box>
        </box>

        {/* Vista Biblioteca */}
        <box
          orientation={Gtk.Orientation.VERTICAL}
          spacing={12}
          visible={view.as((v: string) => v === "library")}
        >
          {/* Header con buscador */}
          <box spacing={8}>
            <button class="music-control-btn" onClicked={() => showPlayer()}>
              <image iconName="go-previous-symbolic" pixelSize={16} />
            </button>
            <entry
              class="music-search-entry"
              hexpand
              placeholderText="Buscar canción..."
              $={self => {
                /* Cada vez que el entry se hace visible, limpiar búsqueda */
                self.connect("map", () => {
                  self.text = ""
                  setSearchQuery("")
                })
                /* Sincroniza widget → estado */
                self.connect("changed", () => {
                  setSearchQuery(self.text)
                })
              }}
            />
            <button
              class="music-refresh-btn"
              onClicked={() => refreshLibrary()}
            >
              <image iconName="view-refresh-symbolic" pixelSize={14} />
            </button>
          </box>

          {/* Lista de canciones */}
          <scrolledwindow vexpand heightRequest={260}>
            <box orientation={Gtk.Orientation.VERTICAL} spacing={4} marginEnd={12}>
              <For each={filteredSongs}>
                {(s: Song) => (
                  <button
                    class="music-song-btn"
                    onClicked={() => onPlaySong(s)}
                  >
                    <box spacing={10}>
                      <image
                        iconName="audio-x-generic-symbolic"
                        pixelSize={16}
                      />
                      <label
                        label={s.name}
                        hexpand
                        halign={Gtk.Align.START}
                        maxWidthChars={40}
                        ellipsize={3}
                      />
                    </box>
                  </button>
                )}
              </For>
            </box>
          </scrolledwindow>
        </box>
      </box>
    </window>
  )
}
