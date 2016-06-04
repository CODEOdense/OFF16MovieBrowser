# NB This file should only be used for configuring a new box

echo "******************************************"
echo "************** ADDONS ********************"
echo "******************************************"

echo "** UPDATING NPM**"
sudo npm cache clean -f
sudo npm install -g npm
sudo npm cache clean -f

echo "** SETTING UP PM2 NODE SCRIPT STARTER **"
npm install pm2 -g

each "** INSTALLING ARANGODB **"
wget https://www.arangodb.com/repositories/arangodb2/xUbuntu_14.04/Release.key
sudo apt-key add Release.key
sudo apt-add-repository 'deb https://www.arangodb.com/repositories/arangodb2/xUbuntu_14.04/ /'
sudo apt-get update
sleep 1
sudo apt-get install arangodb=2.8.9 -y
sudo sed -i "s/endpoint = tcp:\/\/127.0.0.1:8529/endpoint = tcp:\/\/192.168.57.10:8529/g" /etc/arangodb/arangod.conf
sudo sed -i "s/endpoint = tcp:\/\/127.0.0.1:8529/endpoint = tcp:\/\/192.168.57.10:8529/g" /etc/arangodb/arangosh.conf
sudo service arangodb stop
sudo arangod --upgrade
sudo service arangodb start
sleep 2
curl -H 'Content-Type: application/json' -X PUT -d '{"url": "CODEOdense/OFF16Data", "version": ""}' http://192.168.57.10:8529/_db/_system/_admin/aardvark/foxxes/git?mount=%2Foff2016
