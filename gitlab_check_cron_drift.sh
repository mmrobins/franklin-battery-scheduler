#!/bin/bash

# This script checks the drift between the scheduled and actual run times of GitLab CI pipelines.
#
# Requirements:
# 1. A GitLab Personal Access Token with `read_api` scope.
# https://gitlab.com/-/user_settings/personal_access_tokens
# 2. The token must be stored in the `GITLAB_PRIVATE_TOKEN` environment variable.
# 3. `jq` must be installed (`brew install jq`).

# --- Configuration ---
HISTORY_LIMIT=20 # Number of recent pipelines to check
PROJECT_PATH="mmrobins/franklin-battery-scheduler"

# --- Script ---

if [ -z "$GITLAB_PRIVATE_TOKEN" ]; then
  echo "Error: GITLAB_PRIVATE_TOKEN environment variable is not set."
  echo "Please create a Personal Access Token with 'read_api' scope in your GitLab profile and set it as an environment variable."
  exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "jq could not be found. Please install it (e.g., brew install jq)."
    exit 1
fi

# URL-encode the project path
project_id=$(echo "$PROJECT_PATH" | sed 's/\//%2F/g')



# Get the pipeline schedules
schedules_json=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" "https://gitlab.com/api/v4/projects/$project_id/pipeline_schedules")
if [ -z "$schedules_json" ]; then
    echo "Error: Failed to get pipeline schedules from GitLab API."
    exit 1
fi

# Get the recent pipelines
pipelines_json=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" "https://gitlab.com/api/v4/projects/$project_id/pipelines?source=schedule&per_page=$HISTORY_LIMIT")
if [ -z "$pipelines_json" ]; then
    echo "Error: Failed to get pipelines from GitLab API."
    exit 1
fi

# Print header
printf "% -25s | % -25s | % -15s | %s\n" "Scheduled Time" "Actual Time" "Drift (m)" "Cron"
echo "--------------------------|---------------------------|-----------------|----------------"

# Process each pipeline
while read -r pipeline; do
  pipeline_created_at=$(echo "$pipeline" | jq -r '.created_at' | sed 's/\.[0-9]*Z$/Z/')
  actual_ts=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$pipeline_created_at" "+%s")

  # Find the corresponding schedule
  min_diff=999999
  best_schedule=""

  while read -r schedule; do
    cron=$(echo "$schedule" | jq -r '.cron')
    cron_timezone=$(echo "$schedule" | jq -r '.cron_timezone')

    cron_minute=$(echo "$cron" | cut -d' ' -f1)
    cron_hour=$(echo "$cron" | cut -d' ' -f2)

    pipeline_minute=$(date -u -r "$actual_ts" "+%M")
    pipeline_hour=$(date -u -r "$actual_ts" "+%H")

    if [ "$cron_hour" == "*" ]; then
      cron_hour=$(printf "%02d" $pipeline_hour)
    fi

    case $cron_minute in
      "*/15")
        cron_minute=$(( pipeline_minute / 15 * 15 ));;
      "*")
        cron_minute=$pipeline_minute;;
    esac

    pipeline_date=$(date -u -r "$actual_ts" "+%Y-%m-%d")

    scheduled_time_str="$pipeline_date $cron_hour:$cron_minute:00"

    scheduled_ts=$(TZ="$cron_timezone" date -j -f "%Y-%m-%d %H:%M:%S" "$scheduled_time_str" "+%s" 2>/dev/null)
    if [ $? -ne 0 ]; then
        scheduled_ts=$(date -u -j -f "%Y-%m-%d %H:%M:%S" "$scheduled_time_str" "+%s" 2>/dev/null)
    fi

    if [ "$scheduled_ts" -gt "$actual_ts" ]; then
        scheduled_ts=$((scheduled_ts - 86400))
    fi

    diff=$(( actual_ts - scheduled_ts ))

    if [ $diff -ge 0 ] && [ $diff -lt $min_diff ]; then
      min_diff=$diff
      best_schedule=$schedule
    fi
  done < <(echo "$schedules_json" | jq -c '.[]')

  if [ -n "$best_schedule" ]; then
    cron=$(echo "$best_schedule" | jq -r '.cron')
    cron_timezone=$(echo "$best_schedule" | jq -r '.cron_timezone')

    cron_minute=$(echo "$cron" | cut -d' ' -f1)
    cron_hour=$(echo "$cron" | cut -d' ' -f2)
    pipeline_date=$(date -u -r "$actual_ts" "+%Y-%m-%d")
    scheduled_time_str="$pipeline_date $cron_hour:$cron_minute:00"
    scheduled_ts=$(TZ="$cron_timezone" date -j -f "%Y-%m-%d %H:%M:%S" "$scheduled_time_str" "+%s" 2>/dev/null)
     if [ $? -ne 0 ]; then
        scheduled_ts=$(date -u -j -f "%Y-%m-%d %H:%M:%S" "$scheduled_time_str" "+%s" 2>/dev/null)
    fi

    if [ "$scheduled_ts" -gt "$actual_ts" ]; then
        scheduled_ts=$((scheduled_ts - 86400))
    fi

    drift=$(( actual_ts - scheduled_ts ))
    scheduled_time_utc=$(date -u -r "$scheduled_ts" "+%Y-%m-%d %H:%M:%S")
    actual_time_utc=$(date -u -r "$actual_ts" "+%Y-%m-%d %H:%M:%S")

    printf "% -25s | % -25s | % -15s | %s\n" "$scheduled_time_utc" "$actual_time_utc" "$((drift / 60))" "$cron ($cron_timezone)"
  fi
done < <(echo "$pipelines_json" | jq -c '.[]')
