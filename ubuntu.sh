#! /bin/bash
sudo apt-get update -y
sudo apt-get install apache2 -y
sudo systemctl start apache2
sudo systemctl enable apache2
echo "<h1>Azure Virtual Machine deployed with Terraform</h1> <p>Private IP address: ${ip}</p>" | sudo tee /var/www/html/index.html