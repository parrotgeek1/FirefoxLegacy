#!/bin/bash -e 

cd unsign; make -s; cd ..

#ok
gcc -fPIC -O3 -Wall -Wextra -Werror -Wno-unused-parameter -arch x86_64 -dynamiclib -mmacosx-version-min=10.7 -Wl,-reexport_library,/usr/lib/libSystem.B.dylib -current_version 159.1 -compatibility_version 1 -o libFxShim.dylib shim.c

# NSObject was in CoreFoundation in Lion, not libobjc
#ok
gcc -fPIC -O3 -Wall -Wextra -Werror -arch x86_64 -dynamiclib -mmacosx-version-min=10.7 -Wl,-reexport_library,/usr/lib/libobjc.A.dylib -Wl,-reexport_library,/System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation -current_version 228 -compatibility_version 1 -o libFxShimObjc.dylib shimObjc.c

#ok
gcc -fPIC -O3 -Wall -Wextra -Werror -arch x86_64 -dynamiclib -lobjc -mmacosx-version-min=10.7 -Wl,-reexport_library,/System/Library/Frameworks/Foundation.framework/Versions/C/Foundation -current_version 833.25 -compatibility_version 300 -o libFxShimFoundation.dylib shimFoundation.m

#ok
gcc -fPIC -O3 -Wall -Wextra -Werror -arch x86_64 -dynamiclib -mmacosx-version-min=10.7 -Wl,-reexport_library,/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/CoreText.framework/Versions/A/CoreText -framework CoreFoundation -current_version 1 -compatibility_version 1 -o libFxShimCoreText.dylib shimCoreText.c

#ok
gcc -fPIC -O3 -Wall -Wextra -Werror -Wno-unused-parameter -arch x86_64 -dynamiclib -mmacosx-version-min=10.7 -Wl,-reexport_library,/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/CoreGraphics.framework/Versions/A/CoreGraphics -current_version 600 -compatibility_version 64 -o libFxShimCoreGraphics.dylib shimCoreGraphics.c

#ok
gcc -fPIC -O3 -Wall -Wextra -Werror -Wno-unused-parameter -arch x86_64 -dynamiclib -lobjc -mmacosx-version-min=10.7 -Wl,-reexport_library,/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit -current_version 1138.51 -compatibility_version 45 -o libFxShimAppKit.dylib shimAppKit.m

#ok
gcc -fPIC -O3 -Wall -Wextra -Werror -arch x86_64 -dynamiclib -mmacosx-version-min=10.7 -current_version 1 -compatibility_version 1 -framework CoreFoundation -o libFxShimVT.dylib shimVT.c

#ok
gcc -fPIC -O3 -Wall -Wextra -Werror -arch x86_64 -dynamiclib -mmacosx-version-min=10.7 -Wl,-reexport_library,/System/Library/Frameworks/Security.framework/Versions/A/Security -current_version 55148.6 -compatibility_version 1 -o libFxShimSecurity.dylib shimSecurity.c

gcc -fPIC -O3 -Wall -Wextra -Werror -Wno-sign-compare -arch x86_64 -mmacosx-version-min=10.7 -framework AppKit -o trampoline trampoline.c

mv libFxShim*.dylib Firefox.app/Contents/MacOS/

install_name_tool -change /usr/lib/libSystem.B.dylib '@loader_path/libFxShim.dylib' Firefox.app/Contents/MacOS/libnss3.dylib 

install_name_tool -change /usr/lib/libSystem.B.dylib '@loader_path/libFxShim.dylib' Firefox.app/Contents/MacOS/firefox 

install_name_tool -change /usr/lib/libSystem.B.dylib '@loader_path/libFxShim.dylib' Firefox.app/Contents/MacOS/XUL
install_name_tool -change /usr/lib/libobjc.A.dylib '@loader_path/libFxShimObjc.dylib' Firefox.app/Contents/MacOS/XUL
install_name_tool -change /System/Library/Frameworks/VideoToolbox.framework/Versions/A/VideoToolbox '@loader_path/libFxShimVT.dylib' Firefox.app/Contents/MacOS/XUL
install_name_tool -change /System/Library/Frameworks/Foundation.framework/Versions/C/Foundation '@loader_path/libFxShimFoundation.dylib' Firefox.app/Contents/MacOS/XUL
install_name_tool -change /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit '@loader_path/libFxShimAppKit.dylib' Firefox.app/Contents/MacOS/XUL
install_name_tool -change /System/Library/Frameworks/Security.framework/Versions/A/Security '@loader_path/libFxShimSecurity.dylib' Firefox.app/Contents/MacOS/XUL
perl -pi -e 's/OBJC_CLASS_\$_NSSharingService/OBJC_CLASS_\$_NSSharingServic2/g' Firefox.app/Contents/MacOS/XUL
perl -pi -e 's/OBJC_CLASS_\$_NSSharingServic2PickerTouchBarItem/OBJC_CLASS_\$_NSSharingServicePickerTouchBarItem/g' Firefox.app/Contents/MacOS/XUL # fix false positive

