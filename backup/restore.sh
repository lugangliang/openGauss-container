#!/usr/bin/env bash

remoteServerUser=${TransferUsername}
remoteServerIp=${address}
remoteServerSshPassword=${TransferPassword}
transMode=${mode}
sshOptions=' -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null '

function restoreInit() {
  if [ -z ${backupFile} ]; then
    echo "ERROR can't find backup file from env. "
    exit 1
  fi

  array=(${backupFile//\// })
  export BACKUP_NAME=${array[0]}
  export BACKUP_FILE=${array[1]}

  \rm -rf /backup/gauss/datanode/dn1/*
  echo "Clean up opengauss data dir /backup/gauss/datanode/dn1/* . "
}

function prepareBackupFile() {
  sshpass -p ${remoteServerSshPassword} ssh ${sshOptions} ${remoteServerUser}@${remoteServerIp} pwd
  if [ $? != 0 ]; then
    echo "ERROR! can't not connect to remote server."
    exit 1
  fi

  mkdir -p /backup/gauss/backups/backups/${BACKUP_NAME}/

  sshpass -p ${remoteServerSshPassword} scp -rq   ${sshOptions} \
            ${remoteServerUser}@${remoteServerIp}:/data/backups/${backupFile}  \
            /backup/gauss/backups/backups/${BACKUP_NAME}/

  echo "Copy backup file ${backupFile} from remote server."
}

function restoreGaussdb() {
  gs_probackup restore  -B /backup/gauss/backups/ --instance=${BACKUP_NAME} -b FULL \
               -D /backup/gauss/datanode/dn1  -h /backup/gauss/tmp  \
               -p 5432 -j 8 -U rep1 -W asdfg.1314 -i ${BACKUP_FILE}
}

function cleanBackupfile() {
  \rm -rf /backup/gauss/backups/backups/${backupFile}
  ehco "Clean up backup file in local dir /backup/gauss/backups/backups/${backupFile}. "
}

function main() {
  restoreInit
  prepareBackupFile
  restoreGaussdb
  cleanBackupfile
}

main
