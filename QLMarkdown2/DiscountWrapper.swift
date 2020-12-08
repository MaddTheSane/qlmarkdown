//
//  DiscountWrapper.swift
//  QLMarkdown2
//
//  Created by C.W. Betts on 12/8/20.
//

import Foundation

enum MarkDownErrors: Error {
    case documentFailure
    case compileFailure
    case documentGenerationFailure
}

private func convertMarkDownToHTMLData(from theURL: URL) throws -> Data {
    guard let outFile = theURL.withUnsafeFileSystemRepresentation({fopen($0, "r")}) else {
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(errno), userInfo: [NSURLErrorKey: theURL])
    }
    defer {
        fclose(outFile)
    }
    guard let blob = mkd3_in(outFile, nil) else {
        throw MarkDownErrors.documentFailure
    }
    defer {
        mkd_cleanup(blob)
    }
    
    var out: UnsafeMutablePointer<Int8>? = nil
    let success = mkd3_compile(blob, nil) != 0
    guard success else {
        throw MarkDownErrors.compileFailure
    }
    let sz = mkd_document(blob, &out)
    if sz != 0, let out = out {
        return Data(bytesNoCopy: out, count: Int(sz), deallocator: .free)
    } else {
        throw MarkDownErrors.documentGenerationFailure
    }
}

private let styles = try! String(contentsOf: Bundle(for: PreviewViewController.self).url(forResource: "styles", withExtension: "css")!, encoding: .utf8)

func renderMarkdown(from: URL) throws -> Data {
    let data = try convertMarkDownToHTMLData(from: from)
    
    var encStr: String?
    
    var html = """
    <!DOCTYPE html>
    <meta charset=utf-8>
    <style>\(styles)</style>
    <base href="\(from)"/>
    
    """
    
    for enc in [String.Encoding.utf8, String.Encoding.isoLatin1, String.Encoding.macOSRoman] {
        encStr = String(data: data, encoding: enc)
        if encStr != nil {
            break
        }
    }
    guard let encStr2 = encStr else {
        throw CocoaError(.fileReadInapplicableStringEncoding, userInfo: [NSURLErrorKey: from])
    }
    html += encStr2
    
    return html.data(using: .utf8)!
}
