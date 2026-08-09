import { createState } from "gnim"

export const [panelVisible, setPanelVisible] = createState(false)
export const [musicPlayerVisible, setMusicPlayerVisible] = createState(false)

export function toggleControlPanel() {
  setPanelVisible(v => !v)
}

export function toggleMusicPlayer() {
  setMusicPlayerVisible(v => !v)
}
