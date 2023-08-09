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

  sshpass -p ${remoteServerSshPassword} ssh ${sshOptions} ${remoteServerUser}@${remoteServerIp} pwd
  if [ $? != 0 ]; then
    echo "ERROR! can't not connect to remote server."
    exit 1
  fi

  array=(${backupFile//\// })
  export BACKUP_NAME=${array[0]}
  export BACKUP_FILE=${array[1]}

  gs_probackup init -B /backup/gauss/backups
  echo "INFO gs_probackup init finished. "

  gs_probackup add-instance -B /backup/gauss/backups -D /backup/gauss/datanode/dn1 --instance=${BACKUP_NAME}
  echo "INFO gs_probackup add-instance finished. "
}

function prepareBackupFile() {
  sshpass -p ${remoteServerSshPassword} scp -rq   ${sshOptions} \
            ${remoteServerUser}@${remoteServerIp}:/data/backups/${backupFile}  \
            /backup/gauss/backups/backups/${BACKUP_NAME}/

  echo "Copy backup file ${backupFile} from remote server."
}

function restoreGaussdb() {

  \cp -rf /backup/gauss/datanode/dn1/postgresql.conf /home/omm/

  if [ ! -f /backup/gauss/backups/backups/${backupFile}/pg_probackup.conf ];then
    echo "ERROR backup file does not contain pg_probackup.conf. "
    return 0
  else
    \cp -f /backup/gauss/backups/backups/${BACKUP_NAME}/pg_probackup.conf /home/omm/
  fi

  echo "INFO backup postgresql.conf and pg_probackup.conf. "

  \rm -rf /backup/gauss/datanode/dn1/*
  echo "Clean up opengauss data dir /backup/gauss/datanode/dn1/* . "

  \mv -f   /backup/gauss/backups/backups/${backupFile}/pg_probackup.conf /backup/gauss/backups/backups/${BACKUP_NAME}/
  gs_probackup restore  -B /backup/gauss/backups/ --instance=${BACKUP_NAME}  \
               -D /backup/gauss/datanode/dn1  -h /backup/gauss/tmp  \
               -p 5432 -j 8 -U rep1 -W asdfg.1314 -i ${BACKUP_FILE}

  \mv -f /home/omm/postgresql.conf /backup/gauss/datanode/dn1/postgresql.conf
  \mv -f /home/omm/pg_probackup.conf /backup/gauss/backups/backups/${BACKUP_NAME}/pg_probackup.conf
  echo "INFO restore postgresql.conf and pg_probackup.conf. "

  echo "INFO gs_probackup restore finished. "
}

function cleanBackupfile() {
  \rm -rf /backup/gauss/backups/backups/${backupFile}
  echo "Clean up backup file in local dir /backup/gauss/backups/backups/${backupFile} "
}

function main() {
  restoreInit
  prepareBackupFile
  restoreGaussdb
  cleanBackupfile
}

main
