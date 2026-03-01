# Wazuh SIEM - Automated Docker Deployment

A fully automated, production-ready deployment of **Wazuh 4.9.0** (Indexer, Manager, Dashboard) secured by an **Nginx HTTPS Reverse Proxy**. 

This project is designed for ease of use, featuring an automated SSL certificate generation and security initialization script.



---

## Prerequisites

Before starting, ensure your system meets these requirements:
* **Docker** & **Docker Compose** installed.
* **System Resources**: Minimum 6GB RAM (8GB or more recommended).
* **OS**: Linux (Ubuntu/Debian preferred) or WSL2.

---

## Quick Start (Automated Setup)

Follow these steps to deploy the entire stack in minutes:

### 1. Clone the repository
```bash
git clone [https://github.com/TheoCaudan/SIEM.git](https://github.com/TheoCaudan/SIEM.git)
cd SIEM
```

### 2. Configure environment variables

Copy the example environment file and edit it if you wish to change default passwords:
```bash
cp .env.example .env
```

### 3. Run the Initialization Script
This script handles the kernel configuration (vm.max_map_count), generates all internal SSL certificates, starts the containers, and initializes the security database.
```bash
chmod +x init-stack.sh
./init-stack.sh
```

## Accessing the Dashboard
Once the script displays "DEPLOYMENT COMPLETED SUCCESSFULLY":

`URL: https://localhost`

Username: admin (or your value in .env)

Password: P@ssw0rd (or your value in .env)

Note: Since we use self-signed certificates for the Nginx proxy, your browser will show a security warning. Click "Advanced" and "Proceed to localhost".

## Project Structure
init-stack.sh: The "brain" of the setup. Automates PKI and security injection.

nginx/: Reverse proxy configuration and SSL certificates.

wazuh/: Contains configurations for Indexer, Manager, and Dashboard.

logstash/ & filebeat/: Data collection pipeline for external logs.

## Troubleshooting

| Issue | Solution |
| :--- | ---: |
| 502 Bad Gateway | The Dashboard is still starting. Wait 60 seconds and refresh. |
| Indexer Crashes | Ensure your host has enough RAM. Check docker logs wazuh-indexer. |
| 401 Unauthorized | Verify that your INDEXER_PASSWORD_HASH in .env matches your password. |

## Monitoring New Machines (Agents)

To start supervising a new server or workstation:

1.  **Open Wazuh Dashboard**: Go to `Agents` > `Deploy new agent`.
2.  **Configure**:
    * **OS**: Select your target OS.
    * **Manager Address**: Enter the **IP of your SIEM server**.
    * **Agent Name**: Give it a friendly name (e.g., `Web-Server-01`).
3.  **Install**: Copy and run the generated command on the target machine.
4.  **Start Service**: Ensure the `wazuh-agent` service is started.

The machine will appear in the **Security Events** and **Integrity Monitoring** tabs within 2 minutes.

