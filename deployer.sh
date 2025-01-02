#!/bin/bash

set -e # Exit on any error


APP_DIR="/html"
DEPLOY_DIR="$APP_DIR/deployer"
TAR_FILE="$DEPLOY_DIR/repository.tar.gz"
DEPLOY_REPO_DIR="$DEPLOY_DIR/repository"
BACKUP_DIR="$DEPLOY_DIR/backup-$(date +%Y%m%d%H%M%S)"
LOG_FILE="$APP_DIR/deployment-$(date +%Y%m%d%H%M%S).log"
LOCKFILE="/tmp/deployment.lock"

EXCLUDES=(
  ".git"
  ".env"
  ".github"
  ".gitignore"
  ".htaccess"
  "Thumbs.db"
  "readme.md"
  "platform/"
  "wp-admin/"
  "wp-includes/"
  "wp-content/mu-plugins/"
  "wp-content/themes/twenty*/"
  "wp-content/uploads/"
  "*.log"
  "deployer/"
  "index.php"
  "plat-cron.php"
  "wp-activate.php"
  "wp-blog-header.php"
  "wp-comments-post.php"
  "wp-cron.php"
  "wp-links-opml.php"
  "wp-load.php"
  "wp-login.php"
  "wp-mail.php"
  "wp-settings.php"
  "wp-signup.php"
  "wp-trackback.php"
  "xmlrpc.php"
)

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

acquire_lock() {
  if [ -e "$LOCKFILE" ]; then
    log "Another instance of the deployment script is already running."
    exit 1
  fi

  # lock released on script exit
  trap 'release_lock' EXIT
  touch "$LOCKFILE"
}

release_lock() {
  rm -f "$LOCKFILE"
}

validate_prerequisites() {
  if [ ! -f "$TAR_FILE" ]; then
    log "Error: TAR file not found at $TAR_FILE."
    exit 1
  fi

  if ! command -v wp &>/dev/null; then
    log "Error: WordPress CLI (wp) is not installed or not in PATH."
    exit 1
  fi
}

# Create required directories
create_directories() {
  log "Creating deployment and backup directories..."
  mkdir -p "$DEPLOY_REPO_DIR"
  mkdir -p "$BACKUP_DIR"
}

extract_tar() {
  log "Extracting tar file to $DEPLOY_REPO_DIR..."
  tar -xzf "$TAR_FILE" -C "$DEPLOY_REPO_DIR" || {
    log "Error: Failed to extract tar file."
    exit 1
  }
}

sync_files() {
  log "Synchronizing files to $APP_DIR with backup..."
  RSYNC_EXCLUDES=""
  for EXCLUDE in "${EXCLUDES[@]}"; do
    RSYNC_EXCLUDES+="--exclude=$EXCLUDE "
  done

  rsync -avz --checksum --backup --backup-dir="$BACKUP_DIR" --suffix="" $RSYNC_EXCLUDES "$DEPLOY_REPO_DIR/" "$APP_DIR/" || {
    log "Error: Failed to synchronize files."
    exit 1
  }
}
## do check health before, pass flag from workflow
check_wordpress_health() {
  log "Checking WordPress health..."
  if ! wp core is-installed --path="$APP_DIR"; then
    log "Error: WordPress health check failed. Restoring backup..."
    rsync -avz "$BACKUP_DIR/" "$APP_DIR/" || log "Error: Failed to restore backup."
    log "Backup restored."
    exit 1
  fi
}

flush_cache() {
  log "Flushing WordPress cache..."
  if wp cache flush --path="$APP_DIR"; then
    log "Cache flushed successfully."
  else
    log "Warning: Cache flush failed, but deployment was successful."
  fi
}

persist_backup() {
  log "Move backup to some other directory"
}

cleanup() {
  log "Cleaning up temporary files and directories..."
  rm -rf "$DEPLOY_REPO_DIR"
  rm -f  "$TAR_FILE"
  log "Cleanup completed."
}

main() {
  log "Starting deployment..."
  validate_prerequisites
  create_directories
  extract_tar
  sync_files
  check_wordpress_health
  flush_cache
  persist_backup
  cleanup
  log "Deployment completed successfully."
}

acquire_lock
main
