#!/bin/bash
d="`pwd`"
p=$1
v=$2
rm -rf Firefox\ Legacy.app
mv Firefox.app Firefox\ Legacy.app
/usr/bin/sed -i '' 's/Firefox/Firefox Legacy/g' Firefox\ Legacy.app/Contents/Info.plist
/usr/bin/sed -i '' "s/$v/$v$p/g" Firefox\ Legacy.app/Contents/Info.plist 
find Firefox\ Legacy.app/Contents/Resources/ -name InfoPlist.strings -delete 
cd Firefox\ Legacy.app/Contents/Resources/browser
rm -rf omni
unzip -qqd omni omni.ja 2>/dev/null || true
cd omni
rm -f ../omni.ja
cp "$d/about-wordmark.svg" chrome/browser/content/branding/
/usr/bin/sed -i '' "s/VERSIONVERSION/$v$p/" chrome/browser/content/branding/about-wordmark.svg
/usr/bin/sed -i '' 's/%OS_VERSION%/Darwin 13.0.0/g' defaults/preferences/firefox.js # Widevine CDM
/usr/bin/sed -i '' 's/pref("dom.push.enabled", false);/pref("dom.push.enabled", true);/g' defaults/preferences/firefox.js
/usr/bin/sed -i '' 's/pref("dom.serviceWorkers.enabled", false);/pref("dom.serviceWorkers.enabled", true);/g' defaults/preferences/firefox.js
/usr/bin/sed -i '' 's/pref("security.cert_pinning.enforcement_level", 1);/pref("security.cert_pinning.enforcement_level", 0);/g' defaults/preferences/firefox.js
/usr/bin/sed -i '' 's/pref("permissions.desktop-notification.postPrompt.enabled", false);/pref("permissions.desktop-notification.postPrompt.enabled", true);/g' defaults/preferences/firefox.js
LC_ALL=C find . -name brand.dtd -exec /usr/bin/sed -i '' -e 's/Firefox and the Firefox logos are trademarks of the Mozilla Foundation./Firefox and the Firefox logos are trademarks of the Mozilla Foundation. Firefox Legacy is a modification of Firefox created by ParrotGeek Software./g' -e 's/Firefox"/Firefox Legacy"/g' -e  's/Mozilla Firefox/Firefox/g' {} \;
LC_ALL=C find . -name brand.ftl -exec /usr/bin/sed -i '' -e 's/Firefox and the Firefox logos are trademarks of the Mozilla Foundation./Firefox and the Firefox logos are trademarks of the Mozilla Foundation. Firefox Legacy is a modification of Firefox created by ParrotGeek Software./g' -e 's/Firefox$/Firefox Legacy/g' -e  's/Mozilla Firefox/Firefox/g' {} \;
LC_ALL=C find . -name aboutDialog.ftl -exec /usr/bin/sed -i '' -e 's/update-adminDisabled =.*/update-adminDisabled = Check for Firefox Legacy updates at parrotgeek.com./g' -e 's/{ -brand-short-name } is designed by/{ -brand-short-name } is a modification of Firefox, which is designed by/' {} \;
zip -qr0XD ../omni.ja *
cd ..
rm -rf omni
cd ..
rm -rf omni
unzip -qqd omni omni.ja 2>/dev/null || true
cd omni
rm -f ../omni.ja
/usr/bin/sed -i '' 's/%OS_VERSION%/Darwin 13.0.0/g' greprefs.js # Widevine CDM
cat << EOF >> greprefs.js
pref("browser.tabs.remote.useCrossOriginEmbedderPolicy", true);
pref("browser.tabs.remote.useCrossOriginOpenerPolicy", true);
pref("dom.animations-api.getAnimations.enabled", true);
pref("dom.animations-api.timelines.enabled", true);
pref("dom.battery.enabled", false);
pref("dom.promise_rejection_events.enabled", true);
pref("dom.security.featurePolicy.enabled", true);
pref("dom.webnotifications.requireuserinteraction", true);
pref("javascript.options.experimental.fields", true);
pref("javascript.options.shared_memory", true);
pref("javascript.options.experimental.await_fix", true);
pref("layout.css.clip-path-path.enabled", true);
pref("layout.css.column-span.enabled", true);
pref("layout.css.contain.enabled", true);
pref("layout.css.individual-transform.enabled", true);
pref("layout.css.motion-path.enabled", true);
pref("layout.css.outline-style-auto.enabled", true);
pref("layout.css.resizeobserver.enabled", true);
pref("media.getusermedia.screensharing.enabled", false);
pref("security.tls.version.min", 3);
EOF
zip -qr0XD ../omni.ja *
cd ..
rm -rf omni
cd "$d"
touch Firefox\ Legacy.app
