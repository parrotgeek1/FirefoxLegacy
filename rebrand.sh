#!/bin/bash
d="`pwd`"
p=$1
v=$2
rm -rf Firefox\ Legacy.app
mv Firefox.app Firefox\ Legacy.app
sed -i '' 's/Firefox/Firefox Legacy/' Firefox\ Legacy.app/Contents/Info.plist 
find Firefox\ Legacy.app/Contents/Resources/ -name InfoPlist.strings -delete 
cat update-settings.ini > Firefox\ Legacy.app/Contents/Resources/update-settings.ini
cd Firefox\ Legacy.app/Contents/Resources/browser
rm -rf omni
unzip -qqd omni omni.ja 2>/dev/null || true
cd omni
rm -f ../omni.ja
cp "$d/about-wordmark.svg" chrome/browser/content/branding/
sed -i '' "s/VERSIONVERSION/$v$p/" chrome/browser/content/branding/about-wordmark.svg
sed -i '' 's/%OS_VERSION%/Darwin 13.0.0/g' defaults/preferences/firefox.js # Widevine CDM
LC_ALL=C find . -name brand.dtd -exec sed -i '' -e 's/Firefox and the Firefox logos are trademarks of the Mozilla Foundation./Firefox and the Firefox logos are trademarks of the Mozilla Foundation. Firefox Legacy is a modification of Firefox created by ParrotGeek Software./g' -e 's/Firefox"/Firefox Legacy"/' -e  's/Mozilla Fire/Fire/' {} \;
LC_ALL=C find . -name brand.ftl -exec sed -i '' -e 's/Firefox and the Firefox logos are trademarks of the Mozilla Foundation./Firefox and the Firefox logos are trademarks of the Mozilla Foundation. Firefox Legacy is a modification of Firefox created by ParrotGeek Software./g' -e 's/Firefox$/Firefox Legacy/' -e  's/Mozilla Fire/Fire/' {} \;
LC_ALL=C find . -name aboutDialog.ftl -exec sed -i '' -e 's/update-noUpdatesFound =.*/update-noUpdatesFound = Check for Firefox Legacy updates at parrotgeek.com./g' -e 's/update-checkingForUpdates =.*/update-checkingForUpdates = Check for Firefox Legacy updates at parrotgeek.com./g' -e 's/update-unsupported =.*/update-unsupported = Check for Firefox Legacy updates at parrotgeek.com./g' -e 's/update-adminDisabled =.*/update-adminDisabled = Check for Firefox Legacy updates at parrotgeek.com./g' -e 's/{ -brand-short-name } is designed by/{ -brand-short-name } is a modification of Firefox, which is designed by/' {} \;
zip -qr0XD ../omni.ja *
cd ..
rm -rf omni
cd ..
rm -rf omni
unzip -qqd omni omni.ja 2>/dev/null || true
cd omni
rm -f ../omni.ja
sed -i '' 's/%OS_VERSION%/Darwin 13.0.0/g' greprefs.js # Widevine CDM
zip -qr0XD ../omni.ja *
cd ..
rm -rf omni
cd "$d"
touch Firefox\ Legacy.app
