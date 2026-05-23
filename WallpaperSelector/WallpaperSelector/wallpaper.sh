#!/usr/bin/env bash
# Wallpaper selector
set -euo pipefail

# === Paths y defaults ===
WALLPAPER_DIR="$HOME/Wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-selector"
HISTORY_FILE="$CACHE_DIR/history.tsv"
ROFI_THEME="$HOME/.config/WallpaperSelector/selector.rasi"
ROFI_FONT="${ROFI_WALLPAPER_FONT:-${ROFI_FONT:-JetBrainsMono Nerd Font}}"
#ROFI_FONT="JetBrainsMono Nerd Font"
ROFI_SCALE="${ROFI_WALLPAPER_SCALE:-${ROFI_SCALE:-8}}"
#ROFI_SCALE=8

mkdir -p "$CACHE_DIR/thumbs"

# === Utils ===
die(){ echo "wallpaper.sh: $*" >&2; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }

ensure_deps(){
  for c in hyprctl jq convert rofi awww wal; do
    have "$c" || die "Falta dependencia: $c"
  done
}

# === Miniaturas ===
thumb_sqre(){
  local src="$1" h out
  h="$(printf '%s' "$src" | sha1sum | cut -d' ' -f1)"
  out="$CACHE_DIR/thumbs/${h}.png"

  #  Si ya existe y no está vacío, NO regenerar
  if [[ -s "$out" ]]; then
    printf '%s\n' "$out"
    return
  fi

  mkdir -p "$CACHE_DIR/thumbs"

  case "${src,,}" in
    *.mp4|*.mkv|*.webm)
      ffmpeg -y -loglevel error \
        -ss 00:00:01 -i "$src" \
        -frames:v 1 \
        -vf "scale=960:540:force_original_aspect_ratio=increase,crop=960:540" \
        "$out"
      ;;

    *.gif)
      convert "$src[0]" \
        -thumbnail 960x540^ \
        -gravity center \
        -extent 960x540 \
        "$out"
      ;;

    *)
      convert "$src" \
        -thumbnail 960x540^ \
        -gravity center \
        -extent 960x540 \
        "$out"
      ;;
  esac

  printf '%s\n' "$out"
}

thumb_hd(){
  local src="$1" h out
  h="$(printf '%s' "$src" | sha1sum | cut -d' ' -f1)"
  out="$CACHE_DIR/thumbs/${h}_hd.png"

  if [[ -s "$out" ]]; then
    printf '%s\n' "$out"
    return
  fi

  mkdir -p "$CACHE_DIR/thumbs"

  case "${src,,}" in
    *.mp4|*.mkv|*.webm)
      ffmpeg -y -loglevel error \
        -ss 00:00:01 -i "$src" \
        -frames:v 1 \
        "$out"
      ;;

    *.gif)
      convert "$src[0]" "$out"
      ;;

    *)
      cp "$src" "$out"
      ;;
  esac

  printf '%s\n' "$out"
}

# === Columnas dinamicas (segun resolucion/escala del monitor) ===
calc_cols(){
  local j w s elm_width max_avail
  j="$(hyprctl -j monitors)"
  w="$(jq '.[]
    | select(.focused==true)
    | (if (.transform % 2 == 0) then .width else .height end)' <<<"$j")"
  s="$(jq -r '.[]
    | select(.focused==true) | .scale' <<<"$j" | sed 's/\.//')"
  [[ -n "$w" && -n "$s" ]] || { echo 5; return; }
  w=$(( w * 100 / s ))
  elm_width=$(((24 + 8 + 5) * ROFI_SCALE ))  # 28em icon, +gaps
  max_avail=$(( w - (4 * ROFI_SCALE) ))
  (( max_avail/elm_width > 1 )) && echo $(( max_avail / elm_width )) || echo 2
}

# === Wallpapers ===
collect_walls(){
  find "$WALLPAPER_DIR" -type f -iregex '.*\.\(jpe?g\|png\|webp\|gif\|mp4\|mkv\|webm\)$' | sort
}

# === Registrar uso de Walpapers ===
update_hystory() {
  local wall="$1" now tmp
  now="$(date +%s)"
  mkdir -p "$CACHE_DIR"
  touch "$HISTORY_FILE"

  tmp="$(mktemp)"
  awk -F'\t' -v OFS='\t' -v w="$wall" -v now="$now" '
    BEGIN { found=0 }
    $1 == w {
      $2 = $2 + 1
      $3 = now
      found=1
    }
    { print }
    END {
      if (!found)
        print w, 1, now
    }
  ' "$HISTORY_FILE" > "$tmp"

  mv "$tmp" "$HISTORY_FILE"
}

