# SIEM

## Pre-requis:

## Sur l'hote :
Ouvrir le port 1514 en tcp et udp et le port 1515 en tcp pour l'enregistrement auto des nouveaux agents

Pour le certificat SSL pour le Wazuh-dashboard :

Dans ~/SIEM/wazuh/wazuh-certs:
```
cd ~/SIEM/wazuh/wazuh-certs
curl -sO https://packages.wazuh.com/4.9/wazuh-certs-tool.sh
curl -sO https://packages.wazuh.com/4.9/config.yml
bash wazuh-certs-tool.sh -A
```
Créer les dossiers dashboard_certs et certs :
```
cd ~/SIEM
mkdir -p ./wazuh/dashboard_certs
cp ./wazuh-certificates/wazuh-dashboard.pem ./wazuh/dashboard_certs/dashboard.pem
cp ./wazuh-certificates/wazuh-dashboard-key.pem ./wazuh/dashboard_certs/dashboard-key.pem
cp ./wazuh-certificates/root-ca.pem ./wazuh/dashboard_certs/root-ca.pem

mkdir -p ./wazuh/indexer_conf/certs
cp ./wazuh-certificates/wazuh-indexer* ./wazuh/indexer_conf/certs/
cp ./wazuh-certificates/root-ca.pem ./wazuh/indexer_conf/certs/
```
/!\ - Ajuster les permissions
```
sudo chown -R 1000:1000 ./wazuh/dashboard_certs
sudo chmod -R 500 ./wazuh/dashboard_certs
sudo chmod 400 ./wazuh/dashboard_certs/*.pem
```
## Sur la machine distante

Lors de l'installation de l'agent sur la VM distante il faudra spécifier l'adresse IP de votre hôte :
```
WAZUH_MANAGER="IP_VM" apt-get install wazuh-agent
```
