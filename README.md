# Health Platform iOS/WatchOS

## HealthPlatform frontend/backend deployment

Start by following the instructions [here](https://github.com/UBC-CIC/health-platform/tree/main/webapp) to deploy both the backend and frontend of the main Health Platform project. This will create a Cognito Pool for you, which along with the IoT Endpoint will be used later to send your data to AWS. Also configure any gas sensors that you might have at this time.

## iOS and WatchOS App Deployment (SIMPLE)

** NOTE: This version of the app will only last on your device for 7 days as it is signed with a free developer account. **

Start by downloading the iOS App [here](https://d3hq6hb4fjgj76.cloudfront.net/HealthPlatform.ipa) onto your Mac.

Plug your iPhone into your Mac and drag the ipa file over to your iPhone in the Finder window to install.

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/ipa%20File.png"/>

## iOS and WatchOS App Deployment (ADVANCED)

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
    
### Update signing and bundle indentifiers

Start by going to Xcode -> Preferences -> Accounts and adding your Apple ID with the plus sign in the bottom left corner

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Xcode%20Accounts.png"/>

Sign up for an Apple developer account with your Apple ID if you don't have one already [here](https://developer.apple.com/account/#!/welcome).

** NOTE: Using a free developer account to build and deploy this app to a device will cause the app to stop working after 7 days. To have the app remain working indefinitely, you will need to join the paid apple development program. More information [here](https://developer.apple.com/programs/enroll/). **

Under HealthPlatformWatchOS -> Signing, change the team to your Apple account. It should say Your Name (Personal Team - youremail@email.com). Also change the bundle identifier to a different string, anything works as long as XCode doesn't show any errors. Do this for each of the 3 targets in the Targets sidebar.

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Signing.png"/>

Next, at the top left corner of XCode, click the search icon and type AppBundle in the search bar, 2 results should show up.

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Bundle%20Identifier%20Search.png" width="400"/>

Change each of the 2 results to your respective new bundle indetifiers. WatchKit Companian App Bundle Indentifier should match the bundle identifier for HealthPlatformWatchOS, and WKAppBundleIdentifier should match the bundle identifier for HealthPlatformWatchOS WatchKit App.

<p float="left">
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Bundle%20Update%201.png"/>
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Bundle%20Update%202.png"/>
</p>

### Deploying to your device

Plug in your iPhone to your Mac and make sure your Apple Watch is connected to the iPhone.

At the top of the screen select your iPhone from the list and then click the play button to run the app. Do the same for your Apple watch. Select HealthPlatformWatchOS for the iPhone app and HealthPlatformWatchOS WatchKit App for the Apple Watch app.

The Apple Watch app may take a couple minutes to attach to your watch.

<p float="left">
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Run%20App%201.png"/>
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Run%20App%202.png"/>
</p>

The very first time you build and run the app on your device, the build will fail. To fix this, go to the settings app -> General -> VPN & Device Management -> Apple Development: YourAppleID@email.com and trust the developer. 

### Finding your AWS Constants

To connect and send your data to AWS, you'll have to find 2 constants through the AWS console. Ensure that you are using the AWS console in the US-WEST-2 region.

IOT ENDPOINT: IoT Core -> Settings -> Device Data Enpoint

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/IoT%20Endpoint.png"/>

COGNITO POOL: Cognito -> Manage Identity Pools -> HealthPlatformIdentityPool -> Edit Identity Pool -> Identity pool ID

<p float="left">
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Cognito%201.png"/>
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Cognito%202.png"/>
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Cognito%203.png"/>
</p>

### Setting up the iOS app

When the app is launched for the first time, you will be prompted to allow the app to read and write your HealthKit data. Accept all permissions in order for the app to work.

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/Iphone%20Permissions.png" width="200"/>

After accepting the permissions, quit the app and go to the settings app. Navigate to HealthPlatformWatchOS and fill in the IoT Endpoint and Cognito Pool ID. Also ensure that the Background App Refresh setting is enabled.

<p float="left">
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/App%20Settings%201.png" width="200"/>
<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/App%20Settings%202.png" width="200"/>
</p>

After you have set the AWS Constants, relaunch the app and the IoT status should say Connected. If this is not the case, check that you are connected to WiFi, and also that you entered your IoT Endpoint and Cognito Pool ID correctly.

At this time, also register the user and device ID in the frontend.

### iOS app overview

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/iOS%20App.png" width="200"/>

- IoT Status: Shows if you are connected to AWS IoT. If you background the app it will disconnect and when you tab back into the app, it will say Connection Error. Give it some time, and the app will reconnect itself.

- Device ID: A unique ID given to your iPhone. Use this to register your device in the frontend.

- Last Send Time: This shows the last time you sent data to AWS.

- HR Sent: How many heart rate data points you just sent to AWS.

- HRV Sent: How many heart rate variability data points you just sent to AWS.

- BGTasks: How many background tasks are currently scheduled. When you open then app, it will say 0 remaning, but after a couple seconds the background task should get scheduled and display 1 remaining. If it continues to display 0 remaining, restart the app.

- Earliest BGTask Time: Earliest time that an automatic data sent can occur. If your background task did not register and shows 0 remaining, this will show a time in the past.

- Error: Will display any error codes. -1 indicates a connection timeout, ensure you have a stable internet connection. -2 indicates the background task expiration task reached the expiration handler, ensure that low power mode is disabled. -3 indicates that the background task cannot be scheduled, check that the Background App Refresh setting is enabled. 0 indicates there are no errors.

- Send Data: Sends all datapoints from your last send time to now to AWS. Ensure the IoT Status says connected before sending the data.

You can also leave your app in the background where it will periodically send data automatically. However, this is unpredictable as Apple has an algorithm which determines when this will happen which may take a long time before triggering. Therefore, it is best to trigger data sends with the button in the app if you can. The automatic data send will not work if you force quit/terminate your app.

Any data that is sent will appear in the Health Platform dashboard. If you find that you missing data, try leaving the app open for a couple minutes and the app should sync and send any missing data to the frontend.

### WatchOS App Setup


**NOTE: This app is completely optional. Continuously running a workout will deplete your watch battery very quickly. It is recommended to just wear your watch normally on your wrist without running any application. Your vitals will still continue to be monitored this way, although at a less frequent rate. If you would like to run a workout, the built in workout app on the Apple Watch works exactly the same way as this app.**

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

### Viewing your HealthKit Data

To view your HealthKit data which is coming from the watch, open the Health app on your iPhone, tap browse in the bottom right corner, and then tap Heart from the list of Health Categories.

<img src="https://github.com/UBC-CIC/health-platform-iOS-watchOS/blob/master/README%20Images/HealthKit.png" width="200"/>
