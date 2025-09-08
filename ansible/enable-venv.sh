#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $DIR

pipenv install

# TODO - verify
#pipenv shellansible-playbook ssh-key-management.yml

python ec2.py --list
