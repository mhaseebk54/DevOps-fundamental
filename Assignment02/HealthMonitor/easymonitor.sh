#!/bin/bash
# Easy System Health Monitor - easymonitor.sh

REFRESH_RATE=3
ALERT_LOG="easymonitor_alerts.log"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Draw bar function
draw_bar() {
    local value=$1
    local max_bar=30
    local filled=$(( value * max_bar / 100 ))
    local empty=$(( max_bar - filled ))
    printf "%0.s█" $(seq 1 $filled)
    printf "%0.s░" $(seq 1 $empty)
}

log_alert() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$ALERT_LOG"
}

while true; do
    clear
    HOSTNAME=$(hostname)
    NOW=$(date '+%Y-%m-%d %H:%M:%S')
    UPTIME=$(uptime -p)

    echo "╔════════════ EASY SYSTEM MONITOR v1.0 ════════════╗  [R]efresh rate: ${REFRESH_RATE}s  [Q]uit"
    echo "║ Hostname: $HOSTNAME          Date: $NOW ║"
    echo "║ Uptime: $UPTIME ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""

    # CPU
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2+$4)}')
    [ $CPU -ge 80 ] && CPU_COLOR=$RED && log_alert "CPU usage exceeded 80% ($CPU%)" || CPU_COLOR=$GREEN
    CPU_BAR=$(draw_bar $CPU)
    echo -e "CPU USAGE: $CPU% ${CPU_COLOR}${CPU_BAR}${RESET} $( [ $CPU -ge 50 ] && echo '[WARNING]' || echo '[OK]' )"
    echo ""

    # Memory
    MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
    MEM_PERCENT=$(( MEM_USED * 100 / MEM_TOTAL ))
    [ $MEM_PERCENT -ge 75 ] && MEM_COLOR=$RED && log_alert "Memory usage exceeded 75% ($MEM_PERCENT%)" || MEM_COLOR=$GREEN
    MEM_BAR=$(draw_bar $MEM_PERCENT)
    echo -e "MEMORY: ${MEM_USED}MB/${MEM_TOTAL}MB ($MEM_PERCENT%) ${MEM_COLOR}${MEM_BAR}${RESET} $( [ $MEM_PERCENT -ge 60 ] && echo '[WARNING]' || echo '[OK]' )"
    echo ""

    # Disk
    echo "DISK USAGE:"
    df -h | awk 'NR>1 {print $6,$5}' | while read mount usage; do
        USAGE_NUM=${usage%\%}
        [ $USAGE_NUM -ge 75 ] && DISK_COLOR=$RED && log_alert "Disk usage on $mount exceeded 75% ($USAGE_NUM%)" || DISK_COLOR=$GREEN
        DISK_BAR=$(draw_bar $USAGE_NUM)
        echo -e "  $mount : $usage ${DISK_COLOR}${DISK_BAR}${RESET} $( [ $USAGE_NUM -ge 60 ] && echo '[WARNING]' || echo '[OK]' )"
    done
    echo ""

    # Load Average
    echo "LOAD AVERAGE: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""

    # Recent Alerts
    echo "RECENT ALERTS:"
    tail -n5 "$ALERT_LOG" 2>/dev/null || echo "None"
    echo ""
    echo "Press 'q' to quit."

    # Handle key press
    read -t $REFRESH_RATE -n 1 key
    if [[ $key == "q" ]]; then
        clear
        exit 0
    fi
done
