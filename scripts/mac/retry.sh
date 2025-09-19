#!/bin/bash
# retry.sh - 尝试推送到 origin main，如果失败就重试
# oneline:
# while ! git push origin main; do echo "retry"; done

while ! git push origin main; do
    echo "Push failed, retrying..."
    sleep 1
done
