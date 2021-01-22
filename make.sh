#!/bin/bash -e

clang -fPIC -O3 -Wall -Wextra -Werror -Wno-unused-parameter -arch x86_64 -dynamiclib -mmacosx-version-min=10.8 -Wl,-reexport_library,/usr/lib/libSystem.B.dylib -current_version 169.3 -compatibility_version 1 -o libFxShim.dylib shim.c

clang -fPIC -O3 -Wall -Wextra -Werror -Wno-unused-parameter -arch x86_64 -dynamiclib -mmacosx-version-min=10.8 -framework CoreFoundation -Wl,-reexport_library,/System/Library/Frameworks/VideoToolbox.framework/Versions/A/VideoToolbox -current_version 1 -compatibility_version 1 -o libFxShimVT.dylib shimVT.c

clang -fPIC -O3 -Wall -Wextra -Werror -Wno-unused-parameter -arch x86_64 -dynamiclib -mmacosx-version-min=10.8 -framework CoreFoundation -Wl,-reexport_library,/System/Library/Frameworks/CoreMedia.framework/Versions/A/CoreMedia -current_version 1 -compatibility_version 1 -o libFxShimCM.dylib shimCM.c

clang -lobjc -fPIC -O3 -Wall -Wextra -Werror -Wno-unused-parameter -arch x86_64 -dynamiclib -mmacosx-version-min=10.8 -framework AppKit -current_version 1 -compatibility_version 1 -o libAppKitFixes.dylib AppKitFixes.m

gcc -fPIC -O3 -Wall -Wextra -Werror -arch x86_64 -dynamiclib -mmacosx-version-min=10.8 -Wl,-reexport_library,/System/Library/Frameworks/Security.framework/Versions/A/Security -current_version 55163.44 -compatibility_version 1 -o libFxShimSecurity.dylib shimSecurity.c

mv libFxShim*.dylib libAppKitFixes.dylib Firefox.app/Contents/MacOS/

install_name_tool -change /usr/lib/libSystem.B.dylib '@loader_path/libFxShim.dylib' Firefox.app/Contents/MacOS/libnss3.dylib 

install_name_tool -change /usr/lib/libSystem.B.dylib '@loader_path/libFxShim.dylib' Firefox.app/Contents/MacOS/firefox 

install_name_tool -change /usr/lib/libSystem.B.dylib '@loader_path/libFxShim.dylib' Firefox.app/Contents/MacOS/XUL

install_name_tool -change /System/Library/Frameworks/VideoToolbox.framework/Versions/A/VideoToolbox '@loader_path/libFxShimVT.dylib' Firefox.app/Contents/MacOS/XUL

install_name_tool -change /System/Library/Frameworks/CoreMedia.framework/Versions/A/CoreMedia '@loader_path/libFxShimCM.dylib' Firefox.app/Contents/MacOS/XUL

install_name_tool -change /System/Library/Frameworks/Security.framework/Versions/A/Security '@loader_path/libFxShimSecurity.dylib' Firefox.app/Contents/MacOS/XUL

cd inject_lib
./m.sh
cd ..
inject_lib/inject_lib Firefox.app/Contents/MacOS/XUL Firefox.app/Contents/MacOS/libAppKitFixes.dylib >/dev/null 2>&1

# gma 950
perl -pi -e 's/\x3D\xC8\x00\x00\x00\x0F\x82/\x3D\x64\x00\x00\x00\x0F\x82/' Firefox.app/Contents/MacOS/XUL
#https://hg.mozilla.org/mozreview/gecko/file/tip/gfx/gl/GLContext.cpp
#  if (mVersion < 200)
#        return false;
# to 100

#widevine
perl -pi -e 's/VerifyCdmHost_/VerifyCdmNOPE_/g' Firefox.app/Contents/MacOS/XUL

LC_ALL=C /usr/bin/sed -i '' 's/>10.9.0</>10.8.0</' Firefox.app/Contents/Info.plist
v=`cat Firefox.app/Contents/Info.plist  | grep -A1 CFBundleShortVersionString | tail -n1 | cut -d '>' -f2 | cut -d '<' -f1`
p=`cat patch.txt`
bash -e ./rebrand.sh $p $v || exit $?

rm -rf "Firefox Legacy.app/Contents/Library/LaunchServices"

/usr/bin/sed -i '' "s/$v/$v$p/" Firefox\ Legacy.app/Contents/Info.plist 

mkdir -p Firefox\ Legacy.app/Contents/Resources/distribution
cat policies.json > Firefox\ Legacy.app/Contents/Resources/distribution/policies.json

codesign --deep -f -s "-" Firefox\ Legacy.app >/dev/null 2>&1

rm -f FirefoxLegacy$v$p.zip 
xattr -cr Firefox\ Legacy.app
zip -9 -r FirefoxLegacy$v$p.zip Firefox\ Legacy.app
