
import Foundation

struct AWSConstants {
    //User defined constants, ensure that you are using the AWS console in us-west-2
    //Input the cognito pool id and IoT endpoint by opening the settings app and navigating to this app
    
    //Cognito -> Manage Identity Pools -> HealthPlatformIdentityPool -> Edit Identity Pool -> Identity pool ID
    static let COGNITO_POOL_ID = (UserDefaults.standard.string(forKey: "cognito_id") ?? "") as String
    
    //IoT Core -> Settings -> Device data endpoint
    static let IOT_ENDPOINT = (UserDefaults.standard.string(forKey: "iot_endpoint") ?? "") as String
    
    //Default topic name for this application, do not change this unless you have changed the topic name in HealthPlatformIoTStack
    static let IOT_TOPIC = "iot_device_analytics"
}
