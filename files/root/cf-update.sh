#!/bin/sh
# =====================================================================
# N1 Cloudflare 节点自动优选与更新脚本 (/root/cf-update.sh)
# 用法:
#   /root/cf-update.sh                     按当前优选模式自动拉取并测速更新
#   /root/cf-update.sh <mode> <port>       切换优选模式(generator|random|custom)及端口(-1|443|...)并同步到后台后立即测速
# =====================================================================

SUB_URL="https://cf-1012.pages.dev/sub?token=9f799e689e8ccb955c8cda1933279b1f"
HOST="cf-1012.pages.dev"
ADMIN_PASS="Yh429273621.."
BEST_FILE="/etc/xray/cf-best.conf"
SUB_CONF="/etc/xray/cf-sub.conf"
TMP_DIR="/tmp/cf_speedtest_$$"

[ -f "$SUB_CONF" ] || echo "generator -1" > "$SUB_CONF"

if [ -n "$1" ]; then
    NEW_MODE="$1"
    NEW_PORT="${2:--1}"
    case "$NEW_MODE" in
        generator|random|custom) ;;
        *) NEW_MODE="generator" ;;
    esac
    case "$NEW_PORT" in
        -1|443|2053|2083|2087|2096|8443) ;;
        *) NEW_PORT="-1" ;;
    esac
    echo "$NEW_MODE $NEW_PORT" > "$SUB_CONF"

    # 同步设置到 https://cf-1012.pages.dev/admin/config.json
    COOKIE_JAR="/tmp/cf_admin_cookie_$$"
    CFG_JSON="/tmp/cf_admin_cfg_$$.json"
    curl -s -m 8 -c "$COOKIE_JAR" -A "Mozilla/5.0" -X POST "https://$HOST/login" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "password=$ADMIN_PASS" >/dev/null 2>&1
    if curl -s -m 8 -b "$COOKIE_JAR" -A "Mozilla/5.0" "https://$HOST/admin/config.json" > "$CFG_JSON" 2>/dev/null && grep -q '"UUID"' "$CFG_JSON" 2>/dev/null; then
        if [ "$NEW_MODE" = "generator" ]; then
            sed -i 's/"local":[[:space:]]*[a-z]*/"local": false/' "$CFG_JSON"
            sed -i 's/"随机IP":[[:space:]]*[a-z]*/"随机IP": false/' "$CFG_JSON"
            sed -i 's/"SUB":[[:space:]]*[^,]*/"SUB": "sub.cmliussss.net"/' "$CFG_JSON"
        elif [ "$NEW_MODE" = "random" ]; then
            sed -i 's/"local":[[:space:]]*[a-z]*/"local": true/' "$CFG_JSON"
            sed -i 's/"随机IP":[[:space:]]*[a-z]*/"随机IP": true/' "$CFG_JSON"
            sed -i 's/"SUB":[[:space:]]*[^,]*/"SUB": null/' "$CFG_JSON"
        else
            sed -i 's/"local":[[:space:]]*[a-z]*/"local": true/' "$CFG_JSON"
            sed -i 's/"随机IP":[[:space:]]*[a-z]*/"随机IP": false/' "$CFG_JSON"
            sed -i 's/"SUB":[[:space:]]*[^,]*/"SUB": null/' "$CFG_JSON"
        fi
        sed -i "s/\"指定端口\":[[:space:]]*[-0-9]*/\"指定端口\": $NEW_PORT/" "$CFG_JSON"
        curl -s -m 8 -b "$COOKIE_JAR" -A "Mozilla/5.0" -X POST "https://$HOST/admin/config.json" \
            -H "Content-Type: application/json" --data-binary "@$CFG_JSON" >/dev/null 2>&1
    fi
    rm -f "$COOKIE_JAR" "$CFG_JSON"
fi

CF_MODE=$(awk '{print $1}' "$SUB_CONF" 2>/dev/null)
CF_PORT=$(awk '{print $2}' "$SUB_CONF" 2>/dev/null)
[ -n "$CF_MODE" ] || CF_MODE="generator"
[ -n "$CF_PORT" ] || CF_PORT="-1"

case "$CF_MODE" in
    generator) MODE_NAME="大佬优选生成器" ;;
    random)    MODE_NAME="随机官方优选" ;;
    custom)    MODE_NAME="自定义订阅" ;;
    *)         MODE_NAME="$CF_MODE" ;;
esac

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 模式: ${MODE_NAME} (端口:${CF_PORT})，开始拉取最新订阅..."

RAW=$(curl -s -m 10 -A "v2rayN/6.23" "$SUB_URL" | tr -d '\r\n')
if [ -z "$RAW" ]; then
    echo "错误: 无法拉取订阅内容，保留原配置。"
    exit 1
fi

NODES=$(printf "%s" "$RAW" | openssl enc -d -base64 -A 2>/dev/null \
    | grep -oE '@[0-9.]+:[0-9]+' | tr -d '@' | sort -u)

if [ -z "$NODES" ]; then
    echo "错误: 未解析到有效节点 IP:PORT"
    exit 1
