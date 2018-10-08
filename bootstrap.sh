#!/bin/bash

echo "Bootstrap script..."
# Enter any additional commands or package installs here

# Author prefers network tools to be baked part of the image
yum -y install bind-utils mtr nc nmap traceroute

# And git
yum -y install git
