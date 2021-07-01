#!/bin/bash

set -euo pipefail

sudo certbot -n --apache --domains nextcloud.frodux.in --agree-tos --email chris@moultrie.org
