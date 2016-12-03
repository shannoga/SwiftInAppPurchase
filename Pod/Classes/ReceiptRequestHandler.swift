//
//  ReceiptRequestHandler.swift
//  IAPMaster
//
//  Created by Suraphan on 12/2/2558 BE.
//  Copyright © 2558 irawd. All rights reserved.
//
import StoreKit

public typealias RequestReceiptCallback = (_ error:Error?) -> ()
public typealias ReceiptVerifyCallback = (_ receipt:NSDictionary?,_ error:Error?) -> ()

let productionVerifyURL = "http://buy.itunes.apple.com/verifyReceipt"
let sandboxVerifyURL = "https://sandbox.itunes.apple.com/verifyReceipt"

open class ReceiptRequestHandler: NSObject ,SKRequestDelegate{

    fileprivate var requestCallback: RequestReceiptCallback?
    fileprivate var receiptVerifyCallback: ReceiptVerifyCallback?
    var isProduction:Bool
    
    override init() {
        isProduction = false
        super.init()
        
    }
    deinit {
        
    }
    func receiptURL() -> URL {
        return Bundle.main.appStoreReceiptURL!
    }
    
    func refreshReceipt(_ requestCallback: @escaping RequestReceiptCallback){
        self.requestCallback = requestCallback
        let receiptRequest = SKReceiptRefreshRequest.init(receiptProperties: nil)
        receiptRequest.delegate = self
        receiptRequest.start()
    }

    open func requestDidFinish(_ request: SKRequest) {
       requestCallback!(nil)
    }
    open func request(_ request: SKRequest, didFailWithError error: Error) {
        requestCallback!(error as NSError?)
    }

    func verifyReceipt(_ autoRenewableSubscriptionsPassword:String?,receiptVerifyCallback:@escaping ReceiptVerifyCallback){
        self.receiptVerifyCallback = receiptVerifyCallback
        
        let session = URLSession.shared
        let receipt = try? Data.init(contentsOf: self.receiptURL())

        let requestContents :NSMutableDictionary = [ "receipt-data" : (receipt?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)))!]
        
        if (autoRenewableSubscriptionsPassword != nil) {
            requestContents.setValue(autoRenewableSubscriptionsPassword, forKey: "password")
        }
        
        let storeURL = URL.init(string: isProduction ? productionVerifyURL:sandboxVerifyURL)
        
        var storeRequest = URLRequest.init(url: storeURL!)
        
        do {
            storeRequest.httpBody = try JSONSerialization.data(withJSONObject: requestContents, options: [])
        } catch {
            
            print(error)
            receiptVerifyCallback(nil, NSError.init(domain: "JsonError", code: 0, userInfo: nil))
            return
        }
        
        storeRequest.httpMethod = "POST"
        let task = session.dataTask(with: storeRequest, completionHandler: {data, response, error -> Void in
            
            guard error == nil else { return }
            let json: NSDictionary?
            do {
                json = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
            } catch let dataError {
                print(dataError)
                receiptVerifyCallback(nil, NSError.init(domain: "JsonError", code: 0, userInfo: nil))
                return
            }
            
            if let parseJSON = json {
                let success = parseJSON["success"] as? Int
                print("Succes: \(success)")
                receiptVerifyCallback(parseJSON, nil)
            
            }
            else {
                let jsonStr = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print("Error could not parse JSON: \(jsonStr)")
                
                receiptVerifyCallback(nil, error)
            }
            
        })
        
        task.resume()
    }
}
