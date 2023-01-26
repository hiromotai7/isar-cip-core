#!/bin/bash

# This script generates rb.yaml with latest epoch time based on
# latest commit id

cat <<EOT > rb.yml
header:
  version: 12

local_conf_header:
  reproducible-builds: |
    SOURCE_DATE_EPOCH = "$(git log -1 --pretty=%ct)"
EOT