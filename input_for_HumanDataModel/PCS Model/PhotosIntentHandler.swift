//
//  PhotosIntentHandler.swift
//  PCS Model
//
//  Created by Niko Mäkitalo on 10.2.2017.
//  Copyright © 2017 Niko Mäkitalo. All rights reserved.
//

import Foundation

import Intents

class PhotosIntentHandler: NSObject, INSendPaymentIntentHandling {
    // MARK: - INSendPaymentIntentHandling
    
    func handle(sendPayment intent: INSendPaymentIntent, completion: @escaping (INSendPaymentIntentResponse) -> Swift.Void) {
        if let _ = intent.payee, let _ = intent.currencyAmount {
            // Handle the payment here!
            
            completion(INSendPaymentIntentResponse.init(code: .success, userActivity: nil))
        }
        else {
            completion(INSendPaymentIntentResponse.init(code: .success, userActivity: nil))
        }
    }
}
