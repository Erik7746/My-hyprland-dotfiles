import { execAsync } from "ags/process"

export function safeExec(cmd: string) {
  execAsync(cmd).catch((err: any) => console.error(err))
}
