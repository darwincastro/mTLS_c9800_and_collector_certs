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

# Generate CA key
echo -e "${CYAN}Generating CA key${RESET}"
openssl genrsa -out ca.key && echo -e "\n${YELLOW}Please add the ROOT-CA information${RESET}"
openssl req -x509 -sha256 -new -nodes -key ca.key -days 14610 -out ca.pem -config .ca.cnf

# Generate WLC key and certificate
echo -e "${CYAN}Generating WLC key${RESET}"
openssl genrsa -out wlc.key 4096 && echo -e "\n${YELLOW}Please add the WLC information${RESET}"
openssl req -new -sha256 -key wlc.key -out wlc.csr -config .device.cnf

openssl x509 -req -sha256 -in wlc.csr -CA ca.pem -CAkey ca.key -CAcreateserial -days 365 -out wlc.pem > /dev/null 2>&1

# Generate Collector key and certificate
echo -e "${CYAN}Generating Collector key${RESET}"
openssl genrsa -out collector.key 4096 && echo -e "\n${YELLOW}Please add the Collector information${RESET}"
openssl req -new -sha256 -key collector.key -out collector.csr -config .device.cnf
openssl x509 -req -sha256 -in collector.csr -CA ca.pem -CAkey ca.key -CAcreateserial -days 365 -extfile collector_extfile.cnf -out collector.pem > /dev/null 2>&1

# Generate PKCS#12 file for WLC
openssl pkcs12 -export -out WLC.pfx -inkey wlc.key -in wlc.pem -certfile ca.pem -passout pass:${PASS}

# Clean up intermediate files
rm wlc.csr \
  collector.csr \
  ca.srl

# Output instructions for configuring the trustpoint
echo -e "\n${GREEN}Configure the trustpoint in your network WLC using the following:

crypto pki import <trustpoint name> pem terminal password cisco
 <paste contents of ca.pem>
 <paste contents of wlc.key>
 <paste contents of wlc.pem>${RESET}\n"

# Output instructions for configuring the Collector
echo -e "\n${GREEN}Configure the Collector certs within \"/etc/telegraf/telegraf.d\" using the following commands:

mv ca.pem /etc/telegraf/certs/ca.pem
mv collector.pem /etc/telegraf/certs/collector.pem
mv collector.key /etc/telegraf/certs/collector.key${RESET}\n"