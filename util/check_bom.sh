#!/bin/bash

# Usage
#   cd /path/to/util
#   ./check_bom.sh /some/other/path/to/bom.yml

if [[ -z $1 ]]; then
  echo "Usage: $0 /path/to/bom.yml"
  exit 8
elif [[ ! -f $1 ]]; then
  echo "$1 not found"
  exit 9
fi

YAML_LINT=$(command -v yamllint) || echo "yamllint not found. To run linting, install yamllint and try again"
ANSIBLE_LINT=$(command -v ansible-lint) || echo "ansible-lint not found. To run linting, install ansible-lint and try again"
YAML_LINT_ERRORS=0
ANSIBLE_LINT_ERRORS=0

if [[ -n ${YAML_LINT} ]]; then
  if ${YAML_LINT} "$1"; then
    echo "... yamllint [ok]"
  else
    echo "... yamllint [errors]"
    YAML_LINT_ERRORS=1
  fi
fi

if [[ -n ${ANSIBLE_LINT} ]]; then
  if ${ANSIBLE_LINT} "$1"; then
    echo "... ansible-lint [ok]"
  else
    echo "... ansible-lint [errors]"
    ANSIBLE_LINT_ERRORS=2
  fi
fi

TMP_DIR=$(mktemp -d)
mkfifo "${TMP_DIR}"/capture
cat "${TMP_DIR}"/capture &

VALIDATION_ERRORS=$(ansible-playbook --extra-vars "bom_name=$1" check_bom.yml 2>/dev/null |
  sed -e 's/, *$//' -n -e '/^failed/,/^}/p' |
  sed -n -e '/"msg":/s/^.*"msg": "\(.*\)"$/  - \1/p' |
  tee "${TMP_DIR}"/capture | wc -l)

wait
rm -rf "${TMP_DIR}"

if [[ ${VALIDATION_ERRORS} -eq 0 ]]; then
  echo "... bom structure [ok]"
else
  echo "... bom structure [errors]"
  VALIDATION_ERRORS=4
fi

exit $(( YAML_LINT_ERRORS + ANSIBLE_LINT_ERRORS + VALIDATION_ERRORS ))
