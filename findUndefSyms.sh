#!/bin/sh
echo Generating available symbol list step 1
nm -Uj /System/Library/Frameworks/*/Versions/*/* "$1"/Contents/MacOS/* "$1"/Contents/MacOS/*.app/Contents/MacOS/* `find "$1"/Contents/Resources -name '*.dylib' -type f` /System/Library/Frameworks/*/Versions/*/Frameworks/*/Versions/*/* /usr/lib/*.dylib /usr/lib/*/*.dylib 2>/dev/null > /tmp/_fusym_tmp
echo Generating available symbol list step 2
nm -Uj /System/Library/PrivateFrameworks/*/Versions/*/* /System/Library/PrivateFrameworks/*/Versions/*/Libraries/* /System/Library/PrivateFrameworks/*/Versions/*/Frameworks/*/Versions/*/* /System/Library/Frameworks/*/Versions/*/Libraries/* 2>/dev/null >> /tmp/_fusym_tmp
echo Generating available symbol list step 3
cat /tmp/_fusym_tmp | sort | uniq > /tmp/_fusym_tmp_
mv -f /tmp/_fusym_tmp_ /tmp/_fusym_tmp
echo Generating used symbol list
nm -u -m "$1/Contents/MacOS/XUL" "$1/Contents/MacOS/"*.dylib 2>/dev/null | grep -vF " weak " | grep -v "^$1" |grep -vF .objc_class_name_ | sed 's/.* external _/_/' | cut -d ' ' -f1 | grep . | sort | uniq > /tmp/_fusym_tmp2
echo ---Undefined symbols---
diff /tmp/_fusym_tmp2 /tmp/_fusym_tmp | grep '^< ' | cut -c3-
rm -f /tmp/_fusym_tmp*
echo ---End---