# gma 950
perl -pi -e 's/\x3D\xC8\x00\x00\x00\x0F\x82/\x3D\x64\x00\x00\x00\x0F\x82/' Firefox.app/Contents/MacOS/XUL
#https://hg.mozilla.org/mozreview/gecko/file/tip/gfx/gl/GLContext.cpp
#  if (mVersion < 200)
#        return false;
# to 100

#widevine
perl -pi -e 's/VerifyCdmHost_/VerifyCdmNOPE_/g' Firefox.app/Contents/MacOS/XUL

#it must be 10.7.5 to work around coreui issue in 10.7.0-4
LC_ALL=C /usr/bin/sed -i '' 's/>10.9.0</>10.7.5</g' Firefox.app/Contents/Info.plist
v=`cat Firefox.app/Contents/Info.plist  | grep -A1 CFBundleShortVersionString | tail -n1 | cut -d '>' -f2 | cut -d '<' -f1`
p=`cat patch.txt`
bash -e ./rebrand.sh $p $v || exit $?

#objc
install_name_tool -change /usr/lib/libobjc.A.dylib '@loader_path/../../../libFxShimObjc.dylib' "Firefox Legacy.app/Contents/MacOS/crashreporter.app/Contents/MacOS/crashreporter"

find Firefox\ Legacy.app -type f -perm 0755 -not -name '*.dylib' -not -name '*.py' | while read a; do 
file "$a" | grep -q executable && (mv "$a" "${a}_real"; cp trampoline "$a"; unsign/unsign "${a}_real"; cat "${a}_real.unsigned" > "${a}_real"; rm "${a}_real.unsigned"; perl -pi -e 's/\x28\x00\x00\x80/\x28\x00\x00\x00/' "${a}_real") || true
done
rm -f trampoline

ls Firefox\ Legacy.app/Contents/MacOS/*.dylib | fgrep -v libFxShim | while read a; do 
	unsign/unsign "$a"
	cat "$a.unsigned" > "$a"
	rm "$a.unsigned"
done

install_name_tool -change /System/Library/Frameworks/CoreGraphics.framework/Versions/A/CoreGraphics '@loader_path/libFxShimCoreGraphics.dylib' Firefox\ Legacy.app/Contents/MacOS/XUL
install_name_tool -change /System/Library/Frameworks/CoreText.framework/Versions/A/CoreText '@loader_path/libFxShimCoreText.dylib' Firefox\ Legacy.app/Contents/MacOS/XUL
install_name_tool -change /System/Library/Frameworks/ImageIO.framework/Versions/A/ImageIO /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/ImageIO.framework/Versions/A/ImageIO Firefox\ Legacy.app/Contents/MacOS/XUL

unsign/unsign Firefox\ Legacy.app/Contents/MacOS/XUL
cat Firefox\ Legacy.app/Contents/MacOS/XUL.unsigned > Firefox\ Legacy.app/Contents/MacOS/XUL
rm Firefox\ Legacy.app/Contents/MacOS/XUL.unsigned

rm -rf Firefox\ Legacy.app/Contents/_CodeSignature Firefox\ Legacy.app/Contents/MacOS/*.app/Contents/_CodeSignature

#updater/telemetry/studies removal, home page link
rm -rf Firefox\ Legacy.app/Contents/MacOS/updater.app
plutil -remove SMPrivilegedExecutables Firefox\ Legacy.app/Contents/Info.plist
rm -rf Firefox\ Legacy.app/Contents/Library 
find Firefox\ Legacy.app -name '*.sig' -not -name libclearkey.dylib.sig -type f -delete
mkdir -p Firefox\ Legacy.app/Contents/Resources/distribution
cat policies.json > Firefox\ Legacy.app/Contents/Resources/distribution/policies.json

rm -f FirefoxLegacy$v$p.zip 
xattr -cr Firefox\ Legacy.app
zip -9 -r FirefoxLegacy$v$p.zip Firefox\ Legacy.app
