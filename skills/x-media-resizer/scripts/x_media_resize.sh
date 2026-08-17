#!/usr/bin/env bash
set -euo pipefail

# X Media Resizer
# - Images: auto-orient + resize + (try) keep under max size
# - Videos/GIF: transcode to H.264/AAC MP4, resize, (optionally) trim to max seconds, faststart
#
# Dependencies: ffmpeg, ffprobe, imagemagick (magick/identify)

usage() {
  cat <<'EOF'
Usage:
  bash scripts/x_media_resize.sh [options] [files...]

If no files are provided:
  - prefer ./attachments if exists
  - else scan current directory recursively for common media extensions

Options:
  --preset auto|landscape|portrait|square|wide-card
  --strategy pad|crop|fit
  --out-dir DIR                (default: dist/x)
  --max-image-mb N             (default: 5)
  --max-video-sec N            (default: 140)
  --no-trim                    disable video trimming to max seconds
  --dry-run                    show what would run
  -h, --help

Presets:
  auto      : choose by orientation/aspect
  landscape : image 1200x675, video 1280x720
  portrait  : image 1080x1350, video 720x1280
  square    : image 1200x1200, video 720x720
  wide-card : image 1200x628  (1.91:1), video 1280x720

Strategy:
  pad  : keep aspect ratio, pad to exact target size (default)
  crop : center-crop to exact target size
  fit  : resize to fit within target size (no pad/crop, output size may be smaller)

EOF
}

die() { echo "Error: $*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

# Find ImageMagick entrypoint
im_cmd() {
  if command -v magick >/dev/null 2>&1; then
    echo "magick"
  elif command -v convert >/dev/null 2>&1; then
    echo "convert"
  else
    die "ImageMagick not found (need magick or convert)."
  fi
}

# ---------- defaults ----------
PRESET="auto"
STRATEGY="pad"
OUT_DIR="dist/x"
MAX_IMAGE_MB=5
MAX_VIDEO_SEC=140
DO_TRIM=1
DRY_RUN=0

# ---------- parse args ----------
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --preset) PRESET="${2:-}"; shift 2;;
    --strategy) STRATEGY="${2:-}"; shift 2;;
    --out-dir) OUT_DIR="${2:-}"; shift 2;;
    --max-image-mb) MAX_IMAGE_MB="${2:-}"; shift 2;;
    --max-video-sec) MAX_VIDEO_SEC="${2:-}"; shift 2;;
    --no-trim) DO_TRIM=0; shift;;
    --dry-run) DRY_RUN=1; shift;;
    -h|--help) usage; exit 0;;
    *) ARGS+=("$1"); shift;;
  esac
done

case "$PRESET" in
  auto|landscape|portrait|square|wide-card) ;;
  *) die "Invalid --preset: $PRESET";;
esac

case "$STRATEGY" in
  pad|crop|fit) ;;
  *) die "Invalid --strategy: $STRATEGY";;
esac

need_cmd ffmpeg
need_cmd ffprobe
need_cmd identify
IM="$(im_cmd)"

mkdir -p "$OUT_DIR"

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "+ $*"
  else
    eval "$@"
  fi
}

bytes_from_mb() {
  awk -v mb="$1" 'BEGIN { printf "%.0f", mb * 1000 * 1000 }'
}

file_size_bytes() {
  if stat -f%z "$1" >/dev/null 2>&1; then
    stat -f%z "$1"   # macOS
  else
    stat -c%s "$1"   # Linux
  fi
}

ext_lower() {
  local f="$1"
  local e="${f##*.}"
  echo "${e,,}"
}

basename_noext() {
  local f="$1"
  local b
  b="$(basename "$f")"
  echo "${b%.*}"
}

# ---------- preset helpers ----------
img_target_wh() {
  local preset="$1"
  case "$preset" in
    landscape) echo "1200 675";;
    portrait) echo "1080 1350";;
    square) echo "1200 1200";;
    wide-card) echo "1200 628";;
    auto) die "img_target_wh should not be called with preset=auto";;
  esac
}

