# Health Platform iOS/WatchOS

## iOS and WatchOS app deployment

### Update signing 

Start by going to Xcode -> Preferences -> Accounts and adding your Apple ID with the plus sign in the bottom right corner

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Xcode%20Accounts.png"/>

Sign up for a Apple developer account with your Apple ID if you don't have one already [here](https://developer.apple.com/account/#!/welcome).

Under HealthPlatformWatchOS -> Signing, change the team to your Apple account. It should say Your Name (Personal Team - youremail@email.com) Do this for each of the 3 targets in the targets sidebar.

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Signing.png"/>

### Deploying to your device

Plug in your iPhone to your Mac and make sure your Apple Watch is connected to the iPhone.

At the top of the screen select your iPhone from the list and then click the play button to run the app. Do the same for your Apple watch. Select HealthPlatformWatchOS for the iPhone app and HealthPlatformWatchOS WatchKit App for the Apple Watch app.

The Apple Watch app may take a couple minutes to attach to your watch.

<p float="left">
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Run%20App%201.png"/>
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Run%20App%202.png"/>
</p>

### Setting up the iOS app

After the iOS app has launched for the first time, quit the app and go to the settings app. Navigate to HealthPlatformWatchOS and fill in the IoT Endpoint and Cognito Pool ID. Also ensure that the Background App Refresh setting is enabled.

<p float="left">
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/App%20Settings%201.png" width="200"/>
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/App%20Settings%202.png" width="200"/>
</p>

After you have set the AWS Constants, relaunch the app and the IoT status should say Connected. If this is not the case, check that you are connected to WiFi, and also that you entered your IoT Endpoint and Cognito Pool ID correctly.

### iOS app overview

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/iOS%20App.png" width="200"/>

- IoT Status: Shows if you are connected to AWS IoT. If you background the app it will disconnect and when you tab back into the app, it will say Connection Error. Give it some time, and the app will reconnect itself.

- Device ID: A unique ID given to your iPhone. Use this to register your device in the frontend.

- Last Send Time: This shows the last time you sent data to AWS.

- HR Sent: How many heart rate data points you just send to AWS.

- HRV Sent: How many heart rate variability data points you just send to AWS.

- Send Data: Sends all datapoints from your last send time to now to AWS. Ensure the IoT Status says connected before sending the data.

You can also leave your app in the background where it will periodically send data automatically. However, this is unpredictabe as Apple has an algorithm which determines when this will happen which may take a long time before triggering. Therefore, it is best to trigger data sends with the button in the app if you can. The automatic data send will not work if you force quit/terminate your app.

### WatchOS App Overview

<p float="left">
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Run%20Button.png"  width="200"/>
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Watch%20App.png" width="200"/>
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Stop%20Pause.png"  width="200"/>
</p>

- Run Button: Tap this button to initate the recording of you heart rate and heart rate variability.

- Main App: You will see the time elapsed and your most recent heart rate reading.

- Stop Pause: Swipe left to pause or end the workout.

You must have a workout started either in this app or any other workout app for your heart rate and heart rate variability to be constantly monitored.
