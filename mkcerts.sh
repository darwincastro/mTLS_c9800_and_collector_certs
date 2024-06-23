#!/usr/bin/env bash

# Load environment variables
export "$(grep -v '^#' .env | xargs)"

# Define colors for output
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Check if openssl is installed
[ ! -x /usr/bin/openssl ] && echo -e "${RED}Openssl not found.${RESET}" && exit 1

# Generate WLC CA key and certificate
echo -e "${CYAN}Generating WLC's CA key${RESET}"
openssl genrsa -out ca_wlc.key 4096 && echo -e "\n${YELLOW}Please add the ROOT-CA information that issues the WLC cert${RESET}"
openssl req -x509 -sha256 -new -nodes -key ca_wlc.key -days 14610 -out ca_wlc.pem -config .ca.cnf

# Generate WLC key and certificate
echo -e "${CYAN}Generating WLC key${RESET}"
openssl genrsa -out wlc.key 4096 && echo -e "\n${YELLOW}Please add the WLC information${RESET}"
openssl req -new -sha256 -key wlc.key -out wlc.csr -config .device.cnf

openssl x509 -req -sha256 -in wlc.csr -CA ca_wlc.pem -CAkey ca_wlc.key -CAcreateserial -days 365 -out wlc.pem > /dev/null 2>&1

# Generate Collector CA key and certificate
echo -e "${CYAN}Generating Collector's CA key${RESET}"
openssl genrsa -out ca_collector.key 4096 && echo -e "\n${YELLOW}Please add the ROOT-CA information that issues the Telegraf cert${RESET}"
openssl req -x509 -sha256 -new -nodes -key ca_collector.key -days 14610 -out ca_collector.pem -config .ca.cnf

# Generate Collector key and certificate
echo -e "${CYAN}Generating Collector key${RESET}"
openssl genrsa -out collector.key 4096 && echo -e "\n${YELLOW}Please add the Collector information${RESET}"
chmod 644 collector.key
openssl req -new -sha256 -key collector.key -out collector.csr -config .device.cnf

openssl x509 -req -sha256 -in collector.csr -CA ca_collector.pem -CAkey ca_collector.key -CAcreateserial -days 365 -extfile collector_extfile.cnf -out collector.pem > /dev/null 2>&1

# Generate PKCS#12 file for WLC
openssl pkcs12 -export -out WLC.pfx -inkey wlc.key -in wlc.pem -certfile ca_wlc.pem -passout pass:${PASS}

# Clean up intermediate files
rm wlc.csr \
  collector.csr \
  ca_wlc.srl \
  ca_collector.srl

# Output instructions for configuring the WLC trustpoints
echo -e "\n${GREEN}Configure the trustpoints in your C9800 using the following:

1st Trustpoint:
The script generates a PKCS#12 file named WLC.pfx, containing the WLC key, WLC certificate, and CA certificate.
Upload the file WLC.pfx to bootflash: and run:

crypto pki import id1 pkcs12 bootflash:WLC.pfx password cisco

2nd Trustpoint:
Where the certificates are placed do: cat ca_collector.pem and copy the certificate's content.
In the WLC terminal run:

config t
crypto pki trustpoint ca1
enrollment terminal
revocation-check none
exit

crypto pki authenticate ca1
<Paste ca_collector.pem content>
${RESET}"

# Output instructions for configuring the Collector
echo -e "\n${GREEN}Configure the Collector certs within \"/etc/telegraf/certs\" using the following commands:

mv ca_wlc.pem /etc/telegraf/certs/ca_wlc.pem
mv collector.pem /etc/telegraf/certs/collector.pem
mv collector.key /etc/telegraf/certs/collector.key
${RESET}\n"