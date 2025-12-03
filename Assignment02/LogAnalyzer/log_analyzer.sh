#!/bin/bash
# Simple Log File Analyzer

if [ $# -ne 1 ]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi

LOG_FILE="$1"

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: File not found!"
    exit 1
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="log_analysis_$TIMESTAMP.txt"

# File info
FILE_SIZE=$(stat -c%s "$LOG_FILE")
FILE_SIZE_HUMAN=$(du -h "$LOG_FILE" | awk '{print $1}')
NOW=$(date)

{
echo "===== LOG FILE ANALYSIS REPORT ====="
echo "File: $LOG_FILE"
echo "Analyzed on: $NOW"
echo "Size: $FILE_SIZE_HUMAN ($FILE_SIZE bytes)"
echo ""
} > "$REPORT_FILE"

# Message counts
ERROR_COUNT=$(grep -c "ERROR" "$LOG_FILE")
WARNING_COUNT=$(grep -c "WARNING" "$LOG_FILE")
INFO_COUNT=$(grep -c "INFO" "$LOG_FILE")

{
echo "MESSAGE COUNTS:"
echo "ERROR: $ERROR_COUNT messages"
echo "WARNING: $WARNING_COUNT messages"
echo "INFO: $INFO_COUNT messages"
echo ""
} >> "$REPORT_FILE"

# Top 5 ERROR messages
{
echo "TOP 5 ERROR MESSAGES:"
grep "ERROR" "$LOG_FILE" | sed -E 's/.*ERROR[: ]*//' | sort | uniq -c | sort -nr | head -n 5
echo ""
} >> "$REPORT_FILE"

# First and last error
FIRST_ERROR=$(grep "ERROR" "$LOG_FILE" | head -n 1)
LAST_ERROR=$(grep "ERROR" "$LOG_FILE" | tail -n 1)

{
echo "ERROR TIMELINE:"
echo "First error: $FIRST_ERROR"
echo "Last error:  $LAST_ERROR"
echo ""
} >> "$REPORT_FILE"

# Error frequency by hour
{
echo "Error frequency by hour:"
for h in 00 04 08 12 16 20; do
    START=$h
    END=$(printf "%02d" $((10#$h + 4)))
    COUNT=$(grep "ERROR" "$LOG_FILE" | awk -v start=$START -v end=$END '{split($2,t,":"); if(t[1]>=start && t[1]<end) print}' | wc -l)
    BAR=$(printf "%0.s█" $(seq 1 $((COUNT / 2 + 1))))
    echo "$START-$END: $BAR ($COUNT)"
done
echo ""
} >> "$REPORT_FILE"

echo "Report saved to: $REPORT_FILE"
