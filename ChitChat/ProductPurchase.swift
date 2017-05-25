//
//  ProductPurchase.swift
//  ChitChat
//
//  Created by next-shot on 5/23/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import StoreKit

class Product {
    let product : SKProduct
     var title : String {
        return product.localizedTitle
    }
    var description : String {
        return product.localizedDescription
    }
    var price : NSDecimalNumber {
        return product.price
    }
    var productIdentifier : String {
        return product.productIdentifier
    }
    var purchased = false
    var expired = false
    init(product: SKProduct) {
        self.product = product
    }
}

class Products {
    enum Id : String { case X2 = "com.next_shot_inc.ChitChat.2X" }
    
    class func checkForPurchase(productId: Id) -> Bool {
        if( settingsDB.settings.purchased_something == false ) {
            return false
        }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return false
        }
        
        let iap = appDelegate.IAPHelper!
        if( !iap.receiptVerified ) {
            iap.verifyReceipt()
        }
        for p in iap.products {
            if( p.productIdentifier == productId.rawValue ) {
                return p.purchased
            }
        }
        return false
    }

    class func ids() -> [String] {
        return [Products.Id.X2.rawValue]
    }
}

class InApppurchaseView {
    func did_purchase() {
        // default does nothing
    }
}

class InAppPurchaseHelper : NSObject, SKPaymentTransactionObserver, SKProductsRequestDelegate, SKRequestDelegate {
    var productIdentifiers = Set<String>()
    var products = [Product]()
    var views = [InApppurchaseView]()
    var request : SKProductsRequest?
    var receiptVerified = false
    
    override init() {
        super.init()
        for id in Products.ids() {
            productIdentifiers.insert(id)
        }
        SKPaymentQueue.default().add(self)
    }
    
    // Payment queue handling
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for t in transactions {
            switch t.transactionState {
            case .purchased:
                for v in views {
                    v.did_purchase()
                }
                SKPaymentQueue.default().finishTransaction(t)
                break
            case .failed:
                SKPaymentQueue.default().finishTransaction(t)
            case .restored:
                for v in views {
                    v.did_purchase()
                }
                SKPaymentQueue.default().finishTransaction(t)
                break
            case .deferred:
                // Waiting for parents approval
                // Nothing to do
                break
            case .purchasing:
                break
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        // Handle error
    }
    
    // Request Products handling
    func requestProducts() {
        request?.cancel()
        
        request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request!.delegate = self
        request!.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        for p in response.products {
            products.append(Product(product: p))
        }
        self.request = nil
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
         print(error.localizedDescription)
    }
    
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func buy(productIdentifier: String) {
        for p in products {
            if( p.productIdentifier == p.productIdentifier ) {
                 let payement = SKPayment(product: p.product)
                 SKPaymentQueue.default().add(payement)
            }
        }
    }
    
    // Manage purchase observers
    func addView(view: InApppurchaseView) {
        views.append(view)
    }
    func removeView(view: InApppurchaseView) {
        let index = views.index { (v) -> Bool in
            v === view
        }
        if( index != nil ) {
            views.remove(at: index!)
        }
    }
    
    // SKReceipt handling
    
    func requestDidFinish(_ request: SKRequest) {
        //
    }
    
    func verifyReceipt() {
        let pv = ProductVerification()
        do {
            try pv.verification()
        } catch ReceiptError.invalidReceipt {
            let req = SKReceiptRefreshRequest()
            req.delegate = self
            req.start()
            return
        } catch ReceiptError.unexpected {
            return
        } catch {
            return
        }
        
        if( pv.hashData == nil || pv.hashData! != pv.computedHashData() ) {
            return
        }
        
        for pr in pv.receipts {
            if( pr.productIdentifier != nil ) {
                let pdi = self.products.index(where: { (p) -> Bool in
                    p.productIdentifier == pr.productIdentifier!
                })
                var product : Product?
                if( pdi != nil ) {
                    product = products[pdi!]
                }
                if( pr.subscriptionExpirationDate != nil ) {
                    if( pr.subscriptionExpirationDate! < Date() ) {
                    
                    }
                } else if( pr.originalPurchaseDate != nil ) {
                    // Valid for 4 hours
                    let validFor = 4*60*60
                    if( Date(timeInterval: TimeInterval(validFor), since: pr.originalPurchaseDate!) >= Date() ) {
                        product?.purchased = true
                    } else {
                        product?.expired = true
                    }
                } else {
                    product?.purchased = true
                }
            }
        }
        
        receiptVerified = true
    }
}
