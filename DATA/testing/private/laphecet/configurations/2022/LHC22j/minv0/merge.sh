#!/bin/bash

echo "ARGS=$@"

if [[ -z $1 ]]; then
  echo "ERROR: Command line arguments missing. Syntax: merge.sh [collection of files to merge] [name(s) of other files to merge at the same location]"
  exit 1
fi
if [ ! -f $1 ]; then
  echo "ERROR: input file $1 not found locally"
  exit 1
fi

# extract the list of input dirname/filename from the collection
if [[ "${1##*.}" == "xml" ]]; then
  FILELIST=${1/%xml/txt}
  sed -rn 's/.*turl="([^"]*)".*/\1/p' $1 > $FILELIST
elif [[ "$(file "$1")" =~ ': ASCII text' ]]; then
  FILELIST=$1
else
  echo "invalid input (must be an xml collection of a text file)"
  exit 2
fi

# get the name of the first file to merge
FILE0="`head -n1 $FILELIST | xargs -L 1 basename`"
if [[ $(grep -v -c -e "/$FILE0$" $FILELIST) != 0 ]]; then
  echo "invalid input (must be a list of dirname/filename with the same filename)"
  exit 2
fi

# append the other files to merge
FILES="$FILE0"
shift
echo "FILES=$FILES"
for file in $@; do
  if [[ "${file}" == ";" ]]; then
    break
  fi
  [[ ! "$FILES" =~ (^|[[:space:]])"$file"($|[[:space:]]) ]] && FILES+=" $file"
done

echo "FILES=$FILES"
# do the merging for files in the list
for file in $FILES; do
  sed -rn "s/$FILE0/$file/gp" $FILELIST > "__$FILELIST"
  echo "file=$file"
  if [[ "$file" == "QC.root" ]]; then
    o2-qc-file-merger --input-files-list __$FILELIST --enable-alien --output-file $file
  else
    root -l -b -q 'merge.C+("__'$FILELIST'","'$file'")'
  fi
  [[ $? -ne 0 ]] && exit 3
done
rm -f "__$FILELIST"