# === Ordenar dependiendo al uso ===
collect_walls_sorted() {
  touch "$HISTORY_FILE"

  awk -F'\t' '
    NR==FNR {
      freq[$1]=$2
      last[$1]=$3
      next
    }
    {
      f = freq[$0] ? freq[$0] : 0
      l = last[$0] ? last[$0] : 0
      printf "%d\t%d\t%s\n", f, l, $0
    }
  ' "$HISTORY_FILE" <(collect_walls) |
  sort -t $'\t' -k1,1nr -k2,2nr |
  cut -f3-
}


# Estado actual (último wallpaper aplicado)
current_wall(){
  if [[ -L "$CACHE_DIR/wall.set" || -f "$CACHE_DIR/wall.set" ]]; then
    readlink -f "$CACHE_DIR/wall.set" || cat "$CACHE_DIR/wall.set"
  else
    echo ""
  fi
}

current_wall_2(){
  local wall="$1"
  local h
  h="$(printf '%s' "$wall" | sha1sum | cut -d' ' -f1)"
  echo "$CACHE_DIR/thumbs/${h}.png"
}


is_video(){
  case "${1,,}" in
    *.mp4|*.mkv|*.webm) return 0 ;;
    *) return 1 ;;
  esac
}

stop_video_wall(){
  pkill -f mpvpaper || true
}

start_video_wall(){
  local video="$1"
  stop_video_wall

  mpvpaper -f -o "--loop --no-audio --hwdec=auto --profile=low-latency" '*' "$video" &
}


# === Aplicar un wallpaper ===
apply_wall(){
  local wall="$1"
  [[ -f "$wall" ]] || die "Wallpaper inexistente: $wall"

  # Guardar el wallpaper actual ANTES de actualizar
  local prev_wall
  prev_wall="$(current_wall)"

  mkdir -p  "$CACHE_DIR"
  ln -sfn "$wall" "$CACHE_DIR/wall.set"

  # generar preview en background si falta
  thumb_sqre "$wall" >/dev/null &

  ln -sfn "$(current_wall_2 "$wall")" "$CACHE_DIR/wall_set.png"

  update_hystory "$wall"


  if is_video "$wall"; then
    # Asegurar que la miniatura HD del video exista (sincrono)
    local video_thumb
    video_thumb="$(thumb_hd "$wall")"

    if is_video "$prev_wall" && [[ -n "$prev_wall" ]]; then
      # Video → Video: transicion directa via miniatura HD
      stop_video_wall
      awww img "$video_thumb" \
        --transition-duration 0.5 \
        --transition-fps 60 \
        --transition-step 90 \
        --transition-type any
      sleep 0.6
      start_video_wall "$wall"
    else
      # Imagen → Video: primero miniatura HD del video, luego video
      stop_video_wall
      awww img "$video_thumb" \
        --transition-duration 0.8 \
        --transition-fps 60 \
        --transition-step 90 \
        --transition-type any
      sleep 0.9
      start_video_wall "$wall"
    fi

    # Colores desde frame del video
    wal -q -n -s -t -e -i "$video_thumb"

  else
    # Imagen estática
    if is_video "$prev_wall" && [[ -n "$prev_wall" ]]; then
      # Video → Imagen: primero miniatura HD del video anterior, luego imagen final
      local prev_video_thumb
      prev_video_thumb="$(thumb_hd "$prev_wall")"

      stop_video_wall

      # Mostrar miniatura del video anterior como puente (instantaneo)
      awww img "$prev_video_thumb" \
        --transition-duration 0 \
        --transition-fps 60 \
        --transition-step 100 \
        --transition-type any
      sleep 0.15

      # Transicion a la imagen final
      awww img "$wall" \
        --transition-duration 0.8 \
        --transition-fps 60 \
        --transition-step 90 \
        --transition-type any
    else
      # Imagen → Imagen: transicion normal
      stop_video_wall

      pgrep -x awww-daemon >/dev/null 2>&1 || awww-daemon >/dev/null 2>&1 & sleep 0.2
      awww img "$wall" \
        --transition-duration 1 \
        --transition-fps 60 \
        --transition-step 90 \
        --transition-type any
    fi

    wal -q -n -s -t -e -i "$wall"

  fi

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROFI_GRADIENT="$SCRIPT_DIR/rofi-gradient.sh"
  TELA_RECOLOR="$SCRIPT_DIR/tela-recolor.sh"
  STARSHIP_RECOLOR="$SCRIPT_DIR/starship-color.sh"

  if [[ -f "$ROFI_GRADIENT" ]]; then
      bash "$ROFI_GRADIENT"
  fi

  if [[ -f "$TELA_RECOLOR" ]]; then
      bash "$TELA_RECOLOR"
  fi

  if [[ -f "$STARSHIP_RECOLOR" ]]; then
      bash "$STARSHIP_RECOLOR"
  fi


  #hyprctl reload

  # Notificacion(opcional)
  #if have notify-send; then
  #  notify-send -a "HyDE" -i "$(thumb_sqre "$wall")" "Wallpaper aplicado" "$(basename "$wall")"
  #fi
}

