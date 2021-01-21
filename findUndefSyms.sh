#!/bin/sh
nm -U /System/Library/Frameworks/*/Versions/*/* "$1"/Contents/MacOS/* /System/Library/Frameworks/*/Versions/*/Frameworks/*/Versions/*/* /usr/lib/*.dylib /usr/lib/*/*.dylib 2>/dev/null> _tmp
nm -U /System/Library/PrivateFrameworks/*/Versions/*/* /System/Library/PrivateFrameworks/*/Versions/*/Libraries/* /System/Library/PrivateFrameworks/*/Versions/*/Frameworks/*/Versions/*/* /System/Library/Frameworks/*/Versions/*/Libraries/* 2>/dev/null >> _tmp
nm -u -m "$1/Contents/MacOS/XUL" "$1/Contents/MacOS/"*.dylib 2>/dev/null | grep -vF " weak " | grep -v "^$1" |grep -vF .objc_class_name_| sed 's/.* external _/_/' | cut -d ' ' -f1| grep . | while read a; do grep -q " $a$" _tmp || echo $a; done > undef_symbols.txt
rm -f _tmp
say Done
echo Done, check undef_symbols.txt
