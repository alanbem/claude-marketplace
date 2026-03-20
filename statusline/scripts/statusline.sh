#!/bin/bash
input=$(cat)

# Version
VERSION=$(echo "$input" | jq -r '.version // "?"')

# Model
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"' | sed 's/ ([^)]*context)//')

# Context — used_percentage is the actual current context window usage
CTX_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
PCT=${PCT:-0}
# Derive current tokens from percentage (matches /context command)
TOKENS=$((PCT * CTX_SIZE / 100))

# Token abbreviation (numbers dimmed, unit suffix normal)
abbrev_tokens() {
    local t=$1
    local D='\033[38;2;100;100;100m' R='\033[0m'
    if [ "$t" -ge 1000000 ]; then
        awk "BEGIN {printf \"${D}%.1f${R}M\", $t/1000000}"
    elif [ "$t" -ge 1000 ]; then
        awk "BEGIN {printf \"${D}%.0f${R}k\", $t/1000}"
    else
        printf "${D}%s${R}" "$t"
    fi
}
TOKEN_DISPLAY="$(abbrev_tokens "$TOKENS")/$(abbrev_tokens "$CTX_SIZE")"

# Context bar (20 units) with color-coded empty dots showing zone preview
# Each unit = 5% of context window. Zones based on absolute token thresholds.
# Each dot covers [i*5%, (i+1)*5%). Fill as soon as tokens enter its range.
if [ "$PCT" -eq 0 ]; then
    FILLED=0
else
    FILLED=$(( PCT * 20 / 100 + 1 ))
    [ "$FILLED" -gt 20 ] && FILLED=20
fi
# Zone boundaries as bar positions (percentage-based)
POS_ORANGE=$((30 * 20 / 100))
POS_RED=$((40 * 20 / 100))
POS_CRIT=$((80 * 20 / 100))
# Colors: filled
C_GREEN='\033[38;2;130;160;130m'
C_ORANGE='\033[38;5;208m'
C_RED='\033[31m'
C_CRIT='\033[38;2;255;50;50m'
# Colors: empty (very faint versions)
C_GREEN_DIM='\033[38;2;40;50;40m'
C_ORANGE_DIM='\033[38;2;60;40;20m'
C_RED_DIM='\033[38;2;55;25;25m'
C_CRIT_DIM='\033[38;2;55;25;25m'
RST='\033[0m'
BAR=""
for ((i=0; i<20; i++)); do
    # Determine zone color for this position
    if [ "$i" -ge "$POS_CRIT" ]; then
        FC="$C_CRIT"; DC="$C_CRIT_DIM"
    elif [ "$i" -ge "$POS_RED" ]; then
        FC="$C_RED"; DC="$C_RED_DIM"
    elif [ "$i" -ge "$POS_ORANGE" ]; then
        FC="$C_ORANGE"; DC="$C_ORANGE_DIM"
    else
        FC="$C_GREEN"; DC="$C_GREEN_DIM"
    fi
    if [ "$i" -lt "$FILLED" ]; then
        BAR+="${FC}⦿${RST}"
    else
        BAR+="${DC}●${RST}"
    fi
done

# Context percentage color — matches the last filled dot's zone color
REMAINING=$((CTX_SIZE - TOKENS))
if [ "$FILLED" -le 0 ]; then
    CTX_COLOR="$C_GREEN"
else
    # Color of the last filled dot (FILLED-1 is the index)
    LAST=$((FILLED - 1))
    if [ "$LAST" -ge "$POS_CRIT" ]; then
        CTX_COLOR="$C_CRIT"
    elif [ "$LAST" -ge "$POS_RED" ]; then
        CTX_COLOR="$C_RED"
    elif [ "$LAST" -ge "$POS_ORANGE" ]; then
        CTX_COLOR="$C_ORANGE"
    else
        CTX_COLOR="$C_GREEN"
    fi
fi

# Workspace dirs
CWD=$(echo "$input" | jq -r '.workspace.current_dir // "."')
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir // "."')

