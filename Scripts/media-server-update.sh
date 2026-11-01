#!/usr/bin/env bash
# =============================================================================
# Media Server update script
# =============================================================================
# DIR: /usr/local/bin/media-server-update.sh
# SERVICE: /etc/systemd/system/media-server-update.service
#          /etc/systemd/system/media-server-update.timer
#
# media-server-update.sh
# Updates system packages, pulls the latest media-server container images,
# recreates any containers whose image changed, and prunes old images.
# Output is logged to $LOG_DIR; only the newest $KEEP_LOGS logs are kept.
#
# Intended to run unattended as root (systemd timer or root crontab).

set -euo pipefail

# --- Configuration -----------------------------------------------------------
LOG_DIR="<YOUR-LOG-PATH>"
COMPOSE_DIR="<YOUR-DOCKER-COMPOSE-PATH>"
KEEP_LOGS=5
AUTO_REBOOT=false          # true = reboot automatically if a package update requires it
LOCK_FILE="/run/media-update.lock"
# -----------------------------------------------------------------------------

LOGFILE="$LOG_DIR/update-log_$(date +%Y-%m-%d_%H-%M).log"

# Refuse to run with unfilled placeholders
if [[ "$LOG_DIR" == *"<"* || "$COMPOSE_DIR" == *"<"* ]]; then
    echo "Edit LOG_DIR and COMPOSE_DIR at the top of this script first." >&2
    exit 1
fi

# Must run as root (no sudo inside an unattended job)
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

# Prevent two runs overlapping
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "Another update is already running, exiting." >&2
    exit 1
fi

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOGFILE") 2>&1
TEE_PID=$!

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# Runs on every exit, success or failure: report status and rotate logs
on_exit() {
    local rc=$?
    if [[ $rc -eq 0 ]]; then
        log "=== Update finished successfully ==="
    else
        log "=== Update FAILED (exit code $rc) ==="
    fi
    ls -1t "$LOG_DIR"/update-log_*.log 2>/dev/null \
        | tail -n +$((KEEP_LOGS + 1)) \
        | xargs -r rm -f --
    # Close our output and wait for tee, so the last lines reach the log
    # before systemd/cron tears the job down
    exec 1>&- 2>&-
    wait "$TEE_PID" 2>/dev/null || true
}
trap on_exit EXIT

log "=== Update started ==="

# --- System packages ---------------------------------------------------------
log "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    upgrade
apt-get -y autoremove

# --- Containers --------------------------------------------------------------
cd "$COMPOSE_DIR"

log "Pulling container images..."
docker compose pull

log "Recreating containers with updated images..."
docker compose up -d --remove-orphans

log "Pruning unused images..."
docker image prune -f

# --- Reboot check ------------------------------------------------------------
if [[ -f /var/run/reboot-required ]]; then
    log "A reboot is required by: $({ tr '\n' ' ' < /var/run/reboot-required.pkgs; } 2>/dev/null || echo 'unknown packages')"
    if [[ "$AUTO_REBOOT" == true ]]; then
        log "Rebooting in 1 minute..."
        shutdown -r +1 "media-update: rebooting after package updates"
    fi
fi
