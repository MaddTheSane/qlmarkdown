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

// 5E2D9680-5022-40FA-B806-43349622E5B9
private let kQLGeneratorTypeID = CFUUIDGetConstantUUIDWithBytes(kCFAllocatorDefault, 0x5E, 0x2D, 0x96, 0x80, 0x50, 0x22, 0x40, 0xFA, 0xB8, 0x06, 0x43, 0x34, 0x96, 0x22, 0xE5, 0xB9)
// 865AF5E0-6D30-4345-951B-D37105754F2D
private let kQLGeneratorCallbacksInterfaceID = CFUUIDGetConstantUUIDWithBytes(kCFAllocatorDefault, 0x86, 0x5A, 0xF5, 0xE0, 0x6D, 0x30, 0x43, 0x45, 0x95, 0x1B, 0xD3, 0x71, 0x05, 0x75, 0x4F, 0x2D)

// Don't modify this line
private let PLUGIN_ID = "984AED87-72B9-4060-B7BC-935561C2221B"


private let S_OK: HRESULT = 0
private let E_NOINTERFACE = HRESULT(bitPattern: 0x80000004)

/// The minimum aspect ratio (width / height) of a thumbnail.
private let MINIMUM_ASPECT_RATIO: CGFloat = 1.0 / 2.0

struct QLGeneratorPlugType {
    var conduitInterface: UnsafeMutableRawPointer
    var factoryID: CFUUID!
    var refCount: UInt32
}

private var myInterfaceFtbl = QLGeneratorInterfaceStruct(_reserved: nil,
    QueryInterface: quickLookGeneratorQueryInterface,
    AddRef: quickLookGeneratorPluginAddRef,
    Release: quickLookGeneratorPluginRelease,
    GenerateThumbnailForURL: nil,
    CancelThumbnailGeneration: nil,
    GeneratePreviewForURL: nil,
    CancelPreviewGeneration: nil)

///Implementation of the `IUnknown` QueryInterface function.
func quickLookGeneratorQueryInterface(thisInstance: UnsafeMutableRawPointer?, iid: REFIID, ppv: UnsafeMutablePointer<LPVOID?>?) -> HRESULT {
    let interfaceID = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, iid)!
    
    if CFEqual(interfaceID, kQLGeneratorCallbacksInterfaceID) {
        /* If the Right interface was requested, bump the ref count,
        * set the ppv parameter equal to the instance, and
        * return good status.
        */

        let tmpConInterface: UnsafeMutablePointer<QLGeneratorInterfaceStruct> = {
            let tmpInterface = thisInstance?.assumingMemoryBound(to: QLGeneratorPlugType.self)
            return tmpInterface!.pointee.conduitInterface.assumingMemoryBound(to: QLGeneratorInterfaceStruct.self)
            }()
        
        tmpConInterface.pointee.GenerateThumbnailForURL = generateThumbnail
        tmpConInterface.pointee.CancelThumbnailGeneration = cancelThumbnailGeneration
        tmpConInterface.pointee.GeneratePreviewForURL = generatePreview
        tmpConInterface.pointee.CancelPreviewGeneration = cancelPreviewGeneration
        _=tmpConInterface.pointee.AddRef(thisInstance)
        
        ppv?.pointee = thisInstance
        return S_OK
    } else {
        ppv?.pointee = nil
        return E_NOINTERFACE
    }
}

///Implementation of reference counting for this type. Whenever an interface
///is requested, bump the refCount for the instance. NOTE: returning the
///refcount is a convention but is not required so don't rely on it.
func quickLookGeneratorPluginAddRef(thisInstance: UnsafeMutableRawPointer?) -> ULONG {
    let tmpInstance = thisInstance!.assumingMemoryBound(to: QLGeneratorPlugType.self)
    tmpInstance.pointee.refCount += 1
    return tmpInstance.pointee.refCount
}

///When an interface is released, decrement the refCount.<br>
///If the refCount goes to zero, deallocate the instance.
func quickLookGeneratorPluginRelease(thisInstance: UnsafeMutableRawPointer?) -> ULONG {
    let anInstance = thisInstance!.assumingMemoryBound(to: QLGeneratorPlugType.self)
    anInstance.pointee.refCount -= 1
    if anInstance.pointee.refCount == 0 {
        deallocQuickLookGeneratorPluginType(anInstance)
        return 0;
    } else {
        return anInstance.pointee.refCount
    }
}


