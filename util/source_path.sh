#!/usr/bin/env bash

# This file is used to add this directory to your $PATH for easier usage
if [[ "$0" == "$BASH_SOURCE" ]] ; then
  echo "This script must be sourced to add the util commands to the PATH environment."
else
  SCRIPTSPATH="$( cd "$(dirname "$BASH_SOURCE")" ; pwd -P )"
  echo "Extending \$PATH with: $SCRIPTSPATH"
  export PATH=$PATH:$SCRIPTSPATH
fi
