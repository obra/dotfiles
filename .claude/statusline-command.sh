#!/bin/bash
# ABOUTME: Comprehensive status line for Claude Code showing model, directory, git, context, rate limits, cost, and background tasks
# ABOUTME: Uses color coding (green/yellow/red) and abbreviations for clean, readable output

# Read JSON input from stdin
input=$(cat)

# Extract basic info from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
model_id=$(echo "$input" | jq -r '.model.id')

# Extract context window data
context_usage=$(echo "$input" | jq '.context_window.current_usage')
if [[ "$context_usage" != "null" ]]; then
    input_tokens=$(echo "$context_usage" | jq '.input_tokens')
    cache_creation=$(echo "$context_usage" | jq '.cache_creation_input_tokens')
    cache_read=$(echo "$context_usage" | jq '.cache_read_input_tokens')
    context_used=$((input_tokens + cache_creation + cache_read))
else
    context_used=0
fi
context_total=$(echo "$input" | jq '.context_window.context_window_size')

# Extract total token counts (cumulative session)
total_input=$(echo "$input" | jq '.context_window.total_input_tokens')
total_output=$(echo "$input" | jq '.context_window.total_output_tokens')

# Extract rate limit data (if available in JSON)
# TODO: These need to be added to the JSON schema - using placeholders for now
rate_limit_5h_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used // 0')
rate_limit_5h_total=$(echo "$input" | jq -r '.rate_limits.five_hour.total // 0')
rate_limit_weekly_used=$(echo "$input" | jq -r '.rate_limits.weekly.used // 0')
rate_limit_weekly_total=$(echo "$input" | jq -r '.rate_limits.weekly.total // 0')

# Extract session cost (if available in JSON)
# TODO: This needs to be added to the JSON schema - using placeholder
session_cost=$(echo "$input" | jq -r '.session.cost // 0')

# Extract background task count (if available in JSON)
# TODO: This needs to be added to the JSON schema - using placeholder
bg_tasks=$(echo "$input" | jq -r '.background_tasks.count // 0')

# Abbreviate directory path intelligently
# Show last 2 components, or ~/... if in home
if [[ "$cwd" == "$HOME"* ]]; then
    short_cwd="~${cwd#$HOME}"
    # Limit to last 2 path components for readability
    short_cwd=$(echo "$short_cwd" | awk -F/ '{if(NF>3) printf "~/../%s/%s", $(NF-1), $NF; else print}')
else
    short_cwd=$(echo "$cwd" | awk -F/ '{if(NF>2) printf ".../%s/%s", $(NF-1), $NF; else print}')
fi

# Abbreviate model name (remove "Claude " prefix, shorten common patterns)
short_model="$model"
short_model="${short_model#Claude }"
short_model="${short_model//Sonnet/Son}"
short_model="${short_model//Haiku/Hai}"
short_model="${short_model//Opus/Ops}"
short_model="${short_model// 20/-}"  # "3.5 Sonnet 20241022" → "3.5 Son-241022"

# Check if we're in a git repository and get branch
git_status=""
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")

    # Check for uncommitted changes
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        git_status="${branch}*"  # * indicates changes
    else
        git_status="$branch"
    fi
fi

# Color codes (dimmed for terminal status line)
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

# Helper: format numbers with k/m suffix
format_number() {
    local num=$1
    if [[ $num -gt 1000000 ]]; then
        echo "$((num / 1000000))m"
    elif [[ $num -gt 1000 ]]; then
        echo "$((num / 1000))k"
    else
        echo "$num"
    fi
}

# Helper: get color based on percentage
get_color() {
    local pct=$1
    if [[ $pct -gt 90 ]]; then
        echo "$RED"
    elif [[ $pct -gt 70 ]]; then
        echo "$YELLOW"
    else
        echo "$GREEN"
    fi
}

# Helper: format percentage with color
format_pct() {
    local used=$1
    local total=$2

    if [[ $total -eq 0 ]]; then
        echo "${DIM}n/a${RESET}"
        return
    fi

    local pct=$((used * 100 / total))
    local color=$(get_color $pct)
    printf "${color}%d%%${RESET}" "$pct"
}

# Helper: format count with optional color
format_count() {
    local count=$1
    local label=$2

    if [[ $count -eq 0 ]]; then
        printf "${DIM}%s:0${RESET}" "$label"
    else
        printf "${CYAN}%s:%d${RESET}" "$label" "$count"
    fi
}

# Build status line components with clean separators
# Format: Model | ~/dir | branch | ctx:50k/200k(25%) | 5h:10% | wk:5% | cost:$1.23 | tasks:2

components=()

# Model name (abbreviated)
components+=("${BLUE}${short_model}${RESET}")

# Directory (cyan for visibility)
components+=("${CYAN}${short_cwd}${RESET}")

# Git branch (if available)
if [[ -n "$git_status" ]]; then
    components+=("${DIM}${git_status}${RESET}")
fi

# Context usage: tokens and percentage
if [[ $context_total -gt 0 ]]; then
    pct=$((context_used * 100 / context_total))
    color=$(get_color $pct)
    ctx_str=$(printf "ctx:%s/%s ${color}%d%%${RESET}" \
        "$(format_number $context_used)" \
        "$(format_number $context_total)" \
        "$pct")
    components+=("$ctx_str")
fi

# 5-hour rate limit percentage
if [[ $rate_limit_5h_total -gt 0 ]]; then
    components+=("5h:$(format_pct $rate_limit_5h_used $rate_limit_5h_total)")
fi

# Weekly rate limit percentage
if [[ $rate_limit_weekly_total -gt 0 ]]; then
    components+=("wk:$(format_pct $rate_limit_weekly_used $rate_limit_weekly_total)")
fi

# Session cost
if [[ $(echo "$session_cost > 0" | bc -l 2>/dev/null) -eq 1 ]]; then
    components+=("$(printf "\$%.2f" "$session_cost")")
fi

# Background tasks count
if [[ $bg_tasks -gt 0 ]]; then
    components+=("$(format_count $bg_tasks "tasks")")
fi

# Join with pipe separators
output=""
for i in "${!components[@]}"; do
    if [[ $i -gt 0 ]]; then
        output+=" ${DIM}|${RESET} "
    fi
    output+="${components[$i]}"
done

printf "%b\n" "$output"