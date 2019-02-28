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
unzip -qqd omni omni.ja 2>/dev/null
cd omni
rm -f ../omni.ja
LC_ALL=C sed -i '' "s/AppConstants.MOZ_APP_VERSION_DISPLAY;/AppConstants.MOZ_APP_VERSION_DISPLAY+\"p$p\";/" chrome/browser/content/browser/aboutDialog.js chrome/browser/content/browser/preferences/in-content/main.js
cp "$d/branding"/* chrome/browser/content/branding/
LC_ALL=C find . -name brand.dtd -exec sed -i '' -e 's/Firefox and the Firefox logos are trademarks of the Mozilla Foundation./Firefox and the Firefox logos are trademarks of the Mozilla Foundation. Firefox Legacy is a modification of Firefox created by ParrotGeek Software./g' -e 's/Firefox"/Firefox Legacy"/' -e  's/Mozilla Fire/Fire/' {} \;
LC_ALL=C find . -name brand.ftl -exec sed -i '' -e 's/Firefox and the Firefox logos are trademarks of the Mozilla Foundation./Firefox and the Firefox logos are trademarks of the Mozilla Foundation. Firefox Legacy is a modification of Firefox created by ParrotGeek Software./g' -e 's/Firefox$/Firefox Legacy/' -e  's/Mozilla Fire/Fire/' {} \;
LC_ALL=C find . -name aboutDialog.ftl -exec sed -i '' -e 's/update-noUpdatesFound =.*/update-noUpdatesFound = Check for Firefox Legacy updates at parrotgeek.com./g' -e 's/update-checkingForUpdates =.*/update-checkingForUpdates = Check for Firefox Legacy updates at parrotgeek.com./g' -e 's/update-unsupported =.*/update-unsupported = Check for Firefox Legacy updates at parrotgeek.com./g' -e 's/update-adminDisabled =.*/update-adminDisabled = Check for Firefox Legacy updates at parrotgeek.com./g' -e 's/{ -brand-short-name } is designed by/{ -brand-short-name } is a modification of Firefox, which is designed by/' {} \;
zip -qr0XD ../omni.ja *
cd ..
rm -rf omni
cd ..
unzip -qqd omni omni.ja 2>/dev/null
cd omni
LC_ALL=C sed -i '' "s/AppConstants.MOZ_APP_VERSION_DISPLAY;/AppConstants.MOZ_APP_VERSION_DISPLAY+\"p$p\";/" chrome/toolkit/content/global/aboutSupport.js
rm -f ../omni.ja
zip -qr0XD ../omni.ja *
cd ..
rm -rf omni
cd "$d"
touch Firefox\ Legacy.app
