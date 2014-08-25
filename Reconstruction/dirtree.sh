#!/bin/bash
# DIRTREE - print a nice graphical directory tree structure

if [ $# -gt 1 ]; then
    echo "usage: `basename $0` <topfolder>"
    exit 1
fi

ls -R $1 | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/' 

exit 0
