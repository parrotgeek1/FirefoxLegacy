#!/bin/bash -e 

cd unsign; make -s; cd ..

gcc -fPIC -O3 -Wall -Wextra -Werror -Wno-unused-parameter -arch x86_64 -dynamiclib -mmacosx-version-min=10.7 -Wl,-reexport_library,/usr/lib/libSystem.B.dylib -current_version 1 -compatibility_version 1 -o libFxShim.dylib shim.c

# NSObject was in CoreFoundation in Lion, not libobjc
gcc -fPIC -O3 -Wall -Wextra -Werror -arch x86_64 -dynamiclib -mmacosx-version-min=10.7 -Wl,-reexport_library,/usr/lib/libobjc.A.dylib -Wl,-reexport_library,/System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation -current_version 1 -compatibility_version 1 -o libFxShimObjc.dylib shimObjc.c

gcc -fPIC -O3 -Wall -Wextra -Werror -arch x86_64 -dynamiclib -lobjc -mmacosx-version-min=10.7 -Wl,-reexport_library,/System/Library/Frameworks/Foundation.framework/Versions/C/Foundation -current_version 300 -compatibility_version 300 -o libFxShimFoundation.dylib shimFoundation.m

gcc -fPIC -O3 -Wall -Wextra -Werror -arch x86_64 -dynamiclib -mmacosx-version-min=10.7 -Wl,-reexport_library,/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/CoreText.framework/Versions/A/CoreText -framework CoreFoundation -current_version 1 -compatibility_version 1 -o libFxShimCoreText.dylib shimCoreText.c

gcc -fPIC -O3 -Wall -Wextra -Werror -Wno-unused-parameter -arch x86_64 -dynamiclib -lobjc -mmacosx-version-min=10.7 -Wl,-reexport_library,/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit -current_version 45 -compatibility_version 45 -o libFxShimAppKit.dylib shimAppKit.m

gcc -fPIC -O3 -Wall -Wextra -Werror -arch x86_64 -dynamiclib -mmacosx-version-min=10.7 -current_version 1 -compatibility_version 1 -framework CoreFoundation -o libFxShimVT.dylib shimVT.c

gcc -fPIC -O3 -Wall -Wextra -Werror -Wno-sign-compare -arch x86_64 -mmacosx-version-min=10.7 -o trampoline trampoline.c

mv libFxShim*.dylib Firefox.app/Contents/MacOS/

install_name_tool -change /usr/lib/libSystem.B.dylib '@loader_path/libFxShim.dylib' Firefox.app/Contents/MacOS/libnss3.dylib 

install_name_tool -change /usr/lib/libSystem.B.dylib '@loader_path/libFxShim.dylib' Firefox.app/Contents/MacOS/firefox 

install_name_tool -change /usr/lib/libSystem.B.dylib '@loader_path/libFxShim.dylib' Firefox.app/Contents/MacOS/XUL
install_name_tool -change /usr/lib/libobjc.A.dylib '@loader_path/libFxShimObjc.dylib' Firefox.app/Contents/MacOS/XUL
install_name_tool -change /System/Library/Frameworks/VideoToolbox.framework/Versions/A/VideoToolbox '@loader_path/libFxShimVT.dylib' Firefox.app/Contents/MacOS/XUL
install_name_tool -change /System/Library/Frameworks/Foundation.framework/Versions/C/Foundation '@loader_path/libFxShimFoundation.dylib' Firefox.app/Contents/MacOS/XUL
install_name_tool -change /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit '@loader_path/libFxShimAppKit.dylib' Firefox.app/Contents/MacOS/XUL
perl -pi -e 's/OBJC_CLASS_\$_NSSharingService/OBJC_CLASS_\$_NSSharingServic2/g' Firefox.app/Contents/MacOS/XUL

LC_ALL=C sed -i '' 's/>10.9.0</>10.7.0</' Firefox.app/Contents/Info.plist
v=`cat Firefox.app/Contents/Info.plist  | grep -A1 CFBundleShortVersionString | tail -n1 | cut -d '>' -f2 | cut -d '<' -f1`
p=`cat patch.txt`
bash ./rebrand.sh $p $v

#objc
#Binary file ./Firefox Legacy.app/Contents/Library/LaunchServices/org.mozilla.updater_real matches
#Binary file ./Firefox Legacy.app/Contents/MacOS/crashreporter.app/Contents/MacOS/crashreporter_real matches
#Binary file ./Firefox Legacy.app/Contents/MacOS/updater.app/Contents/MacOS/org.mozilla.updater_real matches

install_name_tool -change /usr/lib/libobjc.A.dylib '@loader_path/../../../libFxShimObjc.dylib' "Firefox Legacy.app/Contents/MacOS/crashreporter.app/Contents/MacOS/crashreporter"
install_name_tool -change /usr/lib/libobjc.A.dylib '@loader_path/../../../libFxShimObjc.dylib' "Firefox Legacy.app/Contents/MacOS/updater.app/Contents/MacOS/org.mozilla.updater"
rm -rf "Firefox Legacy.app/Contents/Library/LaunchServices"

find Firefox\ Legacy.app -type f -perm 0755 -not -name '*.dylib' | while read a; do 
file "$a" | grep -q executable && (mv "$a" "${a}_real"; cp trampoline "$a"; unsign/unsign "${a}_real"; cat "${a}_real.unsigned" > "${a}_real"; rm "${a}_real.unsigned"; perl -pi -e 's/\x28\x00\x00\x80/\x28\x00\x00\x00/' "${a}_real") || true
done
rm -f trampoline

ls Firefox\ Legacy.app/Contents/MacOS/*.dylib | fgrep -v libFxShim | while read a; do 
	unsign/unsign "$a"
	cat "$a.unsigned" > "$a"
	rm "$a.unsigned"
done

install_name_tool -change /System/Library/Frameworks/CoreGraphics.framework/Versions/A/CoreGraphics /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/CoreGraphics.framework/Versions/A/CoreGraphics Firefox\ Legacy.app/Contents/MacOS/XUL
install_name_tool -change /System/Library/Frameworks/CoreText.framework/Versions/A/CoreText '@loader_path/libFxShimCoreText.dylib' Firefox\ Legacy.app/Contents/MacOS/XUL
install_name_tool -change /System/Library/Frameworks/ImageIO.framework/Versions/A/ImageIO /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/ImageIO.framework/Versions/A/ImageIO Firefox\ Legacy.app/Contents/MacOS/XUL

unsign/unsign Firefox\ Legacy.app/Contents/MacOS/XUL
cat Firefox\ Legacy.app/Contents/MacOS/XUL.unsigned > Firefox\ Legacy.app/Contents/MacOS/XUL
rm Firefox\ Legacy.app/Contents/MacOS/XUL.unsigned

sed -i '' "s/$v/$v$p/" Firefox\ Legacy.app/Contents/Info.plist 

rm -rf Firefox\ Legacy.app/Contents/_CodeSignature Firefox\ Legacy.app/Contents/MacOS/*.app/Contents/_CodeSignature

rm -f Firefox\ Legacy\ $v$p.zip 
xattr -cr Firefox\ Legacy.app
zip -9 -r Firefox\ Legacy\ $v$p.zip Firefox\ Legacy.app
