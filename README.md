[![GitHub license](https://img.shields.io/github/license/Geotab/mobile-sdk-ios)](https://github.com/Geotab/mobile-sdk-ios/blob/main/LICENSE) [![GitHub docs](https://img.shields.io/badge/docs-passing-brightgreen)](https://geotab.github.io/mobile-sdk-ios/Classes/DriveViewController.html) [![GitHub swift](https://img.shields.io/badge/swift-4%20%7C%204.2%20%7C%205-brightgreen)](https://swift.org/) [![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/Geotab/mobile-sdk-ios?label=release)](https://github.com/Geotab/mobile-sdk-ios/tags)

# Mobile SDK iOS

## How to start 

### Installation

The Geotab Mobile SDK is a Swift Package. Refer to Apple's documentation for how to add the SDK to your project: https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app

Using the Mobile SDK with SwiftUI is not recommended. 


**Add background mode capabilities**

In your app's "Signing and Capabilities" section, add "Background mode" section and check the "Audio, Airplay and Picture in Picture" and "Location updates" options. 


**Info.plist**

The following keys must be added to your app's Info.plist:

- "Privacy - Location Always Usage Description"
- "Privacy - Location Always and When In Use Usage Description"
- "Privacy - Location When In Use Usage Description"
- "Privacy - Camera Usage Description"
- "Privacy - Photo Library Usage Description"
- "Privacy - Face ID Usage Description"
- "Privacy - Bluetooth Always Usage Description"
- "Privacy - Bluetooth Peripheral Usage Description"
- "Privacy - Motion Usage Description"

### What is DriveViewController?

DriveViewController is the starting point to integrate the Geotab Mobile SDK. It's the container for the Geotab Drive web app equipped with native APIs for accessing the contained app's data.

### Initialization

Inside your `main` controller, define a property that holds a singleton instance of `DriveViewController`.

```swift
private var driveVC: DriveViewController!
```

If your drivers should login from a specific Geotab server, then you should set `serverAddress` first:

```swift
DriveSdkConfig.serverAddress = "<server-name>.geotab.com"
```

Do not prefix the address with "https://".


You should also set up a listener for `LastServerAddress` updates:

```swift
driveVC.setLastServerAddressUpdatedCallback { server in
    let store = UserDefaults.standard
    store.setValue(server, forKey: MainViewController.GEOTAB_DRIVE_LAST_SERVER_KEY)
    DriveSdkConfig.serverAddress = server
}
```

Save the last the value of `LastServerAddress` in persistent storage. To allow for offline caching, on app launch read the value from persistent storage and set it to `DriveSdkConfig.serverAddress` before executing any Drive SDK APIs.

Initialize the instance during `viewDidLoad()` of your `main` controller

```swift
driveVC = DriveViewController(modules: [])
```

### Login

The Geotab Mobile SDK allows integrators use their own authentication and user management. All the SDK needs to know to log into Geotab Drive is a user's credential. 

Supply credentials to `DriveViewController` as follows:

```swift
driveVC.setSession(credentialResult: CredentialResult, isCoDriver: <set to true if it's a co-driver login>)
```

where credentials is an instance of: 

```swift
public struct GeotabCredentials: Codable {
    
    var userName: String
    var database: String
    var sessionID: String
    
    public init(userName: String, database: String, sessionID: String){
        self.userName = userName
        self.database = database
        self.sessionID = sessionID
    }
}
```

See `GeotabCredentials.swift`.

### Present the `DriveViewController`

Once user credentials are supplied, present the view controller to the user. `DriveViewController` will automatically validate the session and continue through the normal Geotab Drive workflow.

```swift
self.present(driveVC, animated: true)
```

### Session expired/invalid/no-session and co-Driver Login

To be notified when a user session has expired, set a listener:

```swift
driveVC.setLoginRequiredCallback { (status, errorMessage) in
    ... ...
}
```

Set a listener for session changes, including: no session, invalid session, session expired, or co-driver login is requested.

- Parameters:
   - callback: `LoginRequiredCallbackType`
           - status: `""` `"LoginRequired"`, `"AddCoDriver"`.
           - errorMessage: An error occurred during login. Error info is contained in `errorMessage`.

There are three predefined speical values for error messages that may be passed to the callback.

- `""`: an empty string indicates no login is required, login is successful, or the login is in progress. At this state, an implementor should present `DriveViewController`.
- `"LoginRequired"`: indicates the login UI is going to show a login form (No valid user is available or the current activeSession is expired/invalid). At this state an implementor should present a custom login screen.
- `"AddCoDriver"`: indicates that a co-driver login is requested. At this state and implementor should present a custom co-driver login screen.

For any other error message an implementor should present a custom login screen.

After receiving a session expired callback. An integrator should dismiss the presented `DriveViewController` and present user with a login screen.

### Other important callbacks

There are few other callbacks useful for managing `DriveViewController`.

- `DriveViewController::setDriverActionNecessaryCallback`: `driverActionNecessary` is a collection of events that may occur where the application should bring the Drive view contoller to the foreground. For example: "Your vehicle has been selected by another driver. You now need to select a vehicle".

- `DriveViewController::setPageNavigationCallback`: `pageNavigation` indicates any navigation changes made by the driver in Geotab Drive.

See more details in the [API document](https://geotab.github.io/mobile-sdk-ios/Classes/DriveViewController.html).


### Overwrite Default Background Color, Font Color, and Icon

To override default background color in the network error page, create a property in `Info.plist` named `"NetworkErrorScreenBckColor"` of type `String`. Add a hex value for the color.
To override default font color in the network error page, create a property in `Info.plist` named `"NetworkErrorScreenFontColor"` of type `String`. Add a hex value for the color
To override default icon in the network error page, create a property in `Info.plist` named `"NetworkErrorScreenIcon"` of type String and add the name of the image. The image must also be added to the project.


## Drive APIs

All drive APIs are accessible directly under an instance of `DriveViewController` or `MyGeotabbViewController`. See more details in the [API document](https://geotab.github.io/mobile-sdk-ios/).

## App-Bound Domains

Incorporating App-Bound Domains into your application using the Geotab Drive SDK is recommended. For guidance, refer to [Apple’s documentation](https://webkit.org/blog/10882/app-bound-domains/) on enabling App-Bound Domains, and ensure you include `geotab.com` in your set of approved domains.

If you decide not to use App-Bound Domains, you'll need to set up the Mobile SDK to operate accordingly. When creating a `DriveViewController` instance, adjust the options to disable App-Bound Domains:

```swift
let options = MobileSdkOptions(useAppBoundDomains: false)
let driveViewController = DriveViewController(options: options)
```

## License

GeotabDriveSDK is available under the MIT license. See the LICENSE file for more info.
