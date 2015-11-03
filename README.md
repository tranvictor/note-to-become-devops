# note-to-become-devops
My personal notes for myself to look up later whenever I run into server-related tasks. It's mostly about AWS, Linux (Ubuntu) and other devops technologies.

## Mongodb and Redis server script
It contains script to update system, install MongoDB and Redis, common Ubuntu kernel tweaks for them.

Require: 2 additional attached storage devices for data and log. They are should be separated because of different I/O behaviours.
### Usage
```
ssh -i <path to your keypem> ubuntu@ip.ip.ip.ip 'bash -s' < mongo_redis_server_setup.sh
```
> Note: Assume that you already registered an Ubuntu EC2 server with public IP of `ip.ip.ip.ip`. If your server is not on AWS, change username to your server's username with sudo permission.

## Ubuntu script for Ruby (Rails) app
This script will update the system, install git, imagemagick, nginx, curl, nodejs, htop and common Ubuntu kernel tweaks.
### Usage
Set necessary environment variables in your local machine. Run
```
ruby generate_ubuntu_server_setup_script.rb
```
to generate `setup_server.sh` file.

Run this command to start setting up the server:
```
ssh -i <path to your keypem> ubuntu@ip.ip.ip.ip 'bash -s' < setup_server.sh
```

> Note: You can change your needed varibles in [this script template](https://github.com/tranvictor/note-to-become-devops/blob/master/ubuntu_server_setup.sh.template).

## [Explaination of some Linux limits configuration](https://github.com/tranvictor/note-to-become-devops/tree/master/linux_limits_configuration)
