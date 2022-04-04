#!/usr/bin/env ash

NODEDIR="node_modules"

rm -f package* 2>/dev/null && rm -rf $NODEDIR 2>/dev/null
npm cache clean --force
npm init -y

npm list