private func deallocQuickLookGeneratorPluginType(_ thisInstance: UnsafeMutablePointer<QLGeneratorPlugType>) {
    let theFactoryID = thisInstance.pointee.factoryID
    thisInstance.pointee.factoryID = nil
    
    /* Free the conduitInterface table up */
    free(thisInstance.pointee.conduitInterface);
    
    /* Free the instance structure */
    free(thisInstance);
    if let theFactoryID = theFactoryID {
        CFPlugInRemoveInstanceForFactory(theFactoryID);
    }
}

//MARK: QuickLook functions

private func generatePreview(thisInstance: UnsafeMutableRawPointer?, preview: QLPreviewRequest?, url: CFURL?, contentTypeUTI: CFString?, options: CFDictionary?) -> OSStatus {
    if let data = renderMarkdown(url: url! as URL) {
        let props = [kQLPreviewPropertyTextEncodingNameKey as String: "UTF-8",
                     kQLPreviewPropertyMIMETypeKey as String: "text/html"]
        QLPreviewRequestSetDataRepresentation(preview, data as CFData, kUTTypeHTML, props as NSDictionary)
    }
    return noErr
}

func cancelPreviewGeneration(thisInstance: UnsafeMutableRawPointer?, preview: QLPreviewRequest?) {
    // Implement only if supported
}

func generateThumbnail(thisInstance: UnsafeMutableRawPointer?, thumbnail: QLThumbnailRequest?, url: CFURL?, contentTypeUTI: CFString?, options: CFDictionary?, maxSize: CGSize) -> OSStatus {
    if let data = renderMarkdown(url: url! as URL) {
        let viewRect = NSRect(x: 0, y: 0, width: 600, height: 800)
        let scale = maxSize.height / 800.0
        let scaleSize = NSSize(width: scale, height: scale)
        let thumbSize = NSSize(width: maxSize.width * (600.0 / 800.0), height: maxSize.height)
        
        let webView = WebView(frame: viewRect)
        webView.scaleUnitSquare(to: scaleSize)
        webView.mainFrame.frameView.allowsScrolling = false
        webView.mainFrame.load(data, mimeType: "text/html", textEncodingName: "utf-8", baseURL: nil)
        
        while webView.isLoading {
            CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0, true)
        }
        
        webView.display()
        
        if let context = QLThumbnailRequestCreateContext(thumbnail, thumbSize, false, nil)?.takeRetainedValue() {
            let nsContext = NSGraphicsContext(cgContext: context, flipped: webView.isFlipped)
            webView.displayIgnoringOpacity(webView.bounds, in: nsContext)
            
            QLThumbnailRequestFlushContext(thumbnail, context);
        }
    }
    
    return noErr;
}

func cancelThumbnailGeneration(thisInstance: UnsafeMutableRawPointer?, thumbnail: QLThumbnailRequest?) {
    // Implement only if supported
}

/// Utility function that allocates a new instance.<br>
///      You can do some initial setup for the generator here if you wish
///      like allocating globals etc...
func allocQuickLookGeneratorPluginType(_ inFactoryID: CFUUID) -> UnsafeMutablePointer<QLGeneratorPlugType> {
    let theNewInstance = calloc(MemoryLayout<QLGeneratorPlugType>.alignment, 1).assumingMemoryBound(to: QLGeneratorPlugType.self)
    
    /* Point to the function table Malloc enough to store the stuff and copy the filler from myInterfaceFtbl over */
    theNewInstance.pointee.conduitInterface = malloc(MemoryLayout<QLGeneratorInterfaceStruct>.alignment)
    memcpy(theNewInstance.pointee.conduitInterface, &myInterfaceFtbl, MemoryLayout<QLGeneratorInterfaceStruct>.alignment)
    
    /*  Retain and keep an open instance refcount for each factory. */
    theNewInstance.pointee.factoryID = inFactoryID
    CFPlugInAddInstanceForFactory(inFactoryID)
    
    /* This function returns the IUnknown interface so set the refCount to one. */
    theNewInstance.pointee.refCount = 1;
    return theNewInstance
}

final class QLMarkDownGenerator: NSObject {
    @objc static func quickLookGeneratorPluginFactory(_ allocator: CFAllocator!, typeID: CFUUID) -> UnsafeMutableRawPointer? {
        
        /* If correct type is being requested, allocate an
        * instance of kQLGeneratorTypeID and return the IUnknown interface.
        */
        guard CFEqual(typeID, kQLGeneratorTypeID) else {
            /* If the requested type is incorrect, return NULL. */
            
            return nil
        }
        let uuid = CFUUIDCreateFromString(kCFAllocatorDefault, PLUGIN_ID as CFString)!
        let result = allocQuickLookGeneratorPluginType(uuid)
        return UnsafeMutableRawPointer(result)
    }
}
