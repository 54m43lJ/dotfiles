#!/bin/bash

sudo bash -c 'echo LID0 >/proc/acpi/wakeup'
systemctl suspend
