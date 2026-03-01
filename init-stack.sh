#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' 

echo -e "${BLUE}==> [1/6] Configuring host system requirements...${NC}"

sudo sysctl -w vm.max_map_count=262144

docker network create orchestration_net 2>/dev/null || true

echo -e "${BLUE}==> [2/6] Creating directory structure...${NC}"
mkdir -p ./nginx/certs
mkdir -p ./wazuh/indexer_conf/certs
mkdir -p ./wazuh/wazuh-certs/wazuh-certificates
mkdir -p ./wazuh/manager_etc ./wazuh/manager_logs
mkdir -p ./wazuh/dashboard_certs

echo -e "${BLUE}==> [3/6] Generating Internal PKI Certificates (Wazuh Tool)...${NC}"

if [ ! -f "./wazuh/wazuh-certs/wazuh-certs-tool.sh" ]; then
    curl -s -o ./wazuh/wazuh-certs/wazuh-certs-tool.sh https://packages.wazuh.com/4.x/config/wazuh-certs-tool.sh
    chmod +x ./wazuh/wazuh-certs/wazuh-certs-tool.sh
fi

bash ./wazuh/wazuh-certs/wazuh-certs-tool.sh -A -c ./wazuh/wazuh-certs/config.yml -o ./wazuh/wazuh-certs/wazuh-certificates/

echo "Distributing certificates to service volumes..."

cp ./wazuh/wazuh-certs/wazuh-certificates/wazuh-indexer* ./wazuh/indexer_conf/certs/
cp ./wazuh/wazuh-certs/wazuh-certificates/root-ca.pem ./wazuh/indexer_conf/certs/
cp ./wazuh/wazuh-certs/wazuh-certificates/admin* ./wazuh/indexer_conf/certs/

cp ./wazuh/wazuh-certs/wazuh-certificates/root-ca.pem ./wazuh/wazuh-certs/wazuh-certificates/

echo -e "${BLUE}==> [4/6] Generating Nginx SSL Certificate (Public Front-end)...${NC}"
if [ ! -f "./nginx/certs/nginx-selfsigned.crt" ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout ./nginx/certs/nginx-selfsigned.key \
      -out ./nginx/certs/nginx-selfsigned.crt \
      -subj "/C=US/ST=State/L=City/O=IT/CN=localhost"
    echo -e "${GREEN}Nginx certificates created.${NC}"
fi

echo -e "${BLUE}==> [5/6] Starting Docker Containers...${NC}"
docker compose up -d

echo -e "${BLUE}==> [6/6] Initializing Indexer Security (securityadmin)...${NC}"
echo "Waiting for Indexer API to become responsive (this may take a minute)..."
until curl -k -s https://localhost:9200 > /dev/null; do
    echo -n "."
    sleep 5
done
echo -e "\n${GREEN}Indexer is online. Running securityadmin.sh...${NC}"

docker exec -it wazuh-indexer /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
  -cd /usr/share/wazuh-indexer/securityconfig/ \
  -icl -nhnv \
  -cacert /usr/share/wazuh-indexer/config/certs/root-ca.pem \
  -cert /usr/share/wazuh-indexer/config/certs/admin.pem \
  -key /usr/share/wazuh-indexer/config/certs/admin-key.pem \
  -h localhost

echo -e "${BLUE}Finalizing services...${NC}"
docker compose restart wazuh-dashboard nginx

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}       DEPLOYMENT COMPLETED SUCCESSFULLY         ${NC}"
echo -e "${GREEN}   You can now access your SIEM at:              ${NC}"
echo -e "${GREEN}   https://localhost                             ${NC}"
echo -e "${GREEN}==================================================${NC}"
