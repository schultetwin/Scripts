#!/usr/bin/env bash

error(){
  local message=$1
  local email=$2
  local subject="Error backup ejrst.net"
  local emailmessage="/tmp/emailmessage.txt"
  touch $emailmessage
  echo "An error, ${message}, occured while backing up ejrst.net" > $emailmessage
  /bin/mail -s "$subject" "$email" < $emailmessage
}

# need site to backup
if [ $# != 1 ]
then
  echo "Need to specify site to backup"
  exit 4
fi
# settings
backup="/home/jrsteds/public_html/$1/sites/default"
target="/home/jrsteds/backups/$1/sites"
exclude="/home/jrsteds/backups/exclude.txt"
email="schultetwin@gmail.com"

if [ ! -d ${target} ]
then
  echo "Site files do not exist"
  error "Site files do not exist" ${email}
  exit 2
fi
if [ ! -d ${backup} ]
then
  mkdir -p ${backup}
fi

# date for this backup
date=`date "+%Y-%m-%dT%H_%M_%S"`

# check and create lockfile
if [ -f ${target}/lockfile ]
then
  echo "Lockfile exists, backup stopped."
  error "Lock file exists, backup stopped" ${email}
  exit 2
else
  touch ${target}/lockfile
fi

# create folders if neccessary
if [ ! -e ${target}/current ]
then
  mkdir -p ${target}/current
fi
if [ ! -d ${target}/weekly ]
then
  mkdir ${target}/weekly
fi
if [ ! -d ${target}/daily ]
then
  mkdir ${target}/daily
fi
if [ ! -d ${target}/hourly ]
then
  mkdir ${target}/hourly
fi

# rsync
rsync \
--archive \
--xattrs \
--human-readable \
--delete \
--link-dest=${target}/current \
--exclude-from ${exclude} \
$backup \
$target/$date-incomplete

if [[$? != 0]] ; then
  error "Rsync failed" ${email}
fi

# backup complete
mv $target/$date-incomplete ${target}/hourly/$date
rm -r ${target}/current
ln -s ${target}/hourly/$date ${target}/current
touch ${target}/hourly/$date

# keep daily backup
if [ `find ${target}/daily -maxdepth 1 -type d -mtime -2 -name "20*" | wc -l` -eq 0 ] && [ `find ${target}/hourly -maxdepth 1 -name "20*" | wc -l` -gt 1 ]
then
  oldest=`ls -1 -tr ${target}/hourly/ | head -1`
  mv ${target}/hourly/$oldest ${target}/daily/
fi

# keep weekly backup
if [ `find ${target}/weekly -maxdepth 1 -type d -mtime -14 -name "20*" | wc -l` -eq 0 ] && [ `find ${target}/daily -maxdepth 1 -name "20*" | wc -l` -gt 1 ]
then
  oldest=`ls -1 -tr ${target}/daily/ | head -1`
  mv ${target}/daily/$oldest ${target}/weekly/
fi

# delete old backups
find ${target}/hourly -maxdepth 1 -type d -mtime +0 | xargs rm -rf
find ${target}/daily -maxdepth 1 -type d -mtime +7 | xargs rm -rf

# remove lockfile
rm ${target}/lockfile
