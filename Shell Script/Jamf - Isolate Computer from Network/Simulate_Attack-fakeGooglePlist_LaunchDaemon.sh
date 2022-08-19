#/bin/bash

cp /usr/bin/whoami /tmp/test

cat > /Library/LaunchAgents/com.google.analytictest.plist << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
    	<key>Label</key>
			<string>com.google.test</string>
		<key>ProgramArguments</key>
			<array>
				<string>/tmp/test</string>
			</array>
        <key>RunAtLoad</key>
            <true/>
    </dict>
</plist>
EOL