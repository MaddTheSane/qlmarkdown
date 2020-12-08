//
//  DiscountWrapper.swift
//  QLMarkdown2
//
//  Created by C.W. Betts on 12/8/20.
//

import Foundation

func convertMarkDownToHTMLData(from theURL: URL) -> Data? {
    guard let outFile = theURL.withUnsafeFileSystemRepresentation({fopen($0, "r")}) else {
        return nil
    }
    defer {
        fclose(outFile)
    }
    guard let blob = mkd3_in(outFile, nil) else {
        return nil
    }
    defer {
        mkd_cleanup(blob)
    }
    
    var out: UnsafeMutablePointer<Int8>? = nil
    mkd3_compile(blob, nil)
    let sz = mkd_document(blob, &out)
    if sz != 0, let out = out {
        return Data(bytesNoCopy: out, count: Int(sz), deallocator: .free)
    } else {
        return nil
    }
}

private let styles = try! String(contentsOf: Bundle(for: PreviewViewController.self).url(forResource: "styles", withExtension: "css")!, encoding: .utf8)

func renderMarkdown(from: URL) -> Data? {
    guard let data = convertMarkDownToHTMLData(from: from) else {
        return nil
    }
    
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
        return nil
    }
    html += encStr2
    
    return html.data(using: .utf8)
}
