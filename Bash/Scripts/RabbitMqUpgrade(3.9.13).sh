#### check status of rabbitmq on machine:
rpm -qa | grep -E "rabbit|erlang"

sudo rabbitmqctl status

# Process to upgrade RabbitMQ:
# 1. Stop RabbitMQ
sudo systemctl stop rabbitmq-server

# 2. Backup the existing RabbitMQ data
sudo cp -r /var/lib/rabbitmq /var/lib/rabbitmq_backup

# 3. Remove the existing RabbitMQ and erlang packages
sudo yum remove rabbitmq-server erlang erlang-erts-R16B-03.18.el7.x86_64

# 4. Download the Erlang Package
wget https://github.com/rabbitmq/erlang-rpm/releases/download/v23.3.4.18/erlang-23.3.4.18-1.el7.x86_64.rpm

# 5. Install the Erlang Package
sudo yum install erlang-23.3.4.18-1.el7.x86_64.rpm

# 6. Download the RabbitMQ Package
wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.9.13/rabbitmq-server-3.9.13-1.el7.noarch.rpm

# 7. Install the RabbitMQ Package
sudo yum install rabbitmq-server-3.9.13-1.el7.noarch.rpm

# 8. Enable RabbitMQ Plugins
sudo rabbitmq-plugins enable rabbitmq_management

# Check the new versions of RabbitMQ & Erlang
rpm -qa | grep -E "rabbit|erlang"

# 9. Configure RabbitMQ users
sudo rabbitmqctl add_user vantage
sudo rabbitmqctl set_user_tags vantage administrator

# 10. Configure RabbitMQ Virtual Hosts
sudo rabbitmqctl add_vhost /satellite
sudo rabbitmqctl add_vhost /inbound

# 11. Configure RabbitMQ Permissions
sudo rabbitmqctl set_permissions -p /satellite vantage ".*" ".*" ".*"
sudo rabbitmqctl set_permissions -p /inbound vantage ".*" ".*" ".*"

# 12. Verify Permissions
sudo rabbitmqctl list_user_permissions vantage

# 13. Start RabbitMQ
sudo systemctl start rabbitmq-server

# 14. Check the status of RabbitMQ
sudo systemctl status rabbitmq-server
sudo rabbitmqctl status

# 15. Check that RabbitMQ is listing queues
sudo rabbitmqctl list_queues
