#!/usr/bin/env bash

if [[ "${LOGNAME}" != "root" ]]; then
  echo "Sorry. Only root can start the script." >&2
  exit 1
fi

function err()
{
  echo "[$(date +'%d-%m-%YT%H:%M:%S%z')]: $@" >&2
  return $?
}

function mysql_secure_options()
{
  sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' <<- _EOF_ | mysql_secure_installation
 
y
zxc
zxc
y
y
y
y
_EOF_

return $?
}

function write_repo()
{
  cat <<- _EOF_
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
_EOF_
  return $?
}

touch /etc/yum.repos.d/MariaDB.repo && chmod +w /etc/yum.repos.d/MariaDB.repo
if [[ "$?" -ne 0 ]]; then
  err "Creating repo-file error"
  exit 1
fi

write_repo > /etc/yum.repos.d/MariaDB.repo

yum install mariadb-server -y
if [[ "$?" -ne 0 ]]; then
  err "Installing MariaDB-server error"
  exit 1
fi

systemctl enable mariadb && systemctl start mariadb
if [[ "$?" -ne 0 ]]; then
  err "Starting MariaDB error"
  exit 1
fi

if [[ "$(systemctl is-active mariadb)" -ne "active" ]]; then
  echo "MariaDB-server is no active"
  exit 1
fi

mysql_secure_options
if [[ "$?" -ne 0 ]]; then
  err "MySQL secure options error"
  exit 1
fi

exit 0

