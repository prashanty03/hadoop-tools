#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./install-zeppelin.sh <master>"
  exit -1
fi

MASTER=$1

#ZEPPELIN_NOTEBOOK_S3_BUCKET=$3
#ZEPPELIN_NOTEBOOK_S3_USER=$4

echo "MASTER: $MASTER"

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "Downloading Zeppelin...."
cd /usr/lib
sudo curl -O https://s3-us-west-2.amazonaws.com/noetl-provisioning-us-west-2/emr-4.7.1/zeppelin.tar.gz
echo "Installing Zeppelin...."
sudo tar zxf zeppelin.tar.gz
sudo rm -rf zeppelin.tar.gz

echo "Configuring dirs for Zeppelin...."
sudo mkdir -p /mnt/var/log/zeppelin /mnt/var/lib/zeppelin/local-repo /mnt/var/lib/zeppelin/notebook /mnt/var/lib/zeppelin/webapps /mnt/var/run/zeppelin
sudo cp -R $DIR/zeppelin-notebook/* /mnt/var/lib/zeppelin/notebook/
sudo chown -R hadoop:hadoop /mnt/var/log/zeppelin /mnt/var/lib/zeppelin /mnt/var/run/zeppelin /usr/lib/zeppelin/conf

echo "Configuring Zeppelin...."

# set MASTER and other variables in template
sed -i -e "s/\${MASTER}/${MASTER}/g" $DIR/zeppelin/conf/interpreter.json
sed -i -e "s/\${exec_mem}/${exec_mem}/g" $DIR/zeppelin/conf/interpreter.json

sudo cp -R $DIR/zeppelin /etc/
sudo chown -R hadoop:hadoop /etc/zeppelin/conf

cd /usr/lib/zeppelin
sudo rm -rf local-repo
sudo ln -s /mnt/var/lib/zeppelin/local-repo

echo "Configuring Zeppelin done"

sudo su - hadoop -c 'cat >> ~/.bashrc << EOL
export PATH=\$PATH:/usr/lib/zeppelin/bin
EOL'

#set +e
#echo "Trying to create s3n://${ZEPPELIN_NOTEBOOK_S3_BUCKET}/${ZEPPELIN_NOTEBOOK_S3_USER}/notebook folder"
#su - hadoop -c 'hadoop fs -mkdir -p s3n://${ZEPPELIN_NOTEBOOK_S3_BUCKET}/${ZEPPELIN_NOTEBOOK_S3_USER}/notebook'
#set -e

echo "Starting Zeppelin..."
sudo su - hadoop -c '/usr/lib/zeppelin/bin/zeppelin-daemon.sh start'
echo "done"
echo "Zeppelin          http://${MASTER}:8890"
