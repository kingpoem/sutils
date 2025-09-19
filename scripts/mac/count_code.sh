#!/usr/bin/env bash
# ===============================================
# Script: count_code.sh
# Description:
#   Recursively count useful lines of code in the specified directory.
#   "Useful" lines are non-empty and exclude common comments (#, //).
#
# Usage:
#   ./count_code.sh                     # Count all supported extensions in current dir
#   ./count_code.sh --dir=./src
#                                       # Count code in ./src directory
#   ./count_code.sh --exclude-dir=./build,./test
#                                       # Exclude specific directories
#   ./count_code.sh --extensions=cpp,c,py
#                                       # Only count specific file extensions
#
# Options:
#   --dir=<directory>       Directory to start counting (default: .)
#   --exclude-dir=<dirs>    Comma-separated directories to exclude
#   --extensions=<exts>     Comma-separated file extensions to count
#   -h, --help              Show this help message
# ===============================================

HELP=$(cat <<'EOF'
Usage: count_code.sh [options]

English:
  --dir=<directory>       Directory to start counting (default: .)
  --exclude-dir=<dirs>    Comma-separated directories to exclude
  --extensions=<exts>     Comma-separated file extensions to count
  -h, --help              Show this help message

中文:
  --dir=<目录>             指定统计的目录（默认当前目录）
  --exclude-dir=<目录列表>  用逗号分隔的目录，将在统计时排除
  --extensions=<扩展名列表> 用逗号分隔的文件扩展名，只统计指定类型
  -h, --help              显示此帮助信息
EOF
)

# 默认参数
extensions="c cpp h hpp py java rs go js ts sh"
exclude_dirs=""
target_dir="."

# 解析命令行参数
for arg in "$@"; do
    case $arg in
        --dir=*)
            target_dir="${arg#*=}"
            ;;
        --exclude-dir=*)
            exclude_dirs="${arg#*=}"
            ;;
        --extensions=*)
            extensions="${arg#*=}"
            ;;
        -h|--help)
            echo "$HELP"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $arg"
            echo "$HELP"
            exit 1
            ;;
    esac
done

# 构造 find 参数
find_args=()
for ext in $(echo $extensions | tr ',' ' '); do
    find_args+=(-name "*.$ext" -o)
done
unset 'find_args[${#find_args[@]}-1]'

# 构造排除目录参数
exclude_args=()
if [ -n "$exclude_dirs" ]; then
    IFS=',' read -r -a dirs <<< "$exclude_dirs"
    for d in "${dirs[@]}"; do
        exclude_args+=(-path "$d" -prune -o)
    done
fi

total=0

# 查找文件并统计
while IFS= read -r file; do
    count=$(sed -E '/^\s*$/d;/^\s*#/d;/^\s*\/\//d' "$file" | wc -l)
    echo "$file: $count"
    total=$((total + count))
done < <(find "$target_dir" "${exclude_args[@]}" -type f \( "${find_args[@]}" \) -print)

echo "-----------------------"
echo "Total useful code lines: $total"
