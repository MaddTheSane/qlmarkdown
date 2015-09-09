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
    var conduitInterface: UnsafeMutablePointer<()>
    var factoryID: CFUUIDRef!
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
func quickLookGeneratorQueryInterface(thisInstance: UnsafeMutablePointer<Void>, iid: REFIID, ppv: UnsafeMutablePointer<LPVOID>) -> HRESULT {
    let interfaceID = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, iid)!
    
    if CFEqual(interfaceID, kQLGeneratorCallbacksInterfaceID) {
        /* If the Right interface was requested, bump the ref count,
        * set the ppv parameter equal to the instance, and
        * return good status.
        */

        let tmpConInterface: UnsafeMutablePointer<QLGeneratorInterfaceStruct> = {
            let tmpInterface = UnsafeMutablePointer<QLGeneratorPlugType>(thisInstance)
            return UnsafeMutablePointer<QLGeneratorInterfaceStruct>(tmpInterface.memory.conduitInterface)
            }()
        
        tmpConInterface.memory.GenerateThumbnailForURL = generateThumbnail
        tmpConInterface.memory.CancelThumbnailGeneration = cancelThumbnailGeneration
        tmpConInterface.memory.GeneratePreviewForURL = generatePreview
        tmpConInterface.memory.CancelPreviewGeneration = cancelPreviewGeneration
        tmpConInterface.memory.AddRef(thisInstance)
        
        ppv.memory = thisInstance
        return S_OK
    } else {
        ppv.memory = nil
        return E_NOINTERFACE
    }
}

///Implementation of reference counting for this type. Whenever an interface
///is requested, bump the refCount for the instance. NOTE: returning the
///refcount is a convention but is not required so don't rely on it.
func quickLookGeneratorPluginAddRef(thisInstance: UnsafeMutablePointer<Void>) -> ULONG {
    let tmpInstance = UnsafeMutablePointer<QLGeneratorPlugType>(thisInstance)
    return ++tmpInstance.memory.refCount
}

///When an interface is released, decrement the refCount.<br>
///If the refCount goes to zero, deallocate the instance.
func quickLookGeneratorPluginRelease(thisInstance: UnsafeMutablePointer<Void>) -> ULONG {
    let anInstance = UnsafeMutablePointer<QLGeneratorPlugType>(thisInstance)
    anInstance.memory.refCount -= 1
    if anInstance.memory.refCount == 0 {
        deallocQuickLookGeneratorPluginType(anInstance)
        return 0;
    } else {
        return anInstance.memory.refCount
    }
}


private func deallocQuickLookGeneratorPluginType(thisInstance: UnsafeMutablePointer<QLGeneratorPlugType>) {
    let theFactoryID = thisInstance.memory.factoryID
    thisInstance.memory.factoryID = nil
    
    /* Free the conduitInterface table up */
    free(thisInstance.memory.conduitInterface);
    
    /* Free the instance structure */
    free(thisInstance);
    if let theFactoryID = theFactoryID {
        CFPlugInRemoveInstanceForFactory(theFactoryID);
    }
}

private func generatePreview(thisInstance: UnsafeMutablePointer<Void>, preview: QLPreviewRequest!, url: CFURL!, contentTypeUTI: CFString!, options: CFDictionary!) -> OSStatus {
    if let data = renderMarkdown(url) {
        QLPreviewRequestSetDataRepresentation(preview, data, kUTTypeHTML, [:])
    }
    return noErr
}

func cancelPreviewGeneration(thisInstance: UnsafeMutablePointer<Void>, preview: QLPreviewRequest!) {
    // Implement only if supported
}

func generateThumbnail(thisInstance: UnsafeMutablePointer<Void>, thumbnail: QLThumbnailRequest!, url: CFURL!, contentTypeUTI: CFString!, options: CFDictionary!, maxSize: CGSize) -> OSStatus {
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

func cancelThumbnailGeneration(thisInstance: UnsafeMutablePointer<Void>, thumbnail: QLThumbnailRequest!) {
    // Implement only if supported
}

/// Utility function that allocates a new instance.<br>
///      You can do some initial setup for the generator here if you wish
///      like allocating globals etc...
func allocQuickLookGeneratorPluginType(inFactoryID: CFUUID) -> UnsafeMutablePointer<QLGeneratorPlugType> {
    let theNewInstance = UnsafeMutablePointer<QLGeneratorPlugType>(calloc(sizeof(QLGeneratorPlugType), 1))
    
    /* Point to the function table Malloc enough to store the stuff and copy the filler from myInterfaceFtbl over */
    theNewInstance.memory.conduitInterface = malloc(sizeof(QLGeneratorInterfaceStruct))
    memcpy(theNewInstance.memory.conduitInterface, &myInterfaceFtbl, sizeof(QLGeneratorInterfaceStruct))
    
    /*  Retain and keep an open instance refcount for each factory. */
    theNewInstance.memory.factoryID = inFactoryID
    CFPlugInAddInstanceForFactory(inFactoryID)
    
    /* This function returns the IUnknown interface so set the refCount to one. */
    theNewInstance.memory.refCount = 1;
    return theNewInstance
}


final class QLMarkDownGenerator: NSObject {
    static func quickLookGeneratorPluginFactory(allocator: CFAllocatorRef!, typeID: CFUUID) -> UnsafeMutablePointer<()> {
        
        /* If correct type is being requested, allocate an
        * instance of kQLGeneratorTypeID and return the IUnknown interface.
        */
        if CFEqual(typeID, kQLGeneratorTypeID) {
            let uuid = CFUUIDCreateFromString(kCFAllocatorDefault, PLUGIN_ID)
            let result = allocQuickLookGeneratorPluginType(uuid)
            return UnsafeMutablePointer<()>(result)
        }
        
        /* If the requested type is incorrect, return NULL. */
        return nil
    }
}
