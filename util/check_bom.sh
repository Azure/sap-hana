#!/bin/bash

# Usage
#   /path/to/util/check_bom.sh /other/path/to/bom.yml

declare ERR=0
command -v yamllint || sudo apt install -y yamllint
[[ $? -ne 0 ]] && ERR=1
command -v ansible-lint || sudo apt install -y ansible-lint
[[ $? -ne 0 ]] && ERR=1

yamllint $1
ansible-lint $1

ansible-playbook check_bom.yml
