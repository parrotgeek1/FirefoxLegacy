#!/bin/bash -e 

gcc -fPIC -O3 -Wall -Wextra -Werror -Wno-unused-parameter -arch x86_64 -dynamiclib -mmacosx-version-min=10.7 -Wl,-reexport_library,/usr/lib/libSystem.B.dylib -current_version 1 -compatibility_version 1 -o libFxShim.dylib shim.c

gcc -fPIC -O3 -Wall -Wextra -Werror -Wno-sign-compare -arch x86_64 -mmacosx-version-min=10.7 -o trampoline trampoline.c

mv libFxShim.dylib Firefox.app/Contents/MacOS/

install_name_tool -change /usr/lib/libSystem.B.dylib '@loader_path/libFxShim.dylib' Firefox.app/Contents/MacOS/libnss3.dylib 

install_name_tool -change /usr/lib/libSystem.B.dylib '@loader_path/libFxShim.dylib' Firefox.app/Contents/MacOS/firefox 

install_name_tool -change /usr/lib/libSystem.B.dylib '@loader_path/libFxShim.dylib' Firefox.app/Contents/MacOS/XUL

sed -i '' 's/>10.9.0</>10.7.0</' Firefox.app/Contents/Info.plist
v=`cat Firefox.app/Contents/Info.plist  | grep -A1 CFBundleShortVersionString | tail -n1 | cut -d '>' -f2 | cut -d '<' -f1`
p=`cat patch.txt`
bash ./rebrand.sh $p $v

find Firefox\ Legacy.app -type f -perm 0755 -not -name '*.dylib' | while read a; do 
file "$a" | grep -q executable && (mv "$a" "${a}_real"; cp trampoline "$a"; codesign --deep -f -s 'Mac Developer' "$a"; codesign --deep -f -s 'Mac Developer' "${a}_real") || true
done
rm -f trampoline

sed -i '' "s/$v/${v}p$p/" Firefox\ Legacy.app/Contents/Info.plist 

codesign --deep -f -s 'Mac Developer' Firefox\ Legacy.app
rm -f Firefox\ Legacy\ ${v}p$p.zip 
xattr -cr Firefox\ Legacy.app
zip -9 -r Firefox\ Legacy\ ${v}p$p.zip Firefox\ Legacy.app
