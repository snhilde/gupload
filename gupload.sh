# /bin/sh

# FILL THESE IN
CLIENT_ID=""
CLIENT_SECRET=""
REFRESH_TOKEN=""
	
if [ $# -ne 1 ]; then
	echo "Usage:"
	echo "gupload <filename>"
	exit 2
fi

FILE=$1
RVALUE=`ping -w 10 -c 2 drive.google.com > /dev/null; echo $?` 
if [ `echo $RVALUE | tail -1` -ne 0 ]; then
	echo "Error establishing internet connection"
	echo "Please check for internet before proceeding"
	exit 1
fi
	
START_TIME=`/usr/bin/date +%s`
	
function get_token {
	ACCESS_JSON=`/usr/bin/curl --silent --data "client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&refresh_token=$REFRESH_TOKEN&grant_type=refresh_token" https://accounts.google.com/o/oauth2/token`
	ACCESS_TOKEN=`/usr/bin/echo $ACCESS_JSON | /usr/bin/grep -o '"[a-Z|0-9|_.-]*"' | /usr/bin/head -2 | /usr/bin/tail -1 | /usr/bin/tr -d \"`
	if [ -n $ACCESS_TOKEN ]; then
		echo "Successfully received access token"
	else
		echo "Failed to receive access token"
		echo "Please check Client ID, Client Secret, and Refresh Token"
		echo "Exiting..."
		exit 1
	fi
}

function upload_file {
	FILESIZE=`/usr/bin/stat -c %s $FILE`
	URL=`/usr/bin/curl --silent -X POST \
		--header "Authorization: Bearer $ACCESS_TOKEN" \
		--header "Content-Type: application/json; charset=UTF-8" \
		--header "X-Upload-Content-Length: $FILESIZE" \
		--data "{\"title\": \"$FILE\"}" \
		"https://www.googleapis.com/upload/drive/v2/files?uploadType=resumable&visibility=PRIVATE" \
		--dump-header - \
		| /usr/bin/sed -ne s/"Location: "//pi | /usr/bin/tr -d '\r\n '`
	if [ -z $URL ]; then
		echo "Error getting URL"
		echo "Exiting..."
		exit 1
	fi
	
	UPLOADID=`/usr/bin/curl --silent -X PUT \
		-H "Authorization: Bearer $ACCESS_TOKEN" \
		-H "Content-Length: $FILESIZE" \
		--upload-file "$FILE" \
		--dump-header - \
		$URL \
		| /usr/bin/sed -ne s/"\"id\": "//pi | /usr/bin/head -1 | /usr/bin/tr -d '",\r\n '`
	
	if [ $(( `/usr/bin/date +%s` - $START_TIME )) -ge 3600 ]; then
		echo "Access token timed out"
		echo "Cannot verify upload"
		echo "Upload ID:"
		echo $UPLOADID
		echo "Exiting..."
		exit 1
	fi
}

function verify_upload {
	RETURNID=`/usr/bin/curl --silent -X GET \
		-H "Authorization: Bearer $ACCESS_TOKEN" \
		https://www.googleapis.com/drive/v3/files/$UPLOADID \
		| /usr/bin/sed -ne s/"\"id\": "//pi | /usr/bin/tr -d '",\r\n'`
	
	if [ $UPLOADID = $RETURNID ]; then
		echo "Upload verified"
	else
		echo "Error verifying upload of $FILE"
		echo "Upload ID = $UPLOADID"
		echo "Return ID = $RETURNID"
		echo "Exiting..."
		exit 1
	fi
}

function calculate_time {
	END_TIME=`/usr/bin/date +%s`
	TOTAL_TIME=$(( $END_TIME - $START_TIME ))
	MINUTES=$(( $TOTAL_TIME / 60 ))
		if [ $MINUTES -ne 1 ]; then
			TIME_M="$MINUTES minutes"
		else
			TIME_M="$MINUTES minute"
		fi
	MINUTES=$(( $MINUTES * 60 ))
	TOTAL_TIME=$(( $TOTAL_TIME - $MINUTES ))
	if [ $TOTAL_TIME -ne 1 ]; then
		TIME_S="$TOTAL_TIME seconds"
	else
		TIME_S="$TOTAL_TIME second"
	fi
	
	/usr/bin/echo "$TIME_M, $TIME_S"
}
	
get_token
upload_file
verify_upload
echo "Upload completed in `calculate_time`"
