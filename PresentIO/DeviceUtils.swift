//
//  DeviceUtils.swift
//  PresentIO
//
//  Created by Gonçalo Borrêga on 01/03/15.
//  Copyright (c) 2015 Borrega. All rights reserved.
//

import Foundation
import CoreMediaIO
import Cocoa
import AVKit
import AVFoundation

enum DeviceType {
    case iPhone
    case iPad
}
enum DeviceOrientation {
    case Portrait
    case Landscape
}

class DeviceUtils {
    
    var type: DeviceType
    var skinSize: NSSize! //video dimensions
    var skin = "Skin"
    var orientation = DeviceOrientation.Portrait
    
    var videDimensions: CMVideoDimensions = CMVideoDimensions(width: 0,height: 0) {
        didSet {
            orientation = videDimensions.width > videDimensions.height ? .Landscape : .Portrait
        }
    }
    
    init(deviceType:DeviceType) {
        self.type = deviceType
        self.skinSize = getSkinSize()
        switch deviceType {
        case .iPhone:
            skin = "Skin"
        case .iPad:
            skin = "Skin_iPad"
        }
    }
    
    class func initWithDimensions(dimensions:CMVideoDimensions) -> DeviceUtils {
        
        var device : DeviceUtils
        if((dimensions.width == 1024 && dimensions.height == 768)
            || (dimensions.width == 768 && dimensions.height == 1024)
            || (dimensions.width == 900 && dimensions.height == 1200)
            || (dimensions.width == 1200 && dimensions.height == 900)
            || (dimensions.width == 1200 && dimensions.height == 1600)
            || (dimensions.width == 1600 && dimensions.height == 1200)) {
            device = DeviceUtils(deviceType: .iPad)
        } else {
            device = DeviceUtils(deviceType: .iPhone)
        }
        
        device.videDimensions = dimensions
        return device
    }
    

    func getSkinDeviceImage() -> String {
        let imgLandscape = self.orientation == .Landscape ? "_landscape" : ""
        let imgtype = self.type == .iPad ? "iPad" : "iphone6"
        return "\(imgtype)_white\(imgLandscape)"
    }

    func getSkinSize() -> NSSize {
        var size : NSSize
        switch self.type {
        case .iPhone:
            size = NSSize(width: 350,height: 700) //640x1136 (iPhone5)
        case .iPad:
            size = NSSize(width: 435,height: 646) // 768x1024 (ipad mini)
        }
        return self.orientation == .Portrait ?
            NSSize(width: size.width, height: size.height) :
            NSSize(width: size.height, height: size.width)
    }
    
    func getFrame() -> CGRect {
        return CGRectMake(0, 0, skinSize.width, skinSize.height)
    }
    
    func getWindowSize() -> NSSize {
        //return NSSize(width: max(skinSize.width, skinSize.height), height: max(skinSize.width, skinSize.height))
        if(self.orientation == .Portrait) {
            return NSSize(width: skinSize.width, height: skinSize.height)
        } else {
            return NSSize(width: skinSize.height, height: skinSize.width)
        }
    }
    
    class func getCenteredRect(windowSize : NSSize) -> NSRect{
        let screenFrame = NSScreen.mainScreen()?.frame
        let origin = NSPoint(
            x: screenFrame!.width / 2 - windowSize.width / 2,
            y: screenFrame!.height / 2 - windowSize.height / 2 )


        return NSRect(origin: origin, size: windowSize)
    }
    
    
    class func registerForScreenCaptureDevices() {
        
        var prop : CMIOObjectPropertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster))
        
        var allow:UInt32 = 1
        
        CMIOObjectSetPropertyData( CMIOObjectID(kCMIOObjectSystemObject),
            &prop,
            0,
            nil,
            UInt32(sizeofValue(allow)),
            &allow)
        
    }
}