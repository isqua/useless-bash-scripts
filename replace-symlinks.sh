#!/bin/bash

DIR=$1

for file in `find $DIR -type l`; do
  sourcefile=`readlink -e $file`
  echo 'Replace $(basename $file) with content of $(basename $sourcefile)'
  rm $file
  cat $sourcefile > $file
done