# === Rofi selector (grilla con iconos)===
rofi_select_wall(){
  local cols font_override sel
  cols="$(calc_cols)"
  font_override="* {font: \"${ROFI_FONT} ${ROFI_SCALE}\";}"
  collect_walls_sorted | while IFS= read -r p; do
    printf '%s:::%s\x00icon\x1f%s\n' "$(basename "$p")" "$p" "$(thumb_sqre "$p")"
  done | rofi -dmenu \
      -display-column-separator ":::" \
      -display-columns 1 \
      -theme-str "${font_override}" \
      -theme-str "window{width:100%;} listview{columns:${cols};spacing:1em;} element{border-radius:12px;orientation:vertical;} element-text{padding:1em;}" \
      -theme "$ROFI_THEME"
}

# JSON de wallpapers (para integrar con otros scripts)
json_list(){
  local first=1
  echo "["
  collect_walls | while IFS= read -r p; do
    local name theme tdir
    name="$(basename "$p")"
    tdir="$(dirname "$(dirname "$p")")"
    theme="$(basename "$tdir")"
    [[ $first -eq 1 ]] && first=0 || echo ","
    printf '  {"name": "%s", "path": "%s", "theme": "%s"}' \
      "$(printf %s "$name" | sed 's/"/\\"/g')" \
      "$(printf %s "$p" | sed 's/"/\\"/g')" \
      "$(printf %s "$theme" | sed 's/"/\\"/g')"
  done
  echo
  echo "]"
}

# NEXT/PREV sobre lista estable
next_prev(){
  local dir="$1"  # +1 / -1
  mapfile -t arr < <(collect_walls)
  [[ ${#arr[@]} -gt 0 ]] || die "No se encontraron wallpapers"
  local cur idx=-1 i
  cur="$(current_wall)"
  for i in "${!arr[@]}"; do
    [[ "${arr[$i]}" == "$cur" ]] && { idx=$i; break; }
  done
  (( idx == -1 )) && idx=0
  local n=$(( (idx + dir + ${#arr[@]}) % ${#arr[@]} ))
  apply_wall "${arr[$n]}"
}

# RANDOM
random_wall(){
  mapfile -t arr < <(collect_walls)
  [[ ${#arr[@]} -gt 0 ]] || die "No se encontraron wallpapers"
  apply_wall "${arr[$RANDOM % ${#arr[@]}]}"
}

# === CLI ===
ensure_deps

ACTION=""
SET_FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) cat <<EOF
Uso: $(basename "$0") [opciones]
  -j, --json          Lista wallpapers en JSON (STDOUT)
  -S|--select|-SG     Selector con rofi
  -n, --next          Siguiente
  -p, --previous      Anterior
  -r, --random        Aleatorio
  -s, --set <file>    Establecer archivo
EOF
      exit 0;;
    -j|--json) ACTION=json;;
    -S|--select|-SG) ACTION=select;;
    -n|--next) ACTION=next;;
    -p|--previous) ACTION=prev;;
    -r|--random) ACTION=random;;
    -s|--set) shift; SET_FILE="${1:-}"; ACTION=set;;
    *) die "Opción inválida: $1";;
  esac
  shift || true
done

case "${ACTION:-select}" in
  json)    json_list;;
  select)  sel="$(rofi_select_wall)"; [[ -n "$sel" ]] && apply_wall "${sel##*:::}";;
  next)    next_prev 1;;
  prev)    next_prev -1;;
  random)  random_wall;;
  set)     [[ -n "$SET_FILE" ]] || die "Falta archivo para --set"; apply_wall "$(readlink -f "$SET_FILE")";;
esac
