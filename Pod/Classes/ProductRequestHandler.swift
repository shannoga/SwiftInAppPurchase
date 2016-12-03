//
//  ProductRequestHandler.swift
//  IAPMaster
//
//  Created by Suraphan on 11/30/2558 BE.
//  Copyright © 2558 irawd. All rights reserved.
//
import StoreKit

public typealias RequestProductCallback = (_ products: [SKProduct]?,_ invalidIdentifiers:[String]?,_ error:NSError?) -> ()

open class ProductRequestHandler: NSObject,SKProductsRequestDelegate {
    
    fileprivate var requestCallback: RequestProductCallback?
    var products: [String: SKProduct] = [:]
    
    override init() {
        super.init()
    }
    deinit {
        
    }
    func addProduct(_ product: SKProduct) {
        products[product.productIdentifier] = product
    }

    func requestProduc(_ productIds: Set<String>, requestCallback: @escaping RequestProductCallback){
        self.requestCallback = requestCallback
        let productRequest = SKProductsRequest(productIdentifiers: productIds)
        productRequest.delegate = self
        productRequest.start()
    }
    // MARK: SKProductsRequestDelegate
    open func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        for product in response.products{
            addProduct(product)
        }
        requestCallback!(response.products, response.invalidProductIdentifiers, nil)
    }

    open func requestDidFinish(_ request: SKRequest) {
        print(request)
    }
    open func request(_ request: SKRequest, didFailWithError error: Error) {
        requestCallback!(nil, nil, error as NSError?)
    }
    
}
