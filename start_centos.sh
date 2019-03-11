#!/usr/bin/env bash

if [[ "${LOGNAME}" != "root" ]]; then
  echo "Sorry. Only root can start the script." >&2
  exit 1
fi

yum update -yy \
	&& yum upgrade -yy \
	&& yum -yy install wget vim htop net-tools gpm bind-utils

yum install -yy https://centos7.iuscommunity.org/ius-release.rpm \
        && yum install -yy python36u python36u-devel python36u-pip

if [[ "$?" -eq 0 ]]; then
  reboot
fi
exit 0
