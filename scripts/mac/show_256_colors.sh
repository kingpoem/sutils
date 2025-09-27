#!/usr/bin/env bash
# ===============================================
# Script: show_256_colors.sh
# Description:
#   Display 256-color examples in the terminal.
#   Shows background color blocks and foreground samples.
#
# Usage:
#   ./show_256_colors.sh                     # Display all colors
#   ./show_256_colors.sh --fg-only           # Show only foreground samples
#   ./show_256_colors.sh --bg-only           # Show only background blocks
#
# Options:
#   --fg-only       Display foreground color samples only
#   --bg-only       Display background color blocks only
#   -h, --help      Show this help message
#
# 中文说明:
#   显示终端 256 色示例，包括背景色方块和前景色数字
#   --fg-only       仅显示前景色样例
#   --bg-only       仅显示背景色方块
#   -h, --help      显示帮助信息
# ===============================================

HELP=$(cat <<'EOF'
Usage: show_256_colors.sh [options]

English:
  --fg-only       Display foreground color samples only
  --bg-only       Display background color blocks only
  -h, --help      Show this help message

中文:
  --fg-only       仅显示前景色样例
  --bg-only       仅显示背景色方块
  -h, --help      显示帮助信息
EOF
)

# 默认显示模式
SHOW_FG=1
SHOW_BG=1

# 解析参数
for arg in "$@"; do
    case $arg in
        --fg-only)
            SHOW_BG=0
            ;;
        --bg-only)
            SHOW_FG=0
            ;;
        -h|--help)
            echo "$HELP"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "$HELP"
            exit 1
            ;;
    esac
done

set -eu

# 检测是否支持 256 色（best-effort）
supports_256() {
  if command -v tput >/dev/null 2>&1; then
    cols=$(tput colors 2>/dev/null || echo 0)
    if [ "${cols:-0}" -ge 256 ]; then
      return 0
    fi
  fi
  case "${TERM:-}" in
    *256color*) return 0 ;;
    *) return 1 ;;
  esac
}

if supports_256; then
  echo "检测到可能支持 256 色（$TERM / tput colors >= 256）"
else
  echo "警告：未检测到 256 色支持 (TERM=${TERM:-unknown})，仍尝试显示（结果可能不准确）"
fi
echo

# 打印背景色方块
print_bg() {
  local n="$1"
  printf "\033[48;5;%sm %3s \033[0m" "$n" "$n"
}

# 打印前景色数字
print_fg() {
  local n="$1"
  printf "\033[38;5;%sm%3s\033[0m " "$n" "$n"
}

# 显示背景色方块
if [ "$SHOW_BG" -eq 1 ]; then
  echo "Standard colors (0-15):"
  for i in $(seq 0 15); do
    print_bg "$i"
    if [ $(( (i+1) % 8 )) -eq 0 ]; then echo; fi
  done
  echo
  echo "Color cube (16-231):"
  count=0
  for i in $(seq 16 231); do
    print_bg "$i"
    count=$((count+1))
    if [ $(( count % 36 )) -eq 0 ]; then echo; fi
  done
  echo
  echo "Grayscale (232-255):"
  for i in $(seq 232 255); do
    print_bg "$i"
    if [ $(( (i-232+1) % 12 )) -eq 0 ]; then echo; fi
  done
  echo
fi

# 显示前景色数字
if [ "$SHOW_FG" -eq 1 ]; then
  echo "Foreground samples (0..15 then 16..231 sample):"
  for i in $(seq 0 15); do print_fg "$i"; done
  echo
  for i in 16 52 88 124 160 196; do print_fg "$i"; done
  echo
fi

echo
echo "完成。若颜色显示异常，请尝试切换到 xterm-256color 或使用支持 256 色的终端（iTerm2, Alacritty, Kitty, GNOME Terminal 等）。"
