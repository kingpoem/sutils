#!/usr/bin/env bash

# 检查是否传入后缀参数
if [ -z "$1" ]; then
    echo "用法: $0 <文件后缀>"
    exit 1
fi

suffix="$1"

# 递归查找符合后缀的文件并输出相对路径
find . -type f -name "*.${suffix}" -print

