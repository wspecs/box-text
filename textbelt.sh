#!/bin/bash

source /etc/wspecs/global.conf
source /etc/wspecs/functions.sh
source $HOME/.wspecsbox.conf

install_once npm
install_once mutt
install_once nodejs
install_once redis-server

cp textbelt.service /etc/systemd/system/
install_dir=/usr/local/lib
mkdir -p $install_dir
cd $install_dir
chown -R user-data $install_dir
rm -rf $install_dir/textbelt
git_clone https://github.com/wspecs/textbelt.git HEAD '' textbelt

cd textbelt
rm -rf .git

if [[ ! -f .env ]]; then
  touch .env
  TEXT_API_KEY=$(openssl rand -base64 48 | tr -d "=+/" | cut -c1-32)
  add_config TEXT_API_KEYS=$TEXT_API_KEY .env
fi
 npm install

SENDER_EMAIL=text@$(echo $PRIMARY_HOSTNAME | sed s/box.//)
if [[ ! -f lib/config.template.js ]]; then
  mv lib/config.js lib/config.template.js
fi
cat lib/config.template.js | sed "s/SENDER_HOST/$PRIMARY_HOSTNAME/" | sed "s/SENDER_PASSWORD/$TEXT_USER_SECRET/" | sed "s/SENDER_EMAIL/$SENDER_EMAIL/" | sed "s/SENDER_NAME/Text Notifier/" > lib/config.js

/etc/init.d/redis-server start
sudo systemctl enable textbelt.service
systemctl restart textbelt
systemctl daemon-reload
systemctl status textbelt