fi

# 若指定了特定端口（非 -1），优先筛选该端口，若不足 4 个则将候选 IP 替换为指定端口测速
if [ "$CF_PORT" != "-1" ]; then
    PORT_NODES=$(printf "%s\n" "$NODES" | grep ":${CF_PORT}$")
    if [ "$(printf "%s\n" "$PORT_NODES" | grep -c ':')" -ge 4 ]; then
        NODES="$PORT_NODES"
    else
        NODES=$(printf "%s\n" "$NODES" | awk -F: -v p="$CF_PORT" '{print $1":"p}' | sort -u)
    fi
fi

mkdir -p "$TMP_DIR"
CNT=$(printf "%s\n" "$NODES" | wc -l)
echo "正在并发测速 ${CNT} 个候选优选节点..."

i=0
for item in $NODES; do
    ip="${item%:*}"
    port="${item#*:}"
    i=$((i + 1))
    (
        res=$(curl -s -o /dev/null -w "%{http_code} %{time_appconnect}" \
            --connect-to "$HOST:443:$ip:$port" \
            "https://$HOST/cdn-cgi/trace" -m 3 2>/dev/null)
        code="${res% *}"
        t="${res#* }"
        if [ "$code" = "200" ]; then
            echo "$t $ip $port" > "$TMP_DIR/$i.res"
        fi
    ) &
done
wait

BEST=$(cat "$TMP_DIR"/*.res 2>/dev/null | sort -n -k1 | head -n 1)
rm -rf "$TMP_DIR"

if [ -z "$BEST" ]; then
    echo "警告: 本轮测速无节点返回 200，保留当前配置。"
    exit 1
fi

BEST_TIME=$(printf "%s" "$BEST" | awk '{print $1}')
BEST_IP=$(printf "%s" "$BEST" | awk '{print $2}')
BEST_PORT=$(printf "%s" "$BEST" | awk '{print $3}')
BEST_MS=$(awk -v t="$BEST_TIME" 'BEGIN{printf "%d", t*1000}')

OLD_IP_PORT=$(awk '{print $1":"$2}' "$BEST_FILE" 2>/dev/null)
NEW_IP_PORT="${BEST_IP}:${BEST_PORT}"

# 防劣化保护：本轮最优比已记录节点慢 50% 以上时，先复测当前节点，
# 仍可用则保留（避免网络抖动把好 IP 换成差 IP）
OLD_MS=$(awk '{gsub(/ms/,""); print $3}' "$BEST_FILE" 2>/dev/null)
if [ -n "$OLD_MS" ] && [ "$OLD_IP_PORT" != "$NEW_IP_PORT" ] && [ "$BEST_MS" -gt $((OLD_MS * 3 / 2)) ] 2>/dev/null; then
    OLD_IP="${OLD_IP_PORT%:*}"
    OLD_PORT="${OLD_IP_PORT#*:}"
    res=$(curl -s -o /dev/null -w "%{http_code} %{time_appconnect}" \
        --connect-to "$HOST:443:$OLD_IP:$OLD_PORT" \
        "https://$HOST/cdn-cgi/trace" -m 3 2>/dev/null)
    code="${res% *}"
    if [ "$code" = "200" ]; then
        echo "本轮最优 ${BEST_MS}ms 明显劣于当前 ${OLD_MS}ms，当前节点复测可用——保留 ${OLD_IP_PORT}"
        BEST_IP="$OLD_IP"
        BEST_PORT="$OLD_PORT"
        BEST_MS="$OLD_MS"
        NEW_IP_PORT="$OLD_IP_PORT"
    fi
fi

echo "${BEST_IP} ${BEST_PORT} ${BEST_MS}ms $(date '+%Y-%m-%d_%H:%M:%S')" > "$BEST_FILE"
echo "已切换【${MODE_NAME}】并测速完成！最快节点: ${BEST_IP}:${BEST_PORT} (TLS 握手: ${BEST_MS}ms)"

if /usr/bin/n1-xray-gen >/dev/null 2>&1; then
    # 仅当全局默认出口为 cf 系列时，IP 变化才值得重启 xray；
    # 走 hysteria/reality 时重启只会让当前线路无谓瞬断（优选结果仍写入
    # cf-best.conf，切回 cf 出口时自然生效）。xray 挂了则无条件拉起。
    DEF_OUT=$(grep -E "^default[[:space:]]" /etc/n1-device-nodes.conf 2>/dev/null | awk '{print $2}')
    case "$DEF_OUT" in
        cf-*) ALLOW_RESTART=1 ;;
        *)    ALLOW_RESTART=0 ;;
    esac
    if { [ "$OLD_IP_PORT" != "$NEW_IP_PORT" ] && [ "$ALLOW_RESTART" = "1" ]; } || ! /etc/init.d/xray status >/dev/null 2>&1; then
        (/etc/init.d/xray restart >/dev/null 2>&1) &
    fi
else
    echo "错误: 生成 Xray 配置失败！"
    exit 1
fi
