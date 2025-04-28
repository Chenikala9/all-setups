#create amazonlinux ec2 with t2.medium and 30 gb of ebs with port 8081 
#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Update system and install dependencies
sudo yum update -y
sudo yum install wget -y
sudo yum install java-17-amazon-corretto-jmods -y

# Create /app directory and navigate
sudo mkdir -p /app
cd /app

# Download and extract Nexus
sudo wget https://download.sonatype.com/nexus/3/nexus-unix-x86-64-3.78.2-04.tar.gz
sudo tar -xvf nexus-unix-x86-64-3.78.2-04.tar.gz
sudo rm -rf /app/nexus
sudo mv nexus-3.78.2-04 /app/nexus

# Create nexus user and set ownership
if id "nexus" &>/dev/null; then
    echo "User nexus already exists."
else
    sudo adduser nexus
fi
sudo chown -R nexus:nexus /app/nexus
sudo chown -R nexus:nexus /app/sonatype-work

# Configure nexus to run as nexus user
echo 'run_as_user="nexus"' | sudo tee /app/nexus/bin/nexus.rc

# Create systemd service file
sudo tee /etc/systemd/system/nexus.service > /dev/null << 'EOL'
[Unit]
Description=Nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=/app/nexus/bin/nexus start
ExecStop=/app/nexus/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd and enable/start Nexus
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus

# Check Nexus service status
sudo systemctl status nexus


