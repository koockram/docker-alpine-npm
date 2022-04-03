#!/usr/bin/env ash

# Before running this script, make sure the script "get_npm_packages.sh" has already run

# This script scans directories "node_modules.[int]", where int starts at 1 and increments for each package in file "list_npm_packages.txt"
# node_modules.1 = @testing-library/react
# node_modules.2 = @testing-library/user-event@12.4.5
# node_modules.3 = typescript@1.0.2

# In each node_modules.[int] directory, there is a bunch of log files which are copied to "npm_packages/logs"
# The log files "log.pkgs", which contains a list of packages for each directory, are aggregated and sorted uniquely into "npm_packages.txt"
# Each package in "npm_packages.txt" is packed as a tgz file in directory "npm_packages"
# Finally "npm_packages" directory is created as a tar file "npm_packages.tar"

# The script will error and exit if return code of any major operation is non-zero

NODEDIR="node_modules"
TEMPDIR="npm_packages"
PKGLIST="npm_packages2.txt"
TARFILE="npm_packages.tar"
SHAFILE="npm_packages.sha"

rm -rf $TEMPDIR 2>/dev/null && mkdir -p $TEMPDIR/logs

for i in ${NODEDIR}.[0-9]*
do
	INT=$(echo $i | awk -F "." '{ print $NF }')

	for j in log.audit log.deps log.install log.list log.pkgs log.rslvd package-lock.json package.json
	do
		echo cp $i/$j $TEMPDIR/logs/$j.$INT
		cp $i/$j $TEMPDIR/logs/$j.$INT

		if [ $? != 0 ]
		then
			echo "ERROR: missing log file $i/$j"
			exit 1
		fi
	done
done

cat ${NODEDIR}.[0-9]*/log.pkgs | sort -u > $PKGLIST

for pkg in $(grep -v "^#|^$" $PKGLIST | sort -u)
do
	tgz_file=$(echo $pkg | sed s'/^@//' | sed s'#[@/]#-#'g).tgz
	chk_file=$TEMPDIR/$tgz_file
	if [ ! -f $chk_file ]
	then
		npm pack $pkg --pack-destination $TEMPDIR --verbose
		if [ $? != 0 ]
		then
			echo "ERROR: npm pack $pkg"
			exit 1
		fi
	fi
done

tar -cvf $TARFILE $TEMPDIR
if [ $? != 0 ]
then
	echo "ERROR: tar -cvf $TARFILE $TEMPDIR"
	exit 1
fi

sha256sum $TARFILE > $SHAFILE
ls -l $TARFILE $SHAFILE

