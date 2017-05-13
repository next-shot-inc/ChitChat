//
//  OpenSSLWrappers.swift
//  ChitChat
//
//  Created by next-shot on 5/10/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation


class BIOWrapper {
    let bio = BIO_new(BIO_s_mem())
    init(data:NSData) {
        BIO_write(bio, data.bytes, Int32(data.length))
    }
    
    init() {}
    
    deinit {
        BIO_free(bio)
    }
}

class X509StoreWrapper {
    let store = X509_STORE_new()
    deinit {
        X509_STORE_free(store)
    }
    
    func addCert(x509:X509Wrapper) {
        X509_STORE_add_cert(store, x509.x509)
    }
}

class X509Wrapper {
    let x509 : UnsafeMutablePointer<X509>!
    init(data:NSData){
        let certBIO = BIOWrapper(data: data)
        x509 = d2i_X509_bio(certBIO.bio, nil)
    }
    
    deinit {
        X509_free(x509)
    }
}

func ASN1ReadInteger(pointer ptr: inout UnsafePointer<UInt8>?, length:Int) -> Int? {
    var type : Int32 = 0
    var xclass: Int32 = 0
    var len = 0
    ASN1_get_object(&ptr, &len, &type, &xclass, length)
    guard type == V_ASN1_INTEGER else {
        return nil
    }
    let integer = c2i_ASN1_INTEGER(nil, &ptr, len)
    let result = ASN1_INTEGER_get(integer)
    ASN1_INTEGER_free(integer)
    return result
}

func ASN1ReadString(pointer ptr: inout UnsafePointer<UInt8>?, length:Int) -> String? {
    var strLength = 0
    var type : Int32 = 0
    var xclass: Int32 = 0
    ASN1_get_object(&ptr, &strLength, &type, &xclass, length)
    if type == V_ASN1_UTF8STRING {
        let p = UnsafeMutableRawPointer(mutating: ptr!)
        return String(bytesNoCopy: p, length: strLength, encoding: String.Encoding.utf8, freeWhenDone: false)
    }
    return nil
}

func ASN1ReadDate(pointer ptr: inout UnsafePointer<UInt8>?, length:Int) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    if let dateString = ASN1ReadString(pointer: &ptr, length:length) {
        return dateFormatter.date(from: dateString)
    }
    return nil
}
