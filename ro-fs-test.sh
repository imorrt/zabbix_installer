#!/bin/bash

awk '$4 ~ "^ro[,$]" && $3 !~ "(squashfs|iso9660|tmpfs)" {print $0}' /proc/mounts | wc -l