vid_target_wh() {
  local preset="$1"
  case "$preset" in
    landscape|wide-card) echo "1280 720";;
    portrait) echo "720 1280";;
    square) echo "720 720";;
    auto) die "vid_target_wh should not be called with preset=auto";;
  esac
}

choose_preset_auto_image() {
  local w="$1" h="$2"
  awk -v w="$w" -v h="$h" 'BEGIN {
    ar = w / h;
    if (ar >= 0.9 && ar <= 1.1) { print "square"; exit }
    if (h > w) { print "portrait"; exit }
    print "landscape";
  }'
}

choose_preset_auto_video() {
  local w="$1" h="$2"
  if [[ "$h" -gt "$w" ]]; then
    echo "portrait"
  elif [[ "$w" -eq "$h" ]]; then
    echo "square"
  else
    echo "landscape"
  fi
}

# ---------- image processing ----------
has_alpha() {
  local f="$1"
  local ch
  ch="$(identify -format "%[channels]" "$f" 2>/dev/null || echo "")"
  [[ "$ch" == *"a"* ]]
}

resize_image() {
  local in="$1"
  local base out preset w h
  base="$(basename_noext "$in")"

  local iw ih
  iw="$(identify -format "%w" "$in")"
  ih="$(identify -format "%h" "$in")"

  if [[ "$PRESET" == "auto" ]]; then
    preset="$(choose_preset_auto_image "$iw" "$ih")"
  else
    preset="$PRESET"
  fi

  read -r w h < <(img_target_wh "$preset")

  local out_ext out_tmp
  if has_alpha "$in"; then
    out_ext="png"
  else
    out_ext="jpg"
  fi

  out="${OUT_DIR}/${base}__x_${preset}.${out_ext}"
  out_tmp="${out}.tmp"

  local common="-auto-orient -strip"
  local geom="${w}x${h}"

  local cmd=""
  if [[ "$out_ext" == "jpg" ]]; then
    case "$STRATEGY" in
      pad)
        cmd="$IM \"$in\" $common -resize ${geom} -background white -gravity center -extent ${geom} -quality 92 \"$out_tmp\""
        ;;
      crop)
        cmd="$IM \"$in\" $common -resize ${geom}^ -gravity center -extent ${geom} -quality 92 \"$out_tmp\""
        ;;
      fit)
        cmd="$IM \"$in\" $common -resize ${geom}\> -quality 92 \"$out_tmp\""
        ;;
    esac
  else
    case "$STRATEGY" in
      pad)
        cmd="$IM \"$in\" $common -resize ${geom} -background none -gravity center -extent ${geom} \"$out_tmp\""
        ;;
      crop)
        cmd="$IM \"$in\" $common -resize ${geom}^ -gravity center -extent ${geom} \"$out_tmp\""
        ;;
      fit)
        cmd="$IM \"$in\" $common -resize ${geom}\> \"$out_tmp\""
        ;;
    esac
  fi

  run "$cmd"

  local max_bytes
  max_bytes="$(bytes_from_mb "$MAX_IMAGE_MB")"

  if [[ "$out_ext" == "jpg" && "$DRY_RUN" -eq 0 ]]; then
    local q=92
    while :; do
      local sz
      sz="$(file_size_bytes "$out_tmp")"
      if [[ "$sz" -le "$max_bytes" ]]; then
        break
      fi
      q=$((q - 7))
      if [[ "$q" -lt 45 ]]; then
        break
      fi
      run "$IM \"$in\" $common -resize ${geom} $( [[ "$STRATEGY" == "crop" ]] && echo '^' ) -background white -gravity center $( [[ "$STRATEGY" == "fit" ]] && echo "" || echo "-extent ${geom}" ) -quality ${q} \"$out_tmp\""
    done
  fi

  if [[ "$DRY_RUN" -eq 0 ]]; then
    mv -f "$out_tmp" "$out"
  else
    echo "+ mv -f \"$out_tmp\" \"$out\""
  fi

  echo "IMAGE  -> $out"
}

