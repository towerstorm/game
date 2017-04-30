source /etc/lsb-release && echo "deb http://download.rethinkdb.com/apt $DISTRIB_CODENAME main" | sudo tee /etc/apt/sources.list.d/rethinkdb.list
wget -qO- https://download.rethinkdb.com/apt/pubkey.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install rethinkdb
sudo apt-get install git

sudo cp ./config/rethinkdb.conf /etc/rethinkdb/instances.d/towerstorm.conf

sudo touch /var/log/rethinkdb
sudo chmod 777 /var/log/rethinkdb

sudo service rethinkdb restart
npm install --production
node database/scripts/db-setup.js 