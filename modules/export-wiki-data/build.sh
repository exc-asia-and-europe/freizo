#!/bin/sh

rm -rf target/*
cp -R source/. target/

for path in $(find target $1 -name "*.html")
do
  echo -e "\033[92mProcessing ${path}\033[0m"
  wkhtmltopdf ${path} "${path%.html}.pdf"
done

find target/. -name "*.html" -type f -delete
find target/. -name "_images" -type d -exec rm -Rf {} \;
find target/. -name "_galleries" -type d -exec rm -Rf {} \;

