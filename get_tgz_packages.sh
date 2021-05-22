#!/usr/bin/env ash

TGZLIST="list_tgz_packages.txt"
TARFILE="npm_packages.tar"
TEMPDIR="npm_packages"
NODEDIR="node_modules"

rm -f $TGZLIST 2>/dev/null && rm -rf $TEMPDIR 2>/dev/null && mkdir $TEMPDIR
find $NODEDIR -name package.json -exec grep _id {} \; | awk '{ print $2 }' | sed s'/[",]//'g | sort -u > $TGZLIST

for tgz_file in $(grep -v "^#|^$" $TGZLIST | sort -u)
do
	tmpf=$(echo $tgz_file | sed s'/^@//' | sed s'#[@/]#-#'g).tgz
	chkf=$TEMPDIR/$tmpf
	if [ ! -f $chkf ]
	then
		npm pack $tgz_file --verbose
		if [ $? != 0 ]
		then
			echo "ERROR: npm pack $tgz_file"
			exit 1
		fi

		mv $tmpf $chkf
		if [ $? != 0 ]
		then
			echo "ERROR: mv $tmpf $chkf"
			exit 1
		fi
	fi
done

tar -cvf $TARFILE $TEMPDIR
if [ $? != 0 ]
then
	echo "ERROR: tar -cvf $TARFILE $TMPDIR"
	exit 1
fi

ls -l $TARFILE
