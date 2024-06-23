# OpenSSL Certificate Generation Script

This script generates a Certificate Authority (CA) and two device certificates for Mutual-TLS (mTLS) exchange between a WLC and Telegraf server(s) both certificates are signed by the same CA. The certificates are used for securing communication between network devices and a Telegraf server.
***
## Prerequisites

OpenSSL v1.1.1f or LibreSSL 3.3.6
***
## Steps to generate the certificate bundle:

1. Clone the repository, and go to the directory.

```sh
git clone https://github.com/darwincastro/mTLS_c9800_and_collector_certs.git
cd mTLS_c9800_and_collector_certs
```
2. Update `collector_extfile.cnf`

This script will append Subject Alternative Names (SAN) for the Telegraf server, which helps with WLC validation. Users need to update the collector_extfile.cnf file accordingly. You can add or remove DNS names and IP addresses as needed.

Example;

```sh
nano collector_extfile.cnf
```

```sh
subjectAltName = @alt_names

[alt_names]
DNS.1 = collector1.example.com
DNS.2 = collector2.example.com
DNS.3 = collector3.example.com
IP.1 = 192.168.10.1
IP.2 = 192.168.10.2
IP.3 = 192.168.10.3
```
***
> **Note:**
>Update or delete the entries in `collector_extfile.cnf` based on your requirements. Each subjectAltName can be on a new line for better readability.
***

3. Run the script:

```sh
./mkcerts.sh
```
The script checks if OpenSSL is installed on your system. If not, it exits with an error message.

**The output should look like the following:**

![cloning repository](./examples/image1.png)

4. The first block of information belongs to the CA that issues the WLC certificate, use any information that you like, and make sure to use your domain name under the "common name" section, like; "cx.example.com"

![CA Information_WLC](./examples/image2.png)

5. The second block belongs to the Cisco C9800 controller

![WLC Information](./examples/image3.png)

6. The Fourth block belongs to the CA that issues the Telegraf certificate, use any information that you like, and make sure to use your domain name under the "common name" section, like; "example.com"

![CA Information_collector](./examples/image4.png)

7. The Fifth block belongs to the Telegraf server

![Telegraf Information](./examples/image5.png)
***

## Output

The following represents the content decoded of `collector.pem` we included DNS addresses and IP addresses

![collector_,pem_decoded](./examples/image6.png)

## Configure the Trustpoint in Your C9800

Use the following commands to configure the trustpoint:

```
crypto pki import <trustpoint name> pem terminal password cisco
 <paste contents of ca.pem>
 <paste contents of wlc.key>
 <paste contents of wlc.pem>
```

***
> **Note:**
>The script also generates a PKCS#12 file named WLC.pfx, containing the WLC key, WLC certificate, and CA certificate.
***

### 1st Trustpoint
Upload the file WLC.pfx to `bootflash:` and run:

```sh
crypto pki import id1 pkcs12 bootflash:WLC.pfx password cisco 
```

### 2nd 

Where the certificates are placed do cat `ca_collector.pem` and copy the certificate's content.
In the WLC terminal run:

```sh
config t
crypto pki trustpoint ca1
enrollment terminal
revocation-check none
exit
```

```sh
crypto pki authenticate ca1
<Paste ca_collector.pem content>
```

### Collector Certs in Telegraf

Move the generated certs to the appropriate directory for Telegraf:
```sh
mv ca_wlc.pem /etc/telegraf/certs/ca_wlc.pem
mv collector.pem /etc/telegraf/certs/collector.pem
mv collector.key /etc/telegraf/certs/collector.key
```
***
> [!IMPORTANT]  
> - Ensure the .ca.cnf and .device.cnf configuration files are correctly set up and present in the same directory as the script.
> - The script assumes the password specified in the .env file is cisco. Adjust the password as needed.
> - Ensure you have the necessary permissions to move and access these files.
> - Ensure you have the necessary permissions to move and access these files.
***

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

***