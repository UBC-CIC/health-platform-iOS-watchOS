
import Foundation
import AWSIoT

class AWSViewModel {
    var connectionStatus = "Not Connected"
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
                case .connecting: connectionStatus = "Connecting"
                case .connected: connectionStatus = "Connected"
                    print("Connected")
                case .connectionError: connectionStatus = "Connection Error"
                    print("error")
//                    let seconds = 5.0
//                    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
//                        self.connectToAWSIoT()
//                    }
                case .connectionRefused: connectionStatus = "Connection Refused"
                    print("refused")
                    connectToAWSIoT()
                case .protocolError: connectionStatus = "Protocol Error"
                    print("protocol")
                    connectToAWSIoT()
                case .disconnected: connectionStatus = "Disconnected"
                    print("disconnected")
                    connectToAWSIoT()
                case .unknown: connectionStatus = "Unknown"
                default: connectionStatus = "Not Connected"
                    
                }
            }
            
            // Ensure connection gets performed background thread (so as not to block the UI)
            DispatchQueue.global(qos: .background).async {
                do {
                    print("Attempting to connect to IoT device gateway with ID = \(self.clientId)")
                    let dataManager = AWSIoTDataManager(forKey: "kDataManager")
                    dataManager.connectUsingWebSocket(withClientId: self.clientId,
                                                      cleanSession: false,
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
