deep link
https://medium.com/flutter-community/deep-links-and-flutter-applications-how-to-handle-them-properly-8c9865af9283

        https://stackoverflow.com/questions/41031908/how-to-restrict-all-other-paths-except-one-for-universal-link-in-ios-to-open-app
https://stackoverflow.com/questions/59970266/how-to-handle-deep-linking-to-a-flutter-app
https://www.raywenderlich.com/6080-universal-links-make-the-connection
https://newbedev.com/how-to-set-correct-content-type-for-apple-app-site-association-file-on-nginx-rails
https://stackoverflow.com/questions/41031908/how-to-restrict-all-other-paths-except-one-for-universal-link-in-ios-to-open-app

ios:   https://branch.io/resources/aasa-validator/
android: https://developers.google.com/digital-asset-links/tools/generator
https://help.short.io/en/articles/4171170-where-to-find-android-app-package-name-and-sha256-fingerprint-certificate
https://newbedev.com/how-know-my-app-package-fingerprint-sha256-code-example

ANDROID   -----  in AndroidManifest.xml:

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <!-- Accepts URIs that begin with "https://rhd.dmasotti.space/rhd_sc” -->
                <data android:scheme="https"
                    android:host="rhd.dmasotti.space"
                    android:pathPrefix="/rhd_sc" />
                <!-- note that the leading "/" is required for pathPrefix-->
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <!-- Accepts URIs that begin with "rhd_sc://item” -->
                <data android:scheme="rhd_sc"
                    android:host="item" />
            </intent-filter>

IOS:   

Info.plist


<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>item</string>
        <key>CFBundleURLSchemes</key>
        <array>
               <string>rhd_sc</string>
        </array>
    </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>https</string>
    <string>http</string>
    <string>rhd_sc</string>
</array>


Runner.entitlements

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>development</string>
	<key>com.apple.developer.associated-domains</key>
	<array>
		<string>applinks:rhd.dmasotti.space</string>
	</array>
</dict>
</plist>

sul server rhd.dmasotti.space in file  .well-known/apple-app-site-association
XHC8ZM9PVH è il development team

{
        "applinks": {
            "apps": [],
            "details": [
                {
                    "appID": "XHC8ZM9PVH.it.alfagroup.rhdtimesheet",
                    "paths": [ "/rhd_timesheet","/rhd_timesheet/*" ]
                },
                {
                    "appID": "XHC8ZM9PVH.it.alfagroup.rhd5",
                    "paths": [ "/rhd","/rhd/*" ]
                },
                {
                    "appID": "ABCD1234.com.apple.wwdc",
                    "paths": [ "*" ]
                }
            ]
        }
}



chiamare su IOS emulator:

xcrun simctl openurl booted "rhd-ts://item?appId=c87cbb47-f820-3eb9-8fb3-b22d661b4f2"

xcrun simctl openurl booted "https://rhd.dmasotti.space/rhd_timesheet?appId=c87cbb47-f820-3eb9-8fb3-b22d661b4f2"
xcrun simctl openurl booted "https://rhd.dmasotti.space/rhd_timesheet?appId=c87cbb47-f820-3eb9-8fb3-b22d661b4f9"

xcrun simctl openurl booted "https://rhd.dmasotti.space/rhd/?item?item=c87cbb47-f820-3eb9-8fb3-b22d661b4f2&d=eyJ1diI6Imh0dHBzOi8vd3d3LmdpdC5rcXUucHR2Lm15Ymx1ZWhvc3QubWUvYS5waHA/IiwiZXQiOiIwZTBkMGY4Zi1kMzllLTM4YzMtYjlmNS02ZTE0MzBjOWVlZTkifQ=="

xcrun simctl openurl booted "https://rhd.dmasotti.space/rhd_timesheet?d=%7B%22uv%22%3A%22https%3A%5C%2F%5C%2Fwww.git.kqu.ptv.mybluehost.me%5C%2Fa.php%3F%22%2C%22et%22%3A%220e0d0f8f-d39e-38c3-b9f5-6e1430c9eee9%22%7D"
xcrun simctl openurl booted "rhd-ts://item/?d=%7B%22uv%22%3A%22https%3A%5C%2F%5C%2Fwww.git.kqu.ptv.mybluehost.me%5C%2Fa.php%3F%22%2C%22et%22%3A%220e0d0f8f-d39e-38c3-b9f5-6e1430c9eee9%22%7D"

chiamare su IOS device collegato con usb (NON VA):

xcrun simctl openurl <device-udid> <url>

xcrun simctl openurl 658e999c8ea1c9b2e90bfea8b32bb70d3b8f905b "https://rhd.dmasotti.space/rhd/?appId=c87cbb47-f820-3eb9-8fb3-b22d661b4f3"



adb shell am start -a "android.intent.action.VIEW" -d "https://rhd.dmasotti.space/timesheet/?appId=c87cbb47-f820-3eb9-8fb3-b22d661b4f3"

adb shell am start -a "android.intent.action.VIEW" -d "rhd-ts://item?appId=c87cbb47-f820-3eb9-8fb3-b22d661b4f3"


Testare aperture:

https://labs.dmasotti.space/links.php

https://rhd.dmasotti.space/rhd/

https://rhd.dmasotti.space/rhd/?appId=c87cbb47-f820-3eb9-8fb3-b22d661b4f3

https://rhd.dmasotti.space/rhd/?d=%7B%22uv%22%3A%22https%3A%5C%2F%5C%2Fwww.git.kqu.ptv.mybluehost.me%5C%2Fa.php%3F%22%2C%22et%22%3A%220e0d0f8f-d39e-38c3-b9f5-6e1430c9eee9%22%7D
