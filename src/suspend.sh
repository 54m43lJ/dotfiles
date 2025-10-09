#!/bin/bash

lid_enabled() {
  sudo bash -c 'cat /proc/acpi/wakeup | grep -Eq LID0.+\*enabled'
}

if lid_enabled; then
  sudo bash -c 'echo LID0 >/proc/acpi/wakeup'
fi
systemctl suspend