# Lines changed (git diff on current branch + session totals)
DIM_GREEN='\033[38;2;70;100;70m'
DIM_RED='\033[38;2;120;70;70m'
GIT_LINE_DIFF=$(git -C "$CWD" diff --shortstat HEAD 2>/dev/null)
GIT_LINES_ADDED=$(echo "$GIT_LINE_DIFF" | grep -oP '\d+(?= insertion)' || echo "0")
GIT_LINES_REMOVED=$(echo "$GIT_LINE_DIFF" | grep -oP '\d+(?= deletion)' || echo "0")
GIT_LINES_ADDED=${GIT_LINES_ADDED:-0}
GIT_LINES_REMOVED=${GIT_LINES_REMOVED:-0}
# File-level changes (modified, added, deleted)
GIT_FILES_MODIFIED=$(git -C "$CWD" diff --diff-filter=M --name-only HEAD 2>/dev/null | wc -l | tr -d ' ')
GIT_FILES_ADDED=$(git -C "$CWD" diff --diff-filter=A --name-only HEAD 2>/dev/null | wc -l | tr -d ' ')
GIT_FILES_DELETED=$(git -C "$CWD" diff --diff-filter=D --name-only HEAD 2>/dev/null | wc -l | tr -d ' ')
GIT_FILES_UNTRACKED=$(git -C "$CWD" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
DIM_ORANGE='\033[38;2;140;100;50m'
SESSION_LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
SESSION_LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# Duration
TOTAL_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0' | cut -d. -f1)
API_MS=$(echo "$input" | jq -r '.cost.total_api_duration_ms // 0' | cut -d. -f1)

# Progressive format — most significant units, no seconds:
# <1m -> 1m -> 59m -> 1h -> 1h1m -> 1h59m -> 2h -> 2h1m -> 23h59m ->
# 1d -> 1d1m -> 1d59m -> 1d1h -> 1d1h1m -> 1d1h59m -> 1d2h -> ...
format_duration() {
    local ms=$1
    local D='\033[38;2;100;100;100m' R='\033[0m'
    local total_secs=$((ms / 1000))
    local days=$((total_secs / 86400))
    local hours=$(( (total_secs % 86400) / 3600 ))
    local mins=$(( (total_secs % 3600) / 60 ))
    if [ "$days" -gt 0 ]; then
        local out="${D}${days}${R}d"
        [ "$hours" -gt 0 ] && out="${out}${D}${hours}${R}h"
        [ "$mins" -gt 0 ] && out="${out}${D}${mins}${R}m"
        printf "%s" "$out"
    elif [ "$hours" -gt 0 ]; then
        local out="${D}${hours}${R}h"
        [ "$mins" -gt 0 ] && out="${out}${D}${mins}${R}m"
        printf "%s" "$out"
    elif [ "$mins" -gt 0 ]; then
        printf "%s" "${D}${mins}${R}m"
    else
        printf "%s" "${D}<${R}1m"
    fi
}

# Commits ahead/behind remote
GIT_AHEAD=0
GIT_BEHIND=0
GIT_UPSTREAM=$(git -C "$CWD" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
if [ -n "$GIT_UPSTREAM" ]; then
    GIT_AB=$(git -C "$CWD" rev-list --left-right --count HEAD...'@{upstream}' 2>/dev/null)
    GIT_AHEAD=$(echo "$GIT_AB" | cut -f1)
    GIT_BEHIND=$(echo "$GIT_AB" | cut -f2)
fi

DURATION=$(format_duration "$TOTAL_MS")
API_TIME=$(format_duration "$API_MS")

# Git branch
BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
IS_GIT=$?

# Icons (UTF-8 bytes — macOS bash 3.2 doesn't support \u)
ICON_VERSION="\xef\x81\xa9"   #
ICON_MODEL="\xef\x83\xa7"     #
ICON_CONTEXT="\xef\x83\x87"   #
ICON_DURATION="\xef\x80\x97"  #
ICON_API="\xef\x80\xa1"       #
ICON_STATS="\xef\x82\x80"     #
ICON_FOLDER="\xef\x80\x95"    #
ICON_BRANCH="\xee\x9c\xa5"    #
ICON_WORKTREE="\xee\x9c\xa5"  #
ICON_FILES="\xef\x81\x84"    #
ICON_DIFF="\xef\x82\x80"     #
# Worktree (native Claude Code field, with git-based fallback)
WORKTREE=$(echo "$input" | jq -r '.worktree.name // empty')
if [ -z "$WORKTREE" ]; then
    GIT_DIR=$(git -C "$CWD" rev-parse --git-dir 2>/dev/null)
    case "$GIT_DIR" in
        *"/worktrees/"*) WORKTREE="${GIT_DIR##*/}" ;;
    esac
fi

# CLI tool auth status (local checks only, no network calls)
# 3 states: not installed (dimmed), installed but not authenticated (dim red), authenticated (dim green)
CLI_AUTH_YES='\033[38;2;70;100;70m'
CLI_AUTH_NO='\033[38;2;120;70;70m'
CLI_NOT_FOUND='\033[38;2;60;60;60m'
if ! command -v aws &>/dev/null; then
    AWS_LABEL="${CLI_NOT_FOUND}aws${RST}"
elif aws configure list 2>&1 | grep -q access_key && aws configure list 2>&1 | grep access_key | grep -qv 'not set'; then
    AWS_LABEL="${CLI_AUTH_YES}aws${RST}"
else
    AWS_LABEL="${CLI_AUTH_NO}aws${RST}"
fi
if ! command -v gh &>/dev/null; then
    GH_LABEL="${CLI_NOT_FOUND}gh${RST}"
elif gh auth status &>/dev/null 2>&1; then
    GH_LABEL="${CLI_AUTH_YES}gh${RST}"
else
    GH_LABEL="${CLI_AUTH_NO}gh${RST}"
fi
if ! command -v acli &>/dev/null; then
    ACLI_LABEL="${CLI_NOT_FOUND}acli${RST}"
elif acli jira auth status &>/dev/null; then
    ACLI_LABEL="${CLI_AUTH_YES}acli${RST}"
else
    ACLI_LABEL="${CLI_AUTH_NO}acli${RST}"
fi
if ! command -v gws &>/dev/null; then
    GWS_LABEL="${CLI_NOT_FOUND}gws${RST}"
elif gws auth status 2>/dev/null | grep -q '"token_valid": true'; then
    GWS_LABEL="${CLI_AUTH_YES}gws${RST}"
else
    GWS_LABEL="${CLI_AUTH_NO}gws${RST}"
fi

# Account email (from Claude config)
ACCOUNT_EMAIL=$(jq -r '.oauthAccount.emailAddress // empty' ~/.claude/.claude.json 2>/dev/null)
ICON_USER="\xef\x80\x87"   #

# Separator
SEP=" │ "
ICON_CLI="\xef\x84\xa0"

# Folder (project basename + relative path from project dir)
PROJECT_BASE=$(basename "$PROJECT_DIR")
REL_FROM_PROJECT=$(realpath --relative-to="$PROJECT_DIR" "$CWD" 2>/dev/null || echo ".")
DIM='\033[38;2;100;100;100m'
if [ "$REL_FROM_PROJECT" = "." ]; then
    FOLDER="${PROJECT_BASE}/"
else
    FOLDER="${PROJECT_BASE}/${DIM}${REL_FROM_PROJECT}${RST}"
fi


# Output
# Anthropic brand color (warm tan/sienna)
ANTHRO='\033[38;2;204;136;68m'

TOOLS_SECTION="${SEP}${ANTHRO}${ICON_CLI}${RST} ${AWS_LABEL} ${DIM}·${RST} ${ANTHRO}${ICON_CLI}${RST} ${GH_LABEL} ${DIM}·${RST} ${ANTHRO}${ICON_CLI}${RST} ${ACLI_LABEL} ${DIM}·${RST} ${ANTHRO}${ICON_CLI}${RST} ${GWS_LABEL}"

# Build git section only if in a git repo
if [ "$IS_GIT" -eq 0 ]; then
    # Two branch icons: both bright in worktree, second dimmed orange otherwise
    ANTHRO_DIM='\033[38;2;120;80;40m'
    if [ -n "$WORKTREE" ]; then
        GIT_ICONS="${ANTHRO}${ICON_BRANCH}${ICON_WORKTREE}${RST}"
    else
        GIT_ICONS="${ANTHRO}${ICON_BRANCH}${ANTHRO_DIM}${ICON_WORKTREE}${RST}"
    fi
    # Ahead/behind remote
    if [ "$GIT_AHEAD" -gt 0 ]; then
        GIT_AHEAD_DISPLAY="${DIM_GREEN}↑${GIT_AHEAD}${RST}"
    else
        GIT_AHEAD_DISPLAY="${DIM}↑${GIT_AHEAD}${RST}"
    fi
    if [ "$GIT_BEHIND" -gt 0 ]; then
        GIT_BEHIND_DISPLAY="${DIM_RED}↓${GIT_BEHIND}${RST}"
    else
        GIT_BEHIND_DISPLAY="${DIM}↓${GIT_BEHIND}${RST}"
    fi
    GIT_AB_DISPLAY=" ${GIT_AHEAD_DISPLAY}${GIT_BEHIND_DISPLAY}"
    GIT_SECTION="${SEP}${GIT_ICONS} ${BRANCH}${GIT_AB_DISPLAY} ${DIM}·${RST} ${ANTHRO}${ICON_FILES}${RST} ${DIM_GREEN}+${GIT_FILES_ADDED}${RST} ${DIM_ORANGE}~${GIT_FILES_MODIFIED}${RST} ${DIM_RED}−${GIT_FILES_DELETED}${RST} ${DIM}?${GIT_FILES_UNTRACKED}${RST} ${DIM}·${RST} ${ANTHRO}${ICON_DIFF}${RST} ${DIM_GREEN}+${GIT_LINES_ADDED}${RST} ${DIM_RED}−${GIT_LINES_REMOVED}${RST}"
else
    GIT_SECTION="${SEP}${CLI_NOT_FOUND}${ICON_BRANCH}${ICON_WORKTREE}${RST}"
fi

ACCOUNT_SECTION=""
if [ -n "$ACCOUNT_EMAIL" ]; then
    EMAIL_USER="${ACCOUNT_EMAIL%%@*}"
    EMAIL_DOMAIN="${ACCOUNT_EMAIL#*@}"
    ACCOUNT_SECTION="${SEP}${ANTHRO}${ICON_USER}${RST} ${EMAIL_USER}${DIM}@${RST}${EMAIL_DOMAIN}"
fi

echo -e "${ANTHRO}${ICON_VERSION}${RST} v${VERSION}${SEP}${ANTHRO}${ICON_MODEL}${RST} ${MODEL}${ACCOUNT_SECTION}${SEP}${ANTHRO}${ICON_CONTEXT}${RST} ${CTX_COLOR}${PCT}% ${BAR}${RST} ${TOKEN_DISPLAY}${SEP}${ANTHRO}${ICON_DURATION}${RST} ${DURATION} ${DIM}·${RST} ${ANTHRO}${ICON_API}${RST} ${API_TIME} ${DIM}·${RST} ${ANTHRO}${ICON_STATS}${RST} ${DIM_GREEN}✚${SESSION_LINES_ADDED}${RST} ${DIM_RED}−${SESSION_LINES_REMOVED}${RST}${GIT_SECTION}${TOOLS_SECTION}${SEP}${ANTHRO}${ICON_FOLDER}${RST} ${FOLDER}\n\xe2\x80\x8b"
