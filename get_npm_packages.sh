#!/usr/bin/env ash

NPMLIST="list_npm_packages.txt"
NODEDIR="node_modules"
X=1

# clear up working directory of any previous runs
rm -f package* 2>/dev/null && rm -rf ${NODEDIR}* 2>/dev/null
#npm cache clean --force

# cycle through a file containing a list of packages
for mod_name in $(egrep -v "^#|^$" $NPMLIST | sort -u)
do
	# clean up and initialise base dir and key files
	rm -f package* 2>/dev/null && rm -rf $NODEDIR 2>/dev/null
	npm init -y

	# create a directory for this package
	COPYDIR=${NODEDIR}.${X}
	rm -rf $COPYDIR 2>/dev/null

	mkdir $COPYDIR
	if [ $? != 0 ]
	then
		echo "ERROR: mkdir $COPYDIR"
		exit 1
	fi

	LOGFILE=${COPYDIR}/log

	# install package and all deps
	npm install $mod_name --save --verbose 2>&1 | tee $LOGFILE.install
	if [ $? != 0 ]
	then
		echo "ERROR: npm install $mod_name"
		exit 1
	fi

	# list and audit commands
	npm list 2>&1 | tee $LOGFILE.list
	npm audit 2>&1 | tee $LOGFILE.audit

	# move the base dir and key files into package dir
	mv $NODEDIR $COPYDIR/
	if [ $? != 0 ]
	then
		echo "ERROR: mv $NODEDIR $COPYDIR/"
		exit 1
	fi

	# use jq to extract dependency names and versions
	cat package-lock.json | jq -r '.dependencies | to_entries[] | "\(.key)@\(.value | .version)"' > $LOGFILE.deps
	cat package-lock.json | jq -r '.dependencies | to_entries[] | .value | .dependencies | select( . != null ) | to_entries[] | "\(.key)@\(.value | .version)"' >> $LOGFILE.deps

	mv package-lock.json $COPYDIR/
	if [ $? != 0 ]
	then
		echo "ERROR: mv package-lock.json $COPYDIR/"
		exit 1
	fi

	mv package.json $COPYDIR
	if [ $? != 0 ]
	then
		echo "ERROR: mv package.json $COPYDIR/"
		exit 1
	fi

	# cycle through package.json files for all deps to get list of package and version
	for pj in $(find ${COPYDIR}/node_modules -name package.json)
	do
		awk '{ if (/name/){ printf "%s@", $NF }; if (/version/){ print $NF ; exit } }' $pj | sed s'/[,"]//'g

	done | tee $LOGFILE.pj

	# increment X
	let X++

	if [ $X -gt 5 ]
	then
		exit
	fi
done

