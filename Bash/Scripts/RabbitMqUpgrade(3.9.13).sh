#!/bin/bash

# Check status of RabbitMQ and Erlang on the machine
echo "Checking current RabbitMQ and Erlang versions..."
rpm -qa | grep -E "rabbit|erlang"
sudo rabbitmqctl status

# Process to upgrade RabbitMQ:
# 1. Stop RabbitMQ
echo "Stopping RabbitMQ..."
sudo systemctl stop rabbitmq-server
if [ $? -ne 0 ]; then
  echo "Failed to stop RabbitMQ. Exiting."
  exit 1
fi

# 2. Backup the existing RabbitMQ data
echo "Backing up RabbitMQ data..."
sudo cp -r /var/lib/rabbitmq /var/lib/rabbitmq_backup
if [ $? -ne 0 ]; then
  echo "Failed to backup RabbitMQ data. Exiting."
  exit 1
fi

# 3. Remove the existing RabbitMQ and Erlang packages
echo "Removing existing RabbitMQ and Erlang packages..."
sudo yum remove -y rabbitmq-server erlang erlang-erts-R16B-03.18.el7.x86_64
if [ $? -ne 0 ]; then
  echo "Failed to remove RabbitMQ and Erlang packages. Exiting."
  exit 1
fi

# 4. Download the Erlang Package
echo "Downloading Erlang package..."
wget https://github.com/rabbitmq/erlang-rpm/releases/download/v23.3.4.18/erlang-23.3.4.18-1.el7.x86_64.rpm
if [ $? -ne 0 ]; then
  echo "Failed to download Erlang package. Exiting."
  exit 1
fi

# 5. Install the Erlang Package
echo "Installing Erlang package..."
sudo yum install -y erlang-23.3.4.18-1.el7.x86_64.rpm
if [ $? -ne 0 ]; then
  echo "Failed to install Erlang package. Exiting."
  exit 1
fi

# 6. Download the RabbitMQ Package
echo "Downloading RabbitMQ package..."
wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.9.13/rabbitmq-server-3.9.13-1.el7.noarch.rpm
if [ $? -ne 0 ]; then
  echo "Failed to download RabbitMQ package. Exiting."
  exit 1
fi

# 7. Install the RabbitMQ Package
echo "Installing RabbitMQ package..."
sudo yum install -y rabbitmq-server-3.9.13-1.el7.noarch.rpm
if [ $? -ne 0 ]; then
  echo "Failed to install RabbitMQ package. Exiting."
  exit 1
fi

# 8. Enable RabbitMQ Plugins
echo "Enabling RabbitMQ plugins..."
sudo rabbitmq-plugins enable rabbitmq_management
if [ $? -ne 0 ]; then
  echo "Failed to enable RabbitMQ plugins. Exiting."
  exit 1
fi

# Check the new versions of RabbitMQ & Erlang
echo "Checking new versions of RabbitMQ and Erlang..."
rpm -qa | grep -E "rabbit|erlang"

# 9. Configure RabbitMQ users
echo "Configuring RabbitMQ users..."
sudo rabbitmqctl add_user vantage
sudo rabbitmqctl set_user_tags vantage administrator
if [ $? -ne 0 ]; then
  echo "Failed to configure RabbitMQ users. Exiting."
  exit 1
fi

# 10. Configure RabbitMQ Virtual Hosts
echo "Configuring RabbitMQ virtual hosts..."
sudo rabbitmqctl add_vhost /satellite
sudo rabbitmqctl add_vhost /inbound
if [ $? -ne 0 ]; then
  echo "Failed to configure RabbitMQ virtual hosts. Exiting."
  exit 1
fi

# 11. Configure RabbitMQ Permissions
echo "Configuring RabbitMQ permissions..."
sudo rabbitmqctl set_permissions -p /satellite vantage ".*" ".*" ".*"
sudo rabbitmqctl set_permissions -p /inbound vantage ".*" ".*" ".*"
if [ $? -ne 0 ]; then
  echo "Failed to configure RabbitMQ permissions. Exiting."
  exit 1
fi

# 12. Verify Permissions
echo "Verifying RabbitMQ permissions..."
sudo rabbitmqctl list_user_permissions vantage
if [ $? -ne 0 ]; then
  echo "Failed to verify RabbitMQ permissions. Exiting."
  exit 1
fi

# 13. Start RabbitMQ
echo "Starting RabbitMQ..."
sudo systemctl start rabbitmq-server
if [ $? -ne 0 ]; then
  echo "Failed to start RabbitMQ. Exiting."
  exit 1
fi

# 14. Check the status of RabbitMQ
echo "Checking RabbitMQ status..."
sudo systemctl status rabbitmq-server
sudo rabbitmqctl status
if [ $? -ne 0 ]; then
  echo "Failed to check RabbitMQ status. Exiting."
  exit 1
fi

# 15. Check that RabbitMQ is listing queues
echo "Checking RabbitMQ queues..."
sudo rabbitmqctl list_queues
if [ $? -ne 0 ]; then
  echo "Failed to list RabbitMQ queues. Exiting."
  exit 1
fi

echo "RabbitMQ upgrade completed successfully."