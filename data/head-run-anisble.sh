#!/bin/bash
(cat << EOT
[compute-master]
cloud-head
[compute-client]
EOT
cat /root/host-list-* ) > /etc/ansible/hosts
cd /etc/ansible
git pull
ansible-playbook /etc/ansible/runme.yml 
