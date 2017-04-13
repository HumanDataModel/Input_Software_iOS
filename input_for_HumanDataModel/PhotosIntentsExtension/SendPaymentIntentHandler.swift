import Intents

class SendPaymentIntentHandler: NSObject, INSendPaymentIntentHandling {
    // MARK: - INSendPaymentIntentHandling
    
    func handle(sendPayment intent: INSendPaymentIntent, completion: @escaping (INSendPaymentIntentResponse) -> Swift.Void) {
        
        print("kissa 1")
        
        if let _ = intent.payee, let _ = intent.currencyAmount {
            // Handle the payment here!
            
            completion(INSendPaymentIntentResponse.init(code: .success, userActivity: nil))
        }
        else {
            completion(INSendPaymentIntentResponse.init(code: .success, userActivity: nil))
        }
    }
}
