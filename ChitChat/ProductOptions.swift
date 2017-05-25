//
//  ProductOptions.swift
//  ChitChat
//
//  Created by next-shot on 5/10/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit

// Receipt validation

public enum ReceiptError : Error {
    case unexpected, invalidReceipt
}

class ProductVerification {
    var bundleIdData : NSData?
    var bundleIdString: String?
    var bundleVersionString : String?
    var opaqueData : NSData?
    var hashData: NSData?
    var receipts = [ProductReceipt]()
    var expirationDate : Date?
    
    init() {
        
    }
    
    func verification() throws {
        
        // First, we need to verify that the receipt is signed by Apple.
        
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            throw ReceiptError.invalidReceipt
        }
        guard let certificateURL = Bundle.main.url(forResource: "AppleIncRootCertificate", withExtension: "cer") else {
            throw ReceiptError.invalidReceipt
        }
        guard let receiptData = NSData(contentsOf: receiptURL) else {
            throw ReceiptError.invalidReceipt
        }
        guard let certificateData = NSData(contentsOf: certificateURL) else {
            throw ReceiptError.invalidReceipt
        }
        let bio = BIOWrapper(data: receiptData)
        let p7 : UnsafeMutablePointer<PKCS7> = d2i_PKCS7_bio(bio.bio, nil)
        
        OpenSSL_add_all_digests()
        
        // First verify that the receipt is signed by Apple
        let x509Store = X509StoreWrapper()
        let certificate = X509Wrapper(data: certificateData)
        x509Store.addCert(x509: certificate)
        let payload = BIOWrapper()
        guard PKCS7_verify(p7, nil, x509Store.store, nil, payload.bio, 0) == 1 else {
            throw ReceiptError.invalidReceipt
        }
        
        // Now we begin to parse the receipt and get following information from the receipt:
        // bundle Identifier
        // bundle Version
        // hash data
        // in-app-purchase receipts, if you have
        if let contents = p7.pointee.d.sign.pointee.contents,
            OBJ_obj2nid(contents.pointee.type) == NID_pkcs7_data ,
            let octets = contents.pointee.d.data
        {
            var ptr : UnsafePointer? = UnsafePointer(octets.pointee.data)
            let end = ptr!.advanced(by: Int(octets.pointee.length))
            var type : Int32 = 0
            var xclass: Int32 = 0
            var length = 0
            ASN1_get_object(&ptr, &length, &type, &xclass,Int(octets.pointee.length))
            guard type == V_ASN1_SET else {
                return
            }
            while ptr! < end {
                ASN1_get_object(&ptr, &length, &type, &xclass, ptr!.distance(to: end))
                guard type == V_ASN1_SEQUENCE else {
                    return
                }
                
                guard let attrType = ASN1ReadInteger(pointer: &ptr, length: ptr!.distance(to: end)) else {
                    return
                }
                
                guard let _ = ASN1ReadInteger(pointer: &ptr, length: ptr!.distance(to: end)) else {
                    return
                }
                
                ASN1_get_object(&ptr, &length, &type, &xclass, ptr!.distance(to: end))
                guard type == V_ASN1_OCTET_STRING else {
                    return
                }
                
                switch attrType {
                case 2:
                    var strPtr = ptr
                    self.bundleIdData = NSData(bytes: strPtr, length: length)
                    self.bundleIdString = ASN1ReadString(pointer: &strPtr, length: length)
                case 3:
                    var strPtr = ptr
                    self.bundleVersionString = ASN1ReadString(pointer: &strPtr, length: length)
                case 4:
                    self.opaqueData = NSData(bytes: ptr!, length: length)
                case 5:
                    self.hashData = NSData(bytes: ptr!, length: length)
                case 17:
                    let p = ptr
                    let iapReceipt = ProductReceipt(with: p!, len: length)
                    self.receipts.append(iapReceipt)
                case 21:
                    var strPtr = ptr
                    self.expirationDate = ASN1ReadDate(pointer: &strPtr, length: length)
                default:
                    break
                }
                ptr = ptr?.advanced(by: length)
            }
        }
    }
    
    func computedHashData() -> NSData {
        let device = UIDevice.current
        var uuid = device.identifierForVendor?.uuid
        let address = withUnsafePointer(to: &uuid) {UnsafeRawPointer($0)}
        let data = NSData(bytes: address, length: 16)
        var hash = Array<UInt8>(repeating: 0, count: 20)
        var ctx = SHA_CTX()
        SHA1_Init(&ctx)
        SHA1_Update(&ctx, data.bytes, data.length)
        SHA1_Update(&ctx, opaqueData!.bytes, opaqueData!.length)
        SHA1_Update(&ctx, bundleIdData!.bytes, bundleIdData!.length)
        SHA1_Final(&hash, &ctx)
        return NSData(bytes: &hash, length: 20)
    }
    
}

class ProductReceipt {
    var quantity : Int?
    var productIdentifier: String?
    var transactionIdentifier: String?
    var originalTransactionIdentifier : String?
    var purchaseDate: Date?
    var originalPurchaseDate: Date?
    var subscriptionExpirationDate : Date?
    var cancellationDate : Date?
    var webOrderLineItemID : Int?
    
    init(with: UnsafePointer<UInt8>, len: Int) {
        read(asn1Data: with, len: len)
    }
    
    func read(asn1Data: UnsafePointer<UInt8>, len: Int) {
        var ptr : UnsafePointer<UInt8>? = asn1Data
        let end = asn1Data.advanced(by: len)
        var type : Int32 = 0
        var xclass: Int32 = 0
        var length = 0
        ASN1_get_object(&ptr, &length, &type, &xclass,Int(len))
        guard type == V_ASN1_SET else {
            return
        }
        while ptr! < end {
            ASN1_get_object(&ptr, &length, &type, &xclass, ptr!.distance(to: end))
            guard type == V_ASN1_SEQUENCE else {
                return
            }
            
            guard let attrType = ASN1ReadInteger(pointer: &ptr, length: ptr!.distance(to: end)) else {
                return
            }
            
            guard let _ = ASN1ReadInteger(pointer: &ptr, length: ptr!.distance(to: end)) else {
                return
            }
            
            ASN1_get_object(&ptr, &length, &type, &xclass, ptr!.distance(to: end))
            guard type == V_ASN1_OCTET_STRING else {
                return
            }
            
            switch attrType {
            case 1701:
                var p = ptr
                self.quantity = ASN1ReadInteger(pointer: &p , length: length)
            case 1702:
                var p = ptr
                self.productIdentifier = ASN1ReadString(pointer: &p, length: length)
            case 1703:
                var p = ptr
                self.transactionIdentifier = ASN1ReadString(pointer: &p, length: length)
            case 1705:
                var p = ptr
                self.originalTransactionIdentifier = ASN1ReadString(pointer: &p, length: length)
            case 1704:
                var p = ptr
                self.purchaseDate = ASN1ReadDate(pointer: &p, length: length)
            case 1706:
                var p = ptr
                self.originalPurchaseDate = ASN1ReadDate(pointer: &p, length: length)
            case 1708:
                var p = ptr
                self.subscriptionExpirationDate = ASN1ReadDate(pointer: &p, length: length)
            case 1712:
                var p = ptr
                self.cancellationDate = ASN1ReadDate(pointer: &p, length: length)
            case 1711:
                var p = ptr
                self.webOrderLineItemID = ASN1ReadInteger(pointer: &p, length: length)
            default:
                break
            }
            ptr = ptr?.advanced(by: length)
        }
    }
}
