#!/bin/bash

# assumes you have the GitHub CLI (gh) installed and authenticated

# GitHub cron is very inconsistent at how close to the actual cron time it runs
# Scheduled Time (UTC) | Actual Time (UTC)     | Drift (minutes)
# ---------------------|-----------------------|-----------------
# 2025-10-16 12:50:00  | 2025-10-16 13:21:47   | 31
# 2025-10-16 04:10:00  | 2025-10-16 04:32:50   | 22
# 2025-10-15 23:55:00  | 2025-10-16 00:40:43   | 45
# 2025-10-15 23:00:00  | 2025-10-15 23:09:55   | 9
# 2025-10-15 12:50:00  | 2025-10-15 13:22:18   | 32
# 2025-10-15 04:10:00  | 2025-10-15 04:33:10   | 23
# 2025-10-14 23:55:00  | 2025-10-15 00:41:14   | 46
# 2025-10-14 23:00:00  | 2025-10-14 23:09:57   | 9
# 2025-10-14 12:50:00  | 2025-10-14 13:21:15   | 31
# 2025-10-14 04:10:00  | 2025-10-14 04:32:58   | 22

# Get the workflow file content
workflow_file=".github/workflows/battery-schedule.yml"
if [ ! -f "$workflow_file" ]; then
  echo "Workflow file not found: $workflow_file"
  exit 1
fi

# Extract cron schedules from the workflow file
cron_schedules=$(grep "cron:" "$workflow_file" | sed "s/.*cron: '\(.*\)'.*/\1/")

# Get the last 10 workflow runs
run_list_json=$(gh run list --workflow=battery-schedule.yml --limit=10 --json createdAt)

# Check if gh command was successful
if [ $? -ne 0 ]; then
  echo "Error getting workflow runs. Make sure you are logged in with
 gh auth login
."
  exit 1
fi

# Parse the run list and print the drift
echo "Scheduled Time (UTC) | Actual Time (UTC)     | Drift (minutes)"
echo "---------------------|-----------------------|-----------------"

echo "$run_list_json" | jq -c '.[]' | while read -r run; do
  created_at=$(echo "$run" | jq -r '.createdAt')

  # Convert createdAt to Unix timestamp
  actual_ts=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_at" "+%s")

  # Find the closest cron schedule
  min_drift=999999
  closest_cron=""

  while IFS= read -r cron_schedule; do
    # Get the next scheduled run time *before* the actual run time
    # This is a bit tricky, we'll go back in time and find the last scheduled time

    # Get current time components
    actual_minute=$(date -u -r "$actual_ts" "+%M")
    actual_hour=$(date -u -r "$actual_ts" "+%H")
    actual_day=$(date -u -r "$actual_ts" "+%d")
    actual_month=$(date -u -r "$actual_ts" "+%m")
    actual_year=$(date -u -r "$actual_ts" "+%Y")

    # Cron parts
    cron_minute=$(echo "$cron_schedule" | cut -d' ' -f1)
    cron_hour=$(echo "$cron_schedule" | cut -d' ' -f2)

    # Construct the scheduled time for the same day
    scheduled_time_str="$actual_year-$actual_month-$actual_day $cron_hour:$cron_minute:00"
    scheduled_ts=$(date -u -j -f "%Y-%m-%d %H:%M:%S" "$scheduled_time_str" "+%s" 2>/dev/null)

    # If the scheduled time is in the future, go back one day
    if [ "$scheduled_ts" -gt "$actual_ts" ]; then
        scheduled_ts=$(($scheduled_ts - 86400))
    fi

    drift=$(( (actual_ts - scheduled_ts) / 60 ))

    if [ "$drift" -ge 0 ] && [ "$drift" -lt "$min_drift" ]; then
      min_drift=$drift
      closest_cron=$cron_schedule
    fi

  done <<< "$cron_schedules"

  # Get the scheduled time for the closest cron
  cron_minute=$(echo "$closest_cron" | cut -d' ' -f1)
  cron_hour=$(echo "$closest_cron" | cut -d' ' -f2)

  # We need to find the day it was supposed to run.
  # Let's assume it's the same day or the day before.

  # Construct the scheduled time for the same day as actual run
  scheduled_time_str_same_day=$(date -u -r "$actual_ts" "+%Y-%m-%d")" $cron_hour:$cron_minute:00"
  scheduled_ts_same_day=$(date -u -j -f "%Y-%m-%d %H:%M:%S" "$scheduled_time_str_same_day" "+%s")

  # Construct the scheduled time for the day before the actual run
  prev_day_ts=$(( $(date -u -r "$actual_ts" "+%s") - 86400 ))
  scheduled_time_str_prev_day=$(date -u -r "$prev_day_ts" "+%Y-%m-%d")" $cron_hour:$cron_minute:00"
  scheduled_ts_prev_day=$(date -u -j -f "%Y-%m-%d %H:%M:%S" "$scheduled_time_str_prev_day" "+%s")

  # Find the real scheduled time
  diff_same_day=$(( actual_ts - scheduled_ts_same_day ))
  diff_prev_day=$(( actual_ts - scheduled_ts_prev_day ))

  if [ "$diff_same_day" -lt 0 ]; then
      # it must be the previous day
      scheduled_ts=$scheduled_ts_prev_day
  elif [ "$diff_prev_day" -lt 0 ]; then
      # it must be the same day
      scheduled_ts=$scheduled_ts_same_day
  else
      # it's the one with the smallest positive difference
      if [ "$diff_same_day" -lt "$diff_prev_day" ]; then
          scheduled_ts=$scheduled_ts_same_day
      else
          scheduled_ts=$scheduled_ts_prev_day
      fi
  fi

  scheduled_time_utc=$(date -u -r "$scheduled_ts" "+%Y-%m-%d %H:%M:%S")
  actual_time_utc=$(date -u -r "$actual_ts" "+%Y-%m-%d %H:%M:%S")
  drift_minutes=$(( (actual_ts - scheduled_ts) / 60 ))

  printf "%-20s | %-21s | %s\n" "$scheduled_time_utc" "$actual_time_utc" "$drift_minutes"

done
