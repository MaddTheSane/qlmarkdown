//
//  markdown.swift
//  QLMarkdown
//
//  Created by C.W. Betts on 1/17/15.
//
//

import Foundation

internal func renderMarkdown(url: NSURL) -> NSData? {
	if let aBund = NSBundle(identifier: "com.fiatdev.QLMarkdown"), abundRes = aBund.URLForResource("styles", withExtension: "css"), styles = try? String(contentsOfURL: abundRes, encoding: NSUTF8StringEncoding) {
		var usedEncoding: NSStringEncoding = 0
		
		if let source = try? String(contentsOfURL: url, usedEncoding: &usedEncoding) {
			if usedEncoding == 0 {
				NSLog("Wasn't able to determine encoding for file “%@”", url.path!)
			}
			let output = convert_markdown_to_string(source)
            let strOutput = NSString(bytesNoCopy: UnsafeMutablePointer<Void>(output), length: Int(strlen(output)), encoding: NSUTF8StringEncoding, freeWhenDone: true) as! String
			let html = "<!DOCTYPE html>\n<meta charset=utf-8>\n<style>\(styles)</style>\n<base href=\"\(url)\"/>\(strOutput)"
			
			return html.dataUsingEncoding(NSUTF8StringEncoding)
		}
	}
	
	return nil
}
