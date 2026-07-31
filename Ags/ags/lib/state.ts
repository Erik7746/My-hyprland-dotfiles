import { createState } from "gnim"

export const [panelVisible, setPanelVisible] = createState(false)

export function toggleControlPanel() {
  setPanelVisible(v => !v)
}
