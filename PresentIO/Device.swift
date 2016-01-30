//
//  Device.swift
//  PresentIO
//
//  Created by Gonçalo Borrêga on 29/01/16.
//  Copyright © 2016 Borrega. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation

class Device: NSObject, NSCoding {
    
    var name: String
    var uid: String
    var portraitRect: NSRect
    var landscapeRect: NSRect
    
    struct PropertyKey {
        static let nameKey = "name"
        static let uidKey = "uid"
        static let portraitRectKey = "p_rect"
        static let landscapeRectKey = "l_rect"
    }
    
    static let ArchivePath = NSHomeDirectory().stringByAppendingString("/devices")

    convenience init?(fromDevice device: AVCaptureDevice) {
        self.init(name: device.localizedName, uid: device.uniqueID, portraitRect:NSRect(), landscapeRect:NSRect())
    }
    init(name: String, uid: String, portraitRect:NSRect, landscapeRect:NSRect) {
        self.name = name
        self.uid = uid
        self.portraitRect = portraitRect
        self.landscapeRect = landscapeRect
        
        super.init()
    }
    
    func hasPreviousLocation(forOrientation: DeviceOrientation) -> Bool {
        if forOrientation == DeviceOrientation.Portrait {
            return portraitRect.origin.x != 0 || portraitRect.origin.y != 0
                || portraitRect.size.height != 0 || portraitRect.size.width != 0
        } else {
            return landscapeRect.origin.x != 0 || landscapeRect.origin.y != 0
                || landscapeRect.size.height != 0 || landscapeRect.size.width != 0
        }
    }
    func savedSettingForOrientation(forOrientation: DeviceOrientation) -> NSRect {
        if forOrientation == DeviceOrientation.Portrait {
            print("Using Portrait settings for \(name): \(portraitRect)")
            return portraitRect
        } else {
            print("Using Landscape settings for \(name): \(portraitRect)")
            return landscapeRect
        }
    }

    
    //MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(name, forKey: PropertyKey.nameKey)
        aCoder.encodeObject(uid, forKey: PropertyKey.uidKey)
        
        aCoder.encodeObject(NSStringFromRect(portraitRect), forKey: PropertyKey.portraitRectKey)
        aCoder.encodeObject(NSStringFromRect(landscapeRect), forKey: PropertyKey.landscapeRectKey)
        
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObjectForKey(PropertyKey.nameKey) as! String
        let uid = aDecoder.decodeObjectForKey(PropertyKey.uidKey) as! String
        let pRect = NSRectFromString(aDecoder.decodeObjectForKey(PropertyKey.portraitRectKey) as! String)
        let lRect = NSRectFromString(aDecoder.decodeObjectForKey(PropertyKey.landscapeRectKey) as! String)
        
        // Must call designated initializer.
        self.init(name: name, uid: uid, portraitRect:pRect, landscapeRect:lRect)
    }
    
}