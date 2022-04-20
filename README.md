# Health Platform iOS/WatchOS

## iOS and WatchOS app deployment

### Downloading XCode

Start by downloading XCode from the App Store. You will require a Mac on an OS able to run XCode, an iPhone running minimum iOS 14.0, and an Apple Watch running minimum WatchOS 7.0.

As of April 19 2022, the current XCode version is 13.3.1. For this version of XCode, your Mac will need a minimum OS of macOS Monterey 12. In the future as XCode continues to get updated, find the minimum macOS required [here](https://developer.apple.com/support/xcode).

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/XCode.png"/>

Download and install the XCode app. This will take a while. 

### Cloning the repository

In the Github repo, click the green Code button and copy the HTTPS Clone link.

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Clone%20Link.png"/>

Now open XCode and you should see this screen.

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/XCode%20Startup.png"/>

Click on clone an existing project. Paste the HTTPS Clone link you copied earlier into the text box at the top of the screen and click clone. You will be prompted to login to your Github account which has access to this repo.

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Clone.png"/>
    
### Update signing 

Start by going to Xcode -> Preferences -> Accounts and adding your Apple ID with the plus sign in the bottom left corner

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Xcode%20Accounts.png"/>

Sign up for an Apple developer account with your Apple ID if you don't have one already [here](https://developer.apple.com/account/#!/welcome).

Under HealthPlatformWatchOS -> Signing, change the team to your Apple account. It should say Your Name (Personal Team - youremail@email.com). Do this for each of the 3 targets in the Targets sidebar.

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

When the app is launched for the first time, you will be prompted to allow the app to read and write your HealthKit data. Accept all permissions in order for the app to work.

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Iphone%20Permissions%20.png" width="200"/>

After accepting the permissions, quit the app and go to the settings app. Navigate to HealthPlatformWatchOS and fill in the IoT Endpoint and Cognito Pool ID. Also ensure that the Background App Refresh setting is enabled.

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

- HR Sent: How many heart rate data points you just sent to AWS.

- HRV Sent: How many heart rate variability data points you just sent to AWS. If this ever shows -1 datapoints, a connection timeout occured. Check that you have a stable internet connection.

- BGTasks: How many background tasks are currently scheduled. When you open then app, it will say 0 remaning, but after a couple seconds the background task should get scheduled and display 1 remaining. If it continues to display 0 remaining, or if it ever shows -1 remaining, restart the app.

- Earliest BGTask Time: Earliest time that an automatic data sent can occur. If your background task did not register and shows 0 remaining, this will show a time in the past.

- Send Data: Sends all datapoints from your last send time to now to AWS. Ensure the IoT Status says connected before sending the data.

You can also leave your app in the background where it will periodically send data automatically. However, this is unpredictable as Apple has an algorithm which determines when this will happen which may take a long time before triggering. Therefore, it is best to trigger data sends with the button in the app if you can. The automatic data send will not work if you force quit/terminate your app.

### WatchOS App Setup

Start by accepting all permissions for the Apple Watch. Tap Review on the first window, then All Requested Data Below and Next for the next 2 windows.

<p float="left">
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Watch%20Permissions%201.png"  width="200"/>
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Watch%20Permissions%202.png" width="200"/>
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Watch%20Permissions%203.png"  width="200"/>
</p>

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

### Viewing your HealthKit Data

To view your HealthKit data which is coming from the watch, open the Health app on your iPhone, tap browse in the bottom left corner, and then tap Heart from the list of Health Categories.
