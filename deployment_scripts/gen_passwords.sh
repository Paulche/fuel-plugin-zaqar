#!/bin/sh

gen_pass() {
     openssl rand -base64 32|tr -d '='
}

CLUSTER_ID=$1
user_pass=$(gen_pass)
db_pass=$(gen_pass)

echo "
---
  zaqar:
    user_password: $user_pass
    db_password: $db_pass
" > /etc/fuel/cluster/$CLUSTER_ID/fuel-plugin-zaqar.yaml
