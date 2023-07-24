#!/usr/bin/env bash

gaussdbSlaveIp=${instanceIp}
remoteServerUser=${TransferUsername}
remoteServerIp=${address}
remoteServerSshPassword=${TransferPassword}
transMode=${mode}
backupPassword=${BrPassword}
backupUser=${BrUsername}
sshOptions=' -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null '

function backupInit() {
  gs_probackup init -B /data/GSbackup
}

function transferBackup() {
  sshpass -p ${remoteServerSshPassword} ssh ${sshOptions} ${remoteServerUser}@${remoteServerIp} pwd
  if [ $? != 0 ]; then
    echo "ERROR! can't not connect to remote server."
    exit 1
  fi

  sshpass -p ${remoteServerSshPassword} ssh ${sshOptions} ${remoteServerUser}@${remoteServerIp} \
             mkdir -p /data/backups/opengaussbk_${gaussdbSlaveIp}

  backupFile=`ls /data/GSbackup/backups/opengaussbk_${gaussdbSlaveIp}/ | grep -v conf`

  sshpass -p ${remoteServerSshPassword} scp -rq   ${sshOptions} \
            /data/GSbackup/backups/opengaussbk_${gaussdbSlaveIp}/${backupFile} \
            ${remoteServerUser}@${remoteServerIp}:/data/backups/opengaussbk_${gaussdbSlaveIp}
}

function backupGaussdb() {

  gs_probackup add-instance -B /data/GSbackup -D /backup/gauss/datanode/dn1 --instance=opengaussbk_${gaussdbSlaveIp}

  gs_probackup backup -B /data/GSbackup --instance=opengaussbk_${gaussdbSlaveIp} -b FULL \
               -U ${backupUser} -W ${backupPassword} -h /backup/gauss/tmp  -d postgres -p 5432
}

function startGaussdb() {
  gs_ctl start -D /var/lib/opengauss/data -Z single_node
  sleep 5
}

function stopGaussdb() {
      gs_ctl stop -D /var/lib/opengauss/data
}

function main() {
    startGaussdb
    backupInit
    backupGaussdb
    transferBackup
    stopGaussdb
}

main