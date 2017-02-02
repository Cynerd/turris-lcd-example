#!/bin/sh
set -e

echo "Content-type:text/html
";

if [ "$REQUEST_METHOD" != "POST" ]; then
	echo "Wrong request method"
	exit 0
fi

if grep -q "$REMOTE_ADDR" /tmp/turris-lcd-did; then
	echo "<!DOCTYPE html>
	<html>
	<head>
		<title>Turris Omnia Feed</title>
	</head>
		<h3>We already have post from you.</h3>
	</p>
	</html>"
	exit 0
else
	echo "$REMOTE_ADDR" >> /tmp/turris-lcd-did
fi

MESSAGE="$(cat | sed 's/message=//;s/+/ /g')"

echo "<!DOCTYPE html>
<html>
<head>
    <title>Turris Omnia Feed</title>
</head>
	<h3>Thank you for your message</h3>
	<p>$(cat<<EOFIKA
$MESSAGE
EOFIKA
)
</p>
</html>"

cat >/tmp/turris-lcd <<EOFIKA
$MESSAGE
EOFIKA
