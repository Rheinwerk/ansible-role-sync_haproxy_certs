#!/bin/bash
set -euo pipefail

# Trap to ensure all failures exit with code 1
trap_error() {
    local exit_code=$?
    # Only convert non-zero, non-2 exit codes to 1
    if [ $exit_code -ne 0 ] && [ $exit_code -ne 2 ]; then
        echo "Error: Script failed with exit code $exit_code" 1>&2
        exit 1
    fi
}
trap trap_error EXIT

# certificate bundles must not be exposed to world
# and haproxy group must only have read access
umask 027

usage() {
  echo "usage: $(basename "$0") [options]"
  echo ""
  echo "  -h, --help              Display help and exit"
  echo "  -b, --bucket BUCKET     S3 bucket name (required, env: SYNC_BUCKET)"
  echo "  -p, --path PATH         Target path (required, env: SYNC_PATH)"
}

S3_BUCKET="${SYNC_BUCKET:-}"
TARGET_DIR="${SYNC_PATH:-}"

## Parse options
while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    usage
    exit 0
    ;;
  -b | --bucket)
    S3_BUCKET="$2"
    shift 2
    ;;
  -p | --path)
    TARGET_DIR="$2"
    shift 2
    ;;
  --* | -*)
    echo "Unknown option $1" 1>&2
    usage 1>&2
    exit 1
    ;;
  *)
    echo "Unknown argument $1" 1>&2
    usage 1>&2
    exit 1
    ;;
  esac
done

# Validate required parameters
if [ -z "$S3_BUCKET" ]; then
    echo "Error: S3 bucket is required (use -b or --bucket, or set SYNC_BUCKET)" 1>&2
    usage 1>&2
    exit 1
fi

if [ -z "$TARGET_DIR" ]; then
    echo "Error: Target path is required (use -p or --path, or set SYNC_PATH)" 1>&2
    usage 1>&2
    exit 1
fi

# Ensure target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Target directory $TARGET_DIR does not exist" 1>&2
    exit 1
fi

# Sync certificates from S3 bucket v1 subfolder
echo "Syncing certificates from s3://${S3_BUCKET}/v1/ to ${TARGET_DIR}/"

# Capture sync output to detect changes
# aws s3 sync outputs lines when files are downloaded/uploaded
if ! SYNC_OUTPUT=$(AWS_PAGER="" aws s3 sync "s3://${S3_BUCKET}/v1/" "${TARGET_DIR}/" 2>&1); then
    echo "Error: aws s3 sync failed" 1>&2
    echo "$SYNC_OUTPUT" 1>&2
    exit 1
fi

# Check if there was any output (indicating changes)
if [ -n "$SYNC_OUTPUT" ]; then
    echo "Certificate sync completed with changes"
    echo "$SYNC_OUTPUT"
    exit 2
fi

echo "Certificate sync completed with no changes"

