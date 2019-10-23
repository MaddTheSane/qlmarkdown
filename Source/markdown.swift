//
//  markdown.swift
//  QLMarkdown
//
//  Created by C.W. Betts on 1/17/15.
//
//

import Foundation

private func convertMarkDownToString(_ str: String) -> String? {
    let cStr = Array(str.utf8CString)
    var out: UnsafeMutablePointer<Int8>? = nil
    let blob = mkd_string(cStr, Int32(cStr.count - 1), 0)
    mkd_compile(blob, 0)
    let sz = mkd_document(blob, &out)
    
    if sz == 0 {
        return nil
    } else {
        out?[Int(sz) - 1] = 0
    }
    let aStr = String(cString: out!)
    free(out)
    return aStr
}

internal func renderMarkdown(url: URL) -> Data? {
    guard let aBund = Bundle(identifier: "com.fiatdev.QLMarkdown"),
        let abundRes = aBund.url(forResource: "styles", withExtension: "css"),
        let styles = try? String(contentsOf: abundRes, encoding: .utf8) else {
        return nil
    }
    var usedEncoding: String.Encoding = String.Encoding(rawValue: 0)
    
    guard let source = try? String(contentsOf: url, usedEncoding: &usedEncoding)  else {
        return nil
    }
    if usedEncoding.rawValue == 0 {
        NSLog("Wasn't able to determine encoding for file “%@”", url.path)
    }
    if let output = convertMarkDownToString(source) {
        let html = "<!DOCTYPE html>\n<meta charset=utf-8>\n<style>\(styles)</style>\n<base href=\"\(url)\"/>\(output)"
        
        return html.data(using: .utf8)
    }
    
    return nil
}
