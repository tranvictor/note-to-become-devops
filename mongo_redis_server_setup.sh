# VARIABLES, change following variables if needed
DATA_DEVICE='xvdb'
LOG_DEVICE='xvdc'

echo ">> Prepare"
ls /etc/apt/sources.list.d/ | grep mongodb
if [ $? -ne 0 ]; then
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
  echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
fi

echo ">> Updating System"
sudo apt-get update
# handle current bug in grub menu
sudo rm /boot/grub/menu.lst
sudo update-grub-legacy-ec2 -y
sudo apt-get dist-upgrade -qq --force-yes
# end handling
sudo apt-get -y upgrade
echo "Installing packages"
sudo apt-get -y install build-essential tcl8.5 git-core nginx redis-server curl htop

echo "Disable Transparent Huge Pages (THP)"
# see https://docs.mongodb.org/manual/tutorial/transparent-huge-pages/
echo '
#!/bin/sh
### BEGIN INIT INFO
# Provides:          disable-transparent-hugepages
# Required-Start:    $local_fs
# Required-Stop:
# X-Start-Before:    mongod mongodb-mms-automation-agent
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Disable Linux transparent huge pages
# Description:       Disable Linux transparent huge pages, to improve
#                    database performance.
### END INIT INFO

case $1 in
  start)
    if [ -d /sys/kernel/mm/transparent_hugepage ]; then
      thp_path=/sys/kernel/mm/transparent_hugepage
    elif [ -d /sys/kernel/mm/redhat_transparent_hugepage ]; then
      thp_path=/sys/kernel/mm/redhat_transparent_hugepage
    else
      return 0
    fi

    echo 'never' > ${thp_path}/enabled
    echo 'never' > ${thp_path}/defrag

    unset thp_path
    ;;
esac
' | sudo tee /etc/init.d/disable-transparent-hugepages
sudo chmod 755 /etc/init.d/disable-transparent-hugepages
sudo update-rc.d disable-transparent-hugepages defaults

echo ">> Installing MongoDB and Redis"
sudo apt-get install -y mongodb-org

echo ">>> Set data, log and journal path to different I/O devices"
sudo mkdir /data /log

# format ext4 for data
sudo mkfs.ext4 /dev/$DATA_DEVICE
# for log
sudo mkfs.ext4 /dev/$LOG_DEVICE

echo "/dev/$DATA_DEVICE /data ext4 defaults,auto,noatime,noexec 0 0
/dev/$LOG_DEVICE /log ext4 defaults,auto,noatime,noexec 0 0" | sudo tee -a /etc/fstab

sudo mount /data
sudo mount /log

sudo mkdir /data/mongodb /data/redis
sudo mkdir /log/mongodb /log/redis

sudo chown mongodb:mongodb /data/mongodb /log/mongodb
sudo chown redis:redis /data/redis /log/redis
sudo ln -s /data/mongodb/journal

echo ">>> Update mongodb configuration"
echo '
storage:
  dbPath: /data/mongodb
  journal:
    enabled: true
#  engine:
#  mmapv1:
#  wiredTiger:

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /log/mongodb/mongodb.log

# network interfaces
net:
  port: 27017
  bindIp: 0.0.0.0
' | sudo tee /etc/mongod.conf

echo ">>> Increase ulimit"
echo '
* soft nofile 64000
* hard nofile 64000
* soft nproc 32000
* hard nproc 32000
' | sudo tee -a /etc/security/limits.conf
echo '
* soft nproc 32000
* hard nproc 32000
' | sudo tee -a /etc/security/limits.d/90-nproc.conf
echo ">>> Changing read-ahead to 32 blocks for data device"
sudo blockdev --setra 32 /dev/$DATA_DEVICE
echo "ACTION==\"add\", KERNEL==\"$DATA_DEVICE\", ATTR{bdi/read_ahead_kb}=\"16\"" | sudo tee -a /etc/udev/rules.d/85-ebs.rules

echo '>> Move Redis path to mounted devices'
echo '>>> Move redis.conf to redis.conf.default'
sudo mv /etc/redis/redis.conf /etc/redis/redis.conf.default
echo '
daemonize yes
pidfile /var/run/redis/redis-server.pid
port 6379
bind 0.0.0.0
timeout 0
tcp-keepalive 0
loglevel notice
logfile /log/redis/redis.log
databases 16
save 3600 1
save 1800 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /log/redis
slave-serve-stale-data yes
slave-read-only yes
repl-disable-tcp-nodelay no
slave-priority 100
appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
lua-time-limit 5000
slowlog-log-slower-than 1000
slowlog-max-len 128
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-entries 512
list-max-ziplist-value 64
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes
' | sudo tee /etc/redis/redis.conf
sudo service redis-server restart

echo '>> Done. You should reboot the system for limits.conf to be applied'
