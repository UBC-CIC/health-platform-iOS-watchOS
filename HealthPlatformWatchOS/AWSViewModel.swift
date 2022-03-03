
import Foundation
import AWSIoT

class AWSViewModel {
    let cognitoCredentials: AWSCognitoCredentialsProvider
    let cognitoConfiguration: AWSServiceConfiguration
    let iotEndpoint: AWSEndpoint
    let iotConfiguration: AWSServiceConfiguration
    var clientId: String
    
    //setup your cognito credentials and iot endpoint
    init() {
        cognitoCredentials = AWSCognitoCredentialsProvider(regionType:.USWest2, identityPoolId: AWSConstants.COGNITO_POOL_ID)
        cognitoConfiguration = AWSServiceConfiguration(region:.USWest2, credentialsProvider: cognitoCredentials)
        AWSIoT.register(with: cognitoConfiguration, forKey: "kAWSIoT")
        iotEndpoint = AWSEndpoint(urlString: "wss://\(AWSConstants.IOT_ENDPOINT)/mqtt")
        iotConfiguration = AWSServiceConfiguration(region: .USWest2, endpoint: iotEndpoint, credentialsProvider: cognitoCredentials)
        AWSIoTDataManager.register(with: iotConfiguration, forKey: "kDataManager")
        clientId = ""
        self.getAWSClientID()
    }
    
    
    func getAWSClientID() {
            cognitoCredentials.getIdentityId().continueWith(block: { (task:AWSTask<NSString>) -> Any? in
                if let error = task.error as NSError? {
                    print("Failed to get client ID => \(error)")
                    return nil  // Required by AWSTask closure
                }
                
                self.clientId = task.result! as String
                print("Got client ID => \(self.clientId)")
                self.connectToAWSIoT()
                return nil 
            })
        }
    
    func connectToAWSIoT() {
            func mqttEventCallback(_ status: AWSIoTMQTTStatus ) {
                switch status {
                case .connecting: print("Connecting to AWS IoT")
                case .connected:
                    print("Connected to AWS IoT")
                    // Register subscriptions here
                    // Publish a boot message if required
                case .connectionError: print("AWS IoT connection error")
                case .connectionRefused: print("AWS IoT connection refused")
                case .protocolError: print("AWS IoT protocol error")
                case .disconnected: print("AWS IoT disconnected")
                case .unknown: print("AWS IoT unknown state")
                default: print("Error - unknown MQTT state")
                }
            }
            
            // Ensure connection gets performed background thread (so as not to block the UI)
            DispatchQueue.global(qos: .background).async {
                do {
                    print("Attempting to connect to IoT device gateway with ID = \(self.clientId)")
                    let dataManager = AWSIoTDataManager(forKey: "kDataManager")
                    dataManager.connectUsingWebSocket(withClientId: self.clientId,
                                                      cleanSession: true,
                                                      statusCallback: mqttEventCallback)
                } catch {
                    print("Error, failed to connect to device gateway => \(error)")
                }
            }
        }
    
    func publishMessage(message: String!) {
      let dataManager = AWSIoTDataManager(forKey: "kDataManager")
        dataManager.publishString(message, onTopic: AWSConstants.IOT_TOPIC, qoS: .messageDeliveryAttemptedAtLeastOnce)
    }
}
