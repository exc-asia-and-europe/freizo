#!/bin/sh

WORKING_DIR=/home/claudius/pdf
SOURCE_DIR=$WORKING_DIR/source
TARGET_DIR=$WORKING_DIR/target

if [ ! -z "$1" ]
then
SOURCE_DIR=$SOURCE_DIR/$1
TARGET_DIR=$TARGET_DIR/$1
fi

rm -rf $TARGET_DIR/*
echo "Removed the target files."
cp -R $SOURCE_DIR/. $TARGET_DIR/
echo "Copied the source files."

for path in $(find $TARGET_DIR $1 -name "*.tif")
do
  echo -e "\033[92mConverting ${path}\033[0m"
  convert ${path} "${path%.tif}.png"
done

for path in $(find $TARGET_DIR $1 -name "*.html")
do
  echo -e "\033[92mProcessing ${path}\033[0m"
  wkhtmltopdf ${path} "${path%.html}.pdf"
done

find $TARGET_DIR -name "*.html" -type f -delete
echo "Deleted the .html files."

find $TARGET_DIR -name "__contents__.xml" -type f -delete
echo "Deleted the __contents__.xml files."

find $TARGET_DIR -name "_images" -type d -exec rm -Rf {} \;
echo "Deleted the _images directories."

find $TARGET_DIR -name "_galleries" -type d -exec rm -Rf {} \;
echo "Deleted the __galleries directories."
