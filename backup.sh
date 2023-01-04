#!/bin/bash

backup () {
  BACKUP_NAME=$1
  BACKUP_SOURCE_BASE_FOLDER=$2
  BACKUP_TARGET_BASE_FOLDER=$3
  BACKUP_SOURCE_RELATIVE_SUBFOLDERS=$4
  BACKUP_TARGET_FOLDER=$BACKUP_TARGET_BASE_FOLDER/$BACKUP_NAME
  SCRIPT_FOLDER=$PWD
  DATE_STRING=`date '+%Y-%m-%d'`
  LOG_FILE_PATH="$BACKUP_TARGET_FOLDER"/"$BACKUP_NAME"_"$DATE_STRING".log
  PASSPHRASE_FILE_PATH="$BACKUP_TARGET_FOLDER"/"$BACKUP_NAME"_"$DATE_STRING".key
  TARGET_FILE_PATH="$BACKUP_TARGET_FOLDER"/"$BACKUP_NAME"_"$DATE_STRING".tar.gz.gpg.part
  FILE_SUM_FILE_PATH="$BACKUP_TARGET_FOLDER"/"$BACKUP_NAME"_"$DATE_STRING".sum

  exec > $LOG_FILE_PATH
  exec 2>&1

  if [ "$#" -lt 3 ];
  then
    echo "Illegal number of parameters: $#"
    return 1
  fi

  if [[ -z "$3" ]];
  then
    BACKUP_SOURCE_RELATIVE_SUBFOLDERS="."
  fi

  echo "Starting backup "$BACKUP_NAME" from source $BACKUP_SOURCE_BASE_FOLDER to target $BACKUP_TARGET_BASE_FOLDER with sub folders $BACKUP_SOURCE_RELATIVE_SUBFOLDERS"

  ls -la $BACKUP_TARGET_BASE_FOLDER > /dev/null
  ls -la $BACKUP_SOURCE_BASE_FOLDER > /dev/null

  set -x

  cd $BACKUP_SOURCE_BASE_FOLDER
  mkdir -p $BACKUP_TARGET_FOLDER

  openssl rand -base64 -out $PASSPHRASE_FILE_PATH 64

  tar cfv - $BACKUP_SOURCE_RELATIVE_SUBFOLDERS | pigz - | gpg --cipher-algo AES256 --batch --passphrase-file $PASSPHRASE_FILE_PATH --compress-algo none -o - -c - | split -b 10GB - $TARGET_FILE_PATH

  sha256sum $TARGET_FILE_PATH* > $FILE_SUM_FILE_PATH

  echo "Finished backup"
}
