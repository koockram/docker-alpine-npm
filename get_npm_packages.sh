#!/usr/bin/env ash

NPMLIST="list_npm_packages.txt"
NODEDIR="node_modules"

rm -f package* 2>/dev/null && rm -rf $NODEDIR 2>/dev/null
npm cache clean --force
npm init -y

for mod_name in $(egrep -v "^#|^$" $NPMLIST | sort -u)
do
	npm install $mod_name --save --verbose
	if [ $? != 0 ]
	then
		echo "ERROR: npm install $mod_name"
		exit 1
	fi
done

npm list
