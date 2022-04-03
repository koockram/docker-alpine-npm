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

	### some analysis (3 x ways), preference is number 2 so far based on analysis of results

	# 1. use jq to extract top level dependency names and versions from "dependencies" part of the package-lock.json file
	cat package-lock.json | \
		jq -r '.dependencies | to_entries[] | "\(.key)@\(.value | .version)"' > $LOGFILE.deps

	# use jq to extract nested dependency names and versions from "dependencies" part of the package-lock.json file
	cat package-lock.json | \
		jq -r '.dependencies | to_entries[] | .value | .dependencies | select( . != null ) | to_entries[] | "\(.key)@\(.value | .version)"' >> $LOGFILE.deps

	# sort results uniquely
	sort -u -o $LOGFILE.deps $LOGFILE.deps

	# 2. use jq to extract package names and versions from "packages" part of the package-lock.json file
	cat package-lock.json | \
		jq -r '.packages | to_entries[] | select( .key != "" ) | "\(.key)@\(.value | .version)"' | \

		# rip out everything up to and including the string "*node_modules/" even if nested
		sed s'#^.*node_modules/##' | \

		# and sort uniquely
		sort -u > $LOGFILE.pkgs


	# 3. find lines indicating a resolved tgz file in package-lock.json
	awk '/"resolved": "/{ print $2 }' package-lock.json  | \

		# remove anything either side of the quotation marks, e.g. [some "/x/y/z/pkg-version.tgz" thing] = [/x/y/z/pkg-version.tgz]
		sed s'/^"\(.*\)".*$/\1/' | \

		# replace version delimiter "-" as "/" and remove ".tgz" file extension = [/x/y/z/pkg/version]
		# agh! version string not semantically reliable, e.g. "1.0-alpha.56", which requires too broad a pattern match
		sed s'/-\([0-9].*\).tgz/\/\1/' | \

		# split on "/" delimiter and join candidate fields = [registry.npmjs.org/pkg@version] OR = [@scope/pkg@version]
		awk -F "/" '{ print $(NF-4) "/" $(NF-1) "@" $NF }' | \

		# and get rid of "registry.npmjs.org/" = [pkg@version] OR = [@scope/pkg@version]
		sed s'/registry.npmjs.org\///' | \

		# and sort uniquely
		sort -u > $LOGFILE.rslvd

	### end analysis

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

	# increment X
	let X++
done

