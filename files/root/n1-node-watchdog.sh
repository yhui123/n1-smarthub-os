#!/bin/sh
# =====================================================================
# N1 节点智能全自动巡检与故障自愈守护 (/root/n1-node-watchdog.sh)
# - 定期探针检测当前节点连通性与延迟
# - 若节点出现超时、不可达或延迟骤增，自动触发秒级重选最优 IP
# - 记录健康日志，保障全家网络永不掉线
# =====================================================================

LOG_FILE="/tmp/n1-node-watchdog.log"
LOCK_FILE="/tmp/n1-node-watchdog.lock"
BEST_FILE="/etc/xray/cf-best.conf"

[ -f "$LOCK_FILE" ] && [ $(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) )) -lt 120 ] && exit 0
touch "$LOCK_FILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# 1. 检测 Xray 主代理端口 (10808) 或分流端口
TEST_URL="https://www.google.com/generate_204"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 4 -x socks5h://127.0.0.1:10808 "$TEST_URL" 2>/dev/null)

if [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "200" ]; then
    # 正常连通，再测一下当前时延
    APP_TIME=$(curl -s -o /dev/null -w "%{time_appconnect}" -m 4 -x socks5h://127.0.0.1:10808 "$TEST_URL" 2>/dev/null)
    MS=$(awk -v t="$APP_TIME" 'BEGIN{printf "%d", t*1000}')
    
    # 如果时延在正常范围 (< 450ms)，保持运行
    if [ "$MS" -gt 0 ] && [ "$MS" -lt 450 ]; then
        # 每10次检测仅轻量记录一次或不刷屏
        rm -f "$LOCK_FILE"
        exit 0
    else
        log "⚠️ 当前节点延迟过高 (${MS}ms > 450ms)，启动自动化节点重选优选..."
    fi
else
    log "❌ 当前代理连通性异常 (HTTP: ${HTTP_CODE})，正在自动切换与优选最佳节点..."
fi

# 2. 执行自动优选
/root/cf-update.sh >> "$LOG_FILE" 2>&1

NEW_BEST=$(cat "$BEST_FILE" 2>/dev/null)
log "✅ 自动化节点优选完成，当前最佳节点: ${NEW_BEST}"

rm -f "$LOCK_FILE"
