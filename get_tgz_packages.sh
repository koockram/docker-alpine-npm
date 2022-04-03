#!/usr/bin/env ash

NODEDIR="node_modules"
PKGLIST="log.pkgs"

for i in ${NODEDIR}.[0-9]*
do
	INT=$(echo $i | awk -F "." '{ print $2 }')
	TARFILE="npm_packages.${INT}.tar"
	TEMPDIR="npm_packages.${INT}"
	rm -rf $TEMPDIR 2>/dev/null && mkdir $TEMPDIR

	PKGLIST=$i/$PKGLIST

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
		echo "ERROR: tar -cvf $TARFILE $TMPDIR"
		exit 1
	fi

	ls -l $TARFILE
	exit
done