# ---------- video processing ----------
video_duration_sec() {
  local in="$1"
  ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$in" 2>/dev/null | awk '{printf "%.3f", $1}'
}

video_stream_wh() {
  local in="$1"
  ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=' ' "$in" 2>/dev/null
}

transcode_video() {
  local in="$1"
  local base out preset w h
  base="$(basename_noext "$in")"

  local vw vh
  read -r vw vh < <(video_stream_wh "$in")
  [[ -n "${vw:-}" && -n "${vh:-}" ]] || die "Cannot detect video size: $in"

  if [[ "$PRESET" == "auto" ]]; then
    preset="$(choose_preset_auto_video "$vw" "$vh")"
  else
    preset="$PRESET"
  fi
  read -r w h < <(vid_target_wh "$preset")

  out="${OUT_DIR}/${base}__x_${preset}.mp4"

  local dur
  dur="$(video_duration_sec "$in")"

  local trim_args=()
  if [[ "$DO_TRIM" -eq 1 ]]; then
    awk -v d="$dur" -v m="$MAX_VIDEO_SEC" 'BEGIN{ exit !(d > m) }' && trim_args=(-t "$MAX_VIDEO_SEC")
  fi

  local vf=""
  case "$STRATEGY" in
    pad)
      vf="scale=${w}:${h}:force_original_aspect_ratio=decrease,pad=${w}:${h}:(ow-iw)/2:(oh-ih)/2,format=yuv420p"
      ;;
    crop)
      vf="scale=${w}:${h}:force_original_aspect_ratio=increase,crop=${w}:${h},format=yuv420p"
      ;;
    fit)
      vf="scale=${w}:${h}:force_original_aspect_ratio=decrease,format=yuv420p"
      ;;
  esac

  local cmd=(
    ffmpeg -y -i "$in"
    "${trim_args[@]}"
    -vf "$vf"
    -c:v libx264 -profile:v high -level 4.1 -preset medium -crf 23
    -maxrate 6M -bufsize 12M
    -c:a aac -b:a 128k -ac 2
    -movflags +faststart
    "$out"
  )

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '+ %q ' "${cmd[@]}"; echo
  else
    "${cmd[@]}" >/dev/null
  fi

  echo "VIDEO  -> $out"
}

# ---------- classify & dispatch ----------
is_image_ext() {
  case "$1" in
    jpg|jpeg|png|webp|bmp|tif|tiff) return 0;;
    *) return 1;;
  esac
}

is_video_ext() {
  case "$1" in
    mp4|mov|m4v|mkv|webm|avi|flv|wmv) return 0;;
    *) return 1;;
  esac
}

is_gif_ext() { [[ "$1" == "gif" ]]; }

gather_inputs() {
  if [[ "${#ARGS[@]}" -gt 0 ]]; then
    printf '%s\0' "${ARGS[@]}"
    return
  fi

  local root="."
  if [[ -d "./attachments" ]]; then
    root="./attachments"
  fi

  find "$root" -type f \( \
    -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.tif" -o -iname "*.tiff" \
    -o -iname "*.mp4" -o -iname "*.mov" -o -iname "*.m4v" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.avi" \
    -o -iname "*.gif" \
  \) -print0
}

main() {
  local any=0
  while IFS= read -r -d '' f; do
    any=1
    if [[ ! -f "$f" ]]; then
      continue
    fi

    local e
    e="$(ext_lower "$f")"

    if is_image_ext "$e"; then
      resize_image "$f"
    elif is_video_ext "$e" || is_gif_ext "$e"; then
      transcode_video "$f"
    else
      echo "SKIP   -> $f"
    fi
  done < <(gather_inputs)

  if [[ "$any" -eq 0 ]]; then
    echo "No media files found."
    exit 0
  fi

  echo "Done. Outputs are in: $OUT_DIR"
}

main
