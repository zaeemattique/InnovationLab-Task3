# NGINX Load Balancer Setup on AWS EC2

This project demonstrates the setup and configuration of an **NGINX Load Balancer** on an **Amazon EC2 instance** to distribute incoming traffic evenly across two backend web servers. The architecture was designed and deployed manually using AWS infrastructure components, ensuring proper network segmentation, routing, and secure access.

---

## Project Overview

The goal of this project was to:
- Deploy a custom **VPC** with public and private subnets.
- Launch and configure two backend EC2 instances running **Apache (httpd)** web servers.
- Set up an **NGINX Load Balancer** on a public EC2 instance to distribute incoming traffic between the backend servers.
- Test and verify the load balancing behavior using different algorithms such as **Round Robin**, **Least Connections**, and **IP Hash**.

---

## Architecture
![alt text](https://raw.githubusercontent.com/zaeemattique/InnovationLab-Task3/refs/heads/main/Task3%20Architecture.jpg)
The architecture consists of:

- **VPC:** `10.0.0.0/16`
- **Public Subnet:** `10.0.1.0/24` (for Load Balancer)
- **Private Subnet:** `10.0.2.0/24` (for Backend Servers)
- **Internet Gateway** attached to the VPC
- **NAT Gateway** for outbound traffic from private instances
- **Security Groups**:
  - Public SG: Allows inbound SSH (22) and HTTP (80)
  - Private SG: Allows HTTP (80) only from the Load Balancer SG

---

## Infrastructure Setup

### Step 1: VPC and Networking
1. Created a custom **VPC**, public, and private subnets.
2. Configured **Route Tables** for internet and NAT access.
3. Attached an **Internet Gateway** and created a **NAT Gateway** with an Elastic IP.

### Step 2: Backend Web Servers
Two backend EC2 instances were launched using **Amazon Linux 2023** and configured with the following user data:

```bash
#!/bin/bash
yum update -y
yum install httpd -y
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello from Backend Server 1</h1>" > /var/www/html/index.html
```
The same script was used for Server 2 with a different message in the index.html file.

### Step 3: NGINX Load Balancer Instance
A third EC2 instance was launched in the public subnet with NGINX installed and configured as a load balancer:

```bash
Copy code
#!/bin/bash
sleep 30
yum update -y
yum install nginx -y
systemctl start nginx
systemctl enable nginx
```
NGINX configuration file (/etc/nginx/nginx.conf) was updated with the following:

```nginx
Copy code
http {
    upstream backend {
        server 10.0.2.10;  # Private IP of Backend Server 1
        server 10.0.2.11;  # Private IP of Backend Server 2
    }

    server {
        listen 80;

        location / {
            proxy_pass http://backend;
        }
    }
}
```

### Testing the Load Balancer
Once all instances were running:

- Access the Load Balancer's Public IP in a browser.
- Refresh multiple times to see responses alternate between backend servers.
- This confirms that NGINX is successfully distributing traffic across both instances.

### Load Balancing Algorithms
NGINX supports multiple load distribution algorithms:

Algorithm	Description
1. **Round Robin**	(Default method): Sends requests to servers sequentially.
2. **Least Connections**: Sends traffic to the server with the fewest active connections.
3. **IP Hash**:	Ensures requests from a client IP always go to the same backend (session persistence).
4. **Weighted Round Robin**: Distributes load based on predefined server weights.
5. **Backup Servers**:	Routes traffic to backups only if primary servers fail.

### Challenges Faced
- Configuration changes in nginx.conf require service reload using:

```bash
sudo systemctl reload nginx
```
- Always test configuration syntax before reloading:

```bash
sudo nginx -t
```
- In Amazon Linux, NGINX stores the main configuration directly in /etc/nginx/nginx.conf instead of /etc/nginx/sites-available/default.
When using dnf in user data, ensure a delay (sleep 30) to allow the network to initialize.

### Author
**Zaeem Attique Ashar**
LinkedIn • GitHub
