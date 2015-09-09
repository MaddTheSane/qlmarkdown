//
//  markdown.swift
//  QLMarkdown
//
//  Created by C.W. Betts on 1/17/15.
//
//

import Foundation

private func convertMarkDownToString(str: String) -> String? {
    let cStr = str.cStringUsingEncoding(NSUTF8StringEncoding)!
    var out = UnsafeMutablePointer<Int8>()
    let blob = mkd_string(cStr, Int32(cStr.count - 1), 0)
    mkd_compile(blob, 0)
    let sz = mkd_document(blob, &out)
    
    if sz == 0 {
        return nil
    } else {
        out[sz - 1] = 0
    }
    let aStr = String.fromCString(out)
    free(out)
    return aStr
}

internal func renderMarkdown(url: NSURL) -> NSData? {
	if let aBund = NSBundle(identifier: "com.fiatdev.QLMarkdown"), abundRes = aBund.URLForResource("styles", withExtension: "css"), styles = try? String(contentsOfURL: abundRes, encoding: NSUTF8StringEncoding) {
		var usedEncoding: NSStringEncoding = 0
		
		if let source = try? String(contentsOfURL: url, usedEncoding: &usedEncoding) {
			if usedEncoding == 0 {
				NSLog("Wasn't able to determine encoding for file “%@”", url.path!)
			}
            if let output = convertMarkDownToString(source) {
                let html = "<!DOCTYPE html>\n<meta charset=utf-8>\n<style>\(styles)</style>\n<base href=\"\(url)\"/>\(output)"
			
                return html.dataUsingEncoding(NSUTF8StringEncoding)
            }
		}
	}
	
	return nil
}
