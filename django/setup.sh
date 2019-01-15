#!/bin/bash

# Make sure CentOs software collections is in repos.d for newer packages
if [[ !$(/usr/bin/yum repolist | /usr/bin/grep -i -q 'centos-sclo') ]]; then
  echo "CentOS Software Collections already installed"
else
  echo "Need to install CentOS Software Collections"
  yum install -y -q centos-release-scl
fi

# Install required packages
yum install -y -q rh-python35-python
. /opt/rh/rh-python35/enable
pip install --upgrade pip
pip install Django==2.1.5

/usr/bin/grep '. /opt/rh/rh-python35/enable' /home/$(logname)/.bashrc
ENABLED=$?

if [[ "$ENABLED" != "0" ]]; then
  echo 'Adding Python 3.5 to logged in user path'
  echo -e "\n. /opt/rh/rh-python35/enable" >> /home/$(logname)/.bashrc
fi
