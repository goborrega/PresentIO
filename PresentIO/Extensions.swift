//
//  Extensions.swift
//  PresentIO
//
//  Created by Gonçalo Borrêga on 29/03/15.
//  Copyright (c) 2015 Borrega. All rights reserved.
//

import Foundation

extension Int {
    func format(f: String) -> String {
        return NSString(format: "%\(f)d", self) as String
    }
}

extension Double {
    func format(f: String) -> String {
        return NSString(format: "%\(f)f", self) as String
    }
    func to_CGFloat() -> CGFloat {
        return CGFloat(self)
    }
}

extension CGFloat {
    func format(f: String) -> String {
        return Double(self).format(f)
    }
}

extension NSSize {
    init(fromCGSize size:CGSize) {
        self.width = size.width
        self.height = size.height
    }
    func rotated() -> NSSize {
        return NSSize(width: self.height, height: self.width)
    }
    func toIntegerSizes() -> NSSize {
        return NSSize(width: Int(self.width), height: Int(self.height))
    }
    var orientation : DeviceOrientation {
        get {
            return self.height >= self.width ? .Portrait : .Landscape
        }
    }
    func scaleToFit(targetSize: NSSize) -> NSSize {

        if NSEqualSizes(self, targetSize) {
            return self
        }
        
        let widthFactor  = targetSize.width / width
        let heightFactor = targetSize.height / height

        var scaleFactor :CGFloat = 0.0
        if ( widthFactor < heightFactor ) {
            scaleFactor = widthFactor
        } else {
            scaleFactor = heightFactor
        }
        
        let scaledWidth  = width  * scaleFactor;
        let scaledHeight = height * scaleFactor;
        
        return NSSize(width: scaledWidth, height: scaledHeight)
        
    }
}
extension NSPoint {
    func rounded() -> NSPoint {
        return NSPoint(x: Int(self.x), y: Int(self.y))
    }
}