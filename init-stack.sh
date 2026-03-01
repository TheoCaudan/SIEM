#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==> 0. System config (Virtual memory)...${NC}"
if [ $(sysctl -n vm.max_map_count) -lt 262144 ]; then
  echo "Config of vm.max_map_count to 262144..."
  sudo sysctl -w vm.max_map_count=262144
else
  echo "System config already OK."
fi

echo -e "${BLUE}==> 1. Network check...${NC}"
NETWORK_NAME="orchestration_net"
if [ ! "$(docker network ls | grep $NETWORK_NAME)" ]; then
  echo "Network creation $NETWORK_NAME..."
  docker network create $NETWORK_NAME
else
  echo "Network $NETWORK_NAME already exists."
fi

echo -e "${BLUE}==> 2. Nginx folders and certificates prep...${NC}"
mkdir -p ./nginx/certs
if [ ! -f "./nginx/certs/nginx-selfsigned.crt" ]; then
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ./nginx/certs/nginx-selfsigned.key \
    -out ./nginx/certs/nginx-selfsigned.crt \
    -subj "/C=FR/ST=Isere/L=Grenoble/O=IT/CN=localhost"
  echo -e "${GREEN}Nginx certificates generated.${NC}"
else
  echo "Nginx certificates already exist."
fi

echo -e "${BLUE}==> 3. Countainers lauching...${NC}"
docker compose up -d

echo -e "${BLUE}==> 4. Wait for Indexer start (about 45s)...${NC}"
until curl -k -s https://localhost:9200 > /dev/null; do
  echo -n "."
  sleep 5
done
echo -e "\n${GREEN}Indexer ready !${NC}"

echo -e "${BLUE}==> 5. OpenSearch Security init...${NC}"
docker exec -it wazuh-indexer /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
  -cd /usr/share/wazuh-indexer/securityconfig/ \
  -icl -nhnv \
  -cacert /usr/share/wazuh-indexer/config/certs/root-ca.pem \
  -cert /usr/share/wazuh-indexer/config/certs/admin.pem \
  -key /usr/share/wazuh-indexer/config/certs/admin-key.pem \
  -h localhost

echo -e "${BLUE}==> 6. Final restart of web services...${NC}"
docker compose restart nginx wazuh-dashboard

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}SUCCESS : Your SIEM is ready !${NC}"
echo -e "${GREEN}Access : https://localhost${NC}"
echo -e "${GREEN}==================================================${NC}"
