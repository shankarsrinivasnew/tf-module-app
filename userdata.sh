#!/bin/bash

ansible-pull -i localhost, -U https://github.com/shankarsrinivasnew/roboshop-infra.git roboshop.yml -e role_name=${component} -e env=${env} >/opt/ansible.log
