#!/bin/bash

export WD="$(cd "$(dirname "$0")" && pwd)"
if [[ -f ~/.finished ]]; then
  echo "Installation is complete. Nothing to do"
  exit
fi
if [[ ! -f ~/.step1 ]]; then
  echo "Starting step 1..."
  $WD/src/step1.sh
fi
if [[ ! -f ~/.finished ]]; then
  echo "Step 1 complete."
  read -p "Proceed to step 2? Make sure you have a internet proxy. (Y/N)" -n 1 proceed && echo
  if [ $proceed = y -o $proceed = Y ]; then
    echo "Starting step 2..."
    $WD/src/step2.sh
  fi
fi
