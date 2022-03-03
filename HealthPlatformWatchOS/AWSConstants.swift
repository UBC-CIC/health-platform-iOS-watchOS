
import Foundation

struct AWSConstants {
    //User defined constants, ensure that you are using the AWS console in us-west-2
    
    //Cognito -> Manage Identity Pools -> HealthPlatformIdentityPool -> Edit Identity Pool -> Identity pool ID
    static let COGNITO_POOL_ID = "Your_Cognito_Pool_ID_Here"
    
    //IoT Core -> Settings -> Device data endpoint
    static let IOT_ENDPOINT = "Your_IoT_Endpoint_Here"
    
    //Default topic name for this application, do not change this unless you have changed the topic name in HealthPlatformIoTStack
    static let IOT_TOPIC = "iot_device_analytics"
}
