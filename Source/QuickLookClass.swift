//
//  File.swift
//  QLMarkdown
//
//  Created by C.W. Betts on 1/17/15.
//
//

import Cocoa
import CoreServices
import QuickLook
import WebKit

/// The minimum aspect ratio (width / height) of a thumbnail.
private let MINIMUM_ASPECT_RATIO: CGFloat = 1.0 / 2.0


final class QLMarkDownGenerator: NSObject {
	@objc(generatePreview:forURL:contentTypeUTI:options:) class func generatePreview(preview: QLPreviewRequest, url: CFURL, contentTypeUTI: CFString, options: CFDictionary) -> OSStatus {
		if let data = renderMarkdown(url) {
            QLPreviewRequestSetDataRepresentation(preview, data, kUTTypeHTML, [:])
		}
		return noErr
	}
	
	@objc class func cancelPreviewGeneration(preview: QLPreviewRequest) {
		// Implement only if supported
	}
	
	@objc(generateThumbnail:forURL:contentTypeUTI:options:maxSize:) class func generateThumbnail(thumbnail: QLThumbnailRequest, url: CFURL, contentTypeUTI: CFString, options: CFDictionary, maxSize: CGSize) -> OSStatus {
		if let data = renderMarkdown(url) {
			let viewRect = NSRect(x: 0, y: 0, width: 600, height: 800)
			let scale = maxSize.height / 800.0
			let scaleSize = NSSize(width: scale, height: scale)
			let thumbSize = NSSize(width: maxSize.width * (600.0 / 800.0), height: maxSize.height)
			
			let webView = WebView(frame: viewRect)
			webView.scaleUnitSquareToSize(scaleSize)
			webView.mainFrame.frameView.allowsScrolling = false
			webView.mainFrame.loadData(data, MIMEType: "text/html", textEncodingName: "utf-8", baseURL: nil)
			
			while webView.loading {
				CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true)
			}
			
			webView.display()
			
			if let context = QLThumbnailRequestCreateContext(thumbnail, thumbSize, false, nil)?.takeRetainedValue() {
				let nsContext = NSGraphicsContext(CGContext: context, flipped: webView.flipped)
				webView.displayRectIgnoringOpacity(webView.bounds, inContext: nsContext)
				
				QLThumbnailRequestFlushContext(thumbnail, context);
			}
		}
		
		return noErr;
	}
	
	@objc class func cancelThumbnailGeneration(thumbnail: QLThumbnailRequest) {
		// Implement only if supported
	}
}
