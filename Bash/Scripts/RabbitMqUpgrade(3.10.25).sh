#!/bin/bash

# Variables
# Edit the following variables with the appropriate values to configure the RabbitMQ upgrade

rabbitmq_definitions_export_file="/tmp/rabbitmq_definitions_export.json"
current_erlang_version=$(rpm -qa | grep erlang | head -n 1)
current_rabbitmq_version=$(rpm -qa | grep rabbitmq | head -n 1)
desired_erlang_version="v25.3.2.15" # Edit with the desired Erlang version (e.g. "v25.3.2.15")
new_erlang_version_install_file="erlang-25.3.2.15-1.el7.x86_64.rpm"
desired_rabbitmq_version="v3.10.25" # Edit with the desired RabbitMQ version (e.g. "v3.10.25")
new_rabbitmq_version_install_file="rabbitmq-server-3.10.25-1.el8.noarch.rpm"

# Check status of RabbitMQ and Erlang on the machine
echo "Checking current RabbitMQ and Erlang versions..."
rpm -qa | grep -E "rabbit|erlang"
sudo rabbitmqctl status

# # Process to upgrade RabbitMQ:
# # 1. Stop RabbitMQ
# echo "Stopping RabbitMQ..."
# sudo systemctl stop rabbitmq-server
# if [ $? -ne 0 ]; then
#     echo "Failed to stop RabbitMQ. Exiting."
#     exit 1
# fi

# 2. Backup the existing RabbitMQ data
echo "Backing up RabbitMQ data..."
sudo cp -r /var/lib/rabbitmq /var/lib/rabbitmq_backup
# Export RabbitMQ definitions
echo "Exporting RabbitMQ definitions..."
sudo curl -u vantage:vantage -X GET http://127.0.0.1:15672/api/definitions > $rabbitmq_definitions_export_file
if [ $? -ne 0 ]; then
    echo "Failed to backup RabbitMQ data. Exiting."
    exit 1
fi

# 3. Remove the existing RabbitMQ and Erlang packages
echo "Removing existing RabbitMQ and Erlang packages..."
sudo yum remove -y "$current_rabbitmq_version" "$current_erlang_version"
if [ $? -ne 0 ]; then
    echo "Failed to remove RabbitMQ and Erlang packages. Exiting."
    exit 1
fi

# 4. Download the Erlang Package
echo "Downloading Erlang package..."
wget https://github.com/rabbitmq/erlang-rpm/releases/download/$desired_erlang_version/$new_erlang_version_install_file
if [ $? -ne 0 ]; then
    echo "Failed to download Erlang package. Exiting."
    exit 1
fi

# 5. Install the Erlang Package
echo "Installing Erlang package..."
sudo yum install -y $new_erlang_version_install_file
if [ $? -ne 0 ]; then
    echo "Failed to install Erlang package. Exiting."
    exit 1
fi

# 6. Download the RabbitMQ Package
echo "Downloading RabbitMQ package..."
wget https://github.com/rabbitmq/rabbitmq-server/releases/download/$desired_rabbitmq_version/$new_rabbitmq_version_install_file
if [ $? -ne 0 ]; then
    echo "Failed to download RabbitMQ package. Exiting."
    exit 1
fi

# 7. Install the RabbitMQ Package
echo "Installing RabbitMQ package..."
sudo yum install -y $new_rabbitmq_version_install_file
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

# 9. Check the new versions of RabbitMQ & Erlang
echo "Checking new versions of RabbitMQ and Erlang..."
rpm -qa | grep -E "rabbit|erlang"

# 10. Start RabbitMQ
echo "Starting RabbitMQ..."
sudo systemctl start rabbitmq-server

# Import RabbitMQ definitions
echo "Importing RabbitMQ definitions..."
sudo rabbitmqctl import_definitions $rabbitmq_definitions_export_file
if [ $? -ne 0 ]; then
    echo "Failed to import RabbitMQ definitions. Exiting."
    exit 1
fi

# # Process to configure RabbitMQ:
# # 11. Configure RabbitMQ users
# echo "Configuring RabbitMQ users..."
# sudo rabbitmqctl add_user vantage "vantage"
# sudo rabbitmqctl set_user_tags vantage administrator
# if [ $? -ne 0 ]; then
#     echo "Failed to configure RabbitMQ users. Exiting."
#     exit 1
# fi

# # 12. Configure RabbitMQ Virtual Hosts
# echo "Configuring RabbitMQ virtual hosts..."
# sudo rabbitmqctl add_vhost /satellite
# sudo rabbitmqctl add_vhost /inbound
# if [ $? -ne 0 ]; then
#     echo "Failed to configure RabbitMQ virtual hosts. Exiting."
#     exit 1
# fi

# # 13. Configure RabbitMQ Permissions
# echo "Configuring RabbitMQ permissions..."
# sudo rabbitmqctl set_permissions -p /satellite vantage ".*" ".*" ".*"
# sudo rabbitmqctl set_permissions -p /inbound vantage ".*" ".*" ".*"
# if [ $? -ne 0 ]; then
#     echo "Failed to configure RabbitMQ permissions. Exiting."
#     exit 1
# fi

# 14. Restart RabbitMQ
echo "Restarting RabbitMQ..."
sudo systemctl restart rabbitmq-server
if [ $? -ne 0 ]; then
    echo "Failed to restart RabbitMQ. Exiting."
    exit 1
fi

# 15. Check the status of RabbitMQ
echo "Checking RabbitMQ status..."
sudo systemctl status rabbitmq-server
sudo rabbitmqctl status
if [ $? -ne 0 ]; then
    echo "Failed to check RabbitMQ status. Exiting."
    exit 1
fi

# 16. Check that RabbitMQ is listing queues
echo "Checking RabbitMQ queues..."
sudo rabbitmqctl list_queues
if [ $? -ne 0 ]; then
    echo "Failed to list RabbitMQ queues. Exiting."
    exit 1
fi

# 17. Verify RabbitMQ users
echo "Verifying RabbitMQ users..."
sudo rabbitmqctl list_users
if [ $? -ne 0 ]; then
    echo "Failed to verify RabbitMQ users. Exiting."
    exit 1
fi

# 18. Verify Permissions
echo "Verifying RabbitMQ permissions..."
sudo rabbitmqctl list_user_permissions vantage
if [ $? -ne 0 ]; then
    echo "Failed to verify RabbitMQ permissions. Exiting."
    exit 1
fi

# 19. Verify Virtual Hosts
echo "Verifying RabbitMQ virtual hosts..."
sudo rabbitmqctl list_vhosts
if [ $? -ne 0 ]; then
    echo "Failed to verify RabbitMQ virtual hosts. Exiting."
    exit 1
fi

# 20. Verify Enabled Plugins
echo "Verifying enabled RabbitMQ plugins..."
sudo rabbitmq-plugins list
if [ $? -ne 0 ]; then
    echo "Failed to verify enabled RabbitMQ plugins. Exiting."
    exit 1
fi

# 21. Report success and cleanup installation files
echo "RabbitMQ upgrade completed successfully. Cleaning up installation files..."
rm $new_erlang_version_install_file $new_rabbitmq_version_install_file $rabbitmq_definitions_export_file
if [ $? -ne 0 ]; then
    echo "Failed to cleanup installation files. Exiting."
    exit 1
fi