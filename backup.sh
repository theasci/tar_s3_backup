#!/bin/sh

set -e

function usage {
        echo "Usage: $0 -b <s3_backup> -d <base_target_directory> -t <full|inc>"
        echo "e.g. $0 -b some_bucket -d /mnt/s3_backups -t full"
        exit 1
}

while getopts "b:d:t:" OPT; do
        case "$OPT" in
                b) BUCKET_NAME="$OPTARG" ;;
                d) BASE_DIR="$OPTARG" ;;
                t) TYPE="$OPTARG" ;;
                ?) usage ;;
        esac
done

if [[ -z $BUCKET_NAME ]] || [[ -z $BASE_DIR ]] || [[ -z $TYPE ]]; then
	usage
fi

BUCKET_DIR="$BASE_DIR/$BUCKET_NAME"
WORKING_DIR="$BUCKET_DIR/working_copy"
SNAPSHOT_FILE="$BUCKET_DIR/snapshot.snar"
BACKUP_FILE="$BUCKET_DIR/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
TAR_EXTRA_ARGS=""

if [[ $TYPE == "inc" ]] && [[ ! -e $SNAPSHOT_FILE ]]; then
	echo "Could not find snapshot file at \"$SNAPSHOT_FILE\""
	exit 1
fi

if [[ $TYPE == "full" ]]; then
	TAR_EXTRA_ARGS="--level=0"
fi

s3cmd sync --delete-removed s3://$BUCKET_DIR $WORKING_DIR

tar --create \
	--listed-incremental="$SNAPSHOT_FILE" \
	--file="$BACKUP_FILE" \
	--gzip \
	$TAR_EXTRA_ARGS \
	$WORKING_DIR
