#!/usr/bin/env bash

PGDATADIR="/var/lib/opengauss/data"
gaussdbSlaveIp=${instanceIp}
remoteServerUser=${TransferUsername}
remoteServerIp=${address}
remoteServerSshPassword=${TransferPassword}
transMode=${mode}
backupPassword=${BrPassword}
backupUser=${BrUsername}
sshOptions=' -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null '


function backupInit() {
  gs_probackup init -B /backup/gauss/backups
}

function cleanupBackupfile() {
  \rm -rf /backup/gauss/backups/backups/opengaussbk_${gaussdbSlaveIp}
  \rm -rf /backup/gauss/backups/wal/opengaussbk_${gaussdbSlaveIp}
  echo "Success to clean backup file. /backup/gauss/backups/backups/opengaussbk_${gaussdbSlaveIp}/${backupFile}"
}

function transferBackup() {
  sshpass -p ${remoteServerSshPassword} ssh ${sshOptions} ${remoteServerUser}@${remoteServerIp} pwd
  if [ $? != 0 ]; then
    echo "ERROR! can't not connect to remote server."
    exit 1
  fi

  sshpass -p ${remoteServerSshPassword} ssh ${sshOptions} ${remoteServerUser}@${remoteServerIp} \
             mkdir -p /data/backups/opengaussbk_${gaussdbSlaveIp}

  backupFile=`ls /backup/gauss/backups/backups/opengaussbk_${gaussdbSlaveIp}/ | grep -v conf`

  sshpass -p ${remoteServerSshPassword} scp -rq   ${sshOptions} \
            /backup/gauss/backups/backups/opengaussbk_${gaussdbSlaveIp}/${backupFile} \
            ${remoteServerUser}@${remoteServerIp}:/data/backups/opengaussbk_${gaussdbSlaveIp}

  if [ $? == 0 ] ; then
      echo "Success send backup file ${backupFile} to remote backup server. "
  else
      echo "Error, failed send backup file ${backupFile} to remote backup server."
      exit 1
  fi

}

function backupGaussdb() {

  gs_probackup add-instance -B /backup/gauss/backups -D /backup/gauss/datanode/dn1 --instance=opengaussbk_${gaussdbSlaveIp}

  gs_probackup backup -B /backup/gauss/backups --instance=opengaussbk_${gaussdbSlaveIp} -b FULL \
               -U ${backupUser} -W ${backupPassword} -h /backup/gauss/tmp  -d postgres -p 5432
}

function startGaussdb() {
  gs_ctl start -D ${PGDATADIR} -Z single_node
  sleep 5
}

function stopGaussdb() {
      gs_ctl stop -D ${PGDATADIR}
}

function main() {
    startGaussdb
    backupInit
    backupGaussdb
    transferBackup
    cleanupBackupfile
    stopGaussdb
}

main