#!/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $DIR/ansible

pipenv install

pipenv shell

ansible-playbook ssh-key-management.yml

python ec2.py --list
