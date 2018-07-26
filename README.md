# gupload
Upload file to Google Drive

Usage:
```
gupload <filename>
```

gupload will upload one file at a time to your Google Drive account. You will need these credentials:
1. Client ID: Follow the steps on [this page](https://support.google.com/googleapi/answer/6158849?hl=en&ref_topic=7013279#) to obtain a Client ID.
2. Client Secret: In the [API Console](https://console.developers.google.com/), click the gear on the right side of the API name, and click the key (credentials) to download a JSON which will contain your Client Secret.
3. Refresh Token: Enter this code in a terminal (substituting in your Client ID):
```
curl --data "client_id=YOURCLIENTID&scope=https://www.googleapis.com/auth/drive.file" https://accounts.google.com/o/oauth2/device/code
```
This returns a user code, URL, and device code. Enter the user code at the URL to authorize access to the account. Keep the device code for later.

Next, enter this code in a terminal (substituting in your Client ID, Client Secret, and Device Code):
```
curl --data "client_id=YOURCLIENTID&client_secret=YOURCLIENTSECRET&code=YOURDEVICECODE&grant_type=http://oauth.net/grant_type/device/1.0" https://accounts.google.com/o/oauth2/token 
```
This returns an access token and a refresh token. The access token is good for one hour. The refresh token is good forever and is used to obtain another access token after the previous one expires.

Copy the credentials into the gupload shell script to enable smooth, effortless access to your Google Drive account.
