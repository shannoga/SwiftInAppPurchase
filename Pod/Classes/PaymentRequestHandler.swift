//
//  PaymentRequestHandler.swift
//  IAPMaster
//
//  Created by Suraphan on 11/30/2558 BE.
//  Copyright © 2558 irawd. All rights reserved.
//


import StoreKit

public enum TransactionResult {
    case purchased(productId: String,transaction:SKPaymentTransaction,paymentQueue:SKPaymentQueue)
    case restored(productId: String,transaction:SKPaymentTransaction,paymentQueue:SKPaymentQueue)
    case nothingToDo
    case failed(error: NSError)
}
public typealias AddPaymentCallback = (_ result: TransactionResult) -> ()

open class PaymentRequestHandler: NSObject,SKPaymentTransactionObserver {

    
    fileprivate var addPaymentCallback: AddPaymentCallback?
    fileprivate var incompleteTransaction : [SKPaymentTransaction] = []
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    func addPayment(_ product: SKProduct,userIdentifier:String?, addPaymentCallback: @escaping AddPaymentCallback){
        
        self.addPaymentCallback = addPaymentCallback
        
        let payment = SKMutablePayment(product: product)
        if userIdentifier != nil {
            payment.applicationUsername = userIdentifier!
        }
        SKPaymentQueue.default().add(payment)
    }

    func restoreTransaction(_ userIdentifier:String?,addPaymentCallback: @escaping AddPaymentCallback){
        
        self.addPaymentCallback = addPaymentCallback
        if userIdentifier != nil {
           SKPaymentQueue.default().restoreCompletedTransactions(withApplicationUsername: userIdentifier)
        }else{
            SKPaymentQueue.default().restoreCompletedTransactions()
        }
        
    }
    open func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]){
    
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                if (addPaymentCallback != nil){
                    addPaymentCallback!(.purchased(productId: transaction.payment.productIdentifier, transaction: transaction, paymentQueue: queue))
                }else{
                    incompleteTransaction.append(transaction)
                }
                
            case .failed:
                if (addPaymentCallback != nil){
                    addPaymentCallback!(.failed(error: transaction.error! as NSError))
                }
                queue.finishTransaction(transaction)
               
            case .restored:
                if (addPaymentCallback != nil){
                    addPaymentCallback!(.restored(productId: transaction.payment.productIdentifier, transaction: transaction, paymentQueue: queue))
                }else{
                    incompleteTransaction.append(transaction)
                }

            case .purchasing:
                // In progress: do nothing
                break
            case .deferred:
                break
            }

        }
    }
    
    
    func checkIncompleteTransaction(_ addPaymentCallback: @escaping AddPaymentCallback){
     
        self.addPaymentCallback = addPaymentCallback
        let queue = SKPaymentQueue.default()
        for transaction in self.incompleteTransaction {
            
            switch transaction.transactionState {
            case .purchased:
                addPaymentCallback(.purchased(productId: transaction.payment.productIdentifier, transaction: transaction, paymentQueue: queue))
                
            case .restored:
                addPaymentCallback(.restored(productId: transaction.payment.productIdentifier, transaction: transaction, paymentQueue: queue))
                
            default:
                break
            }
        }
        self.incompleteTransaction.removeAll()
    }
}
