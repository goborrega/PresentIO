//
//  Skin.swift
//  PresentIO
//
//  Created by Gonçalo Borrêga on 09/03/15.
//  Copyright (c) 2015 Borrega. All rights reserved.
//

import Cocoa
import AVFoundation
import AVKit

//@IBDesignable
class Skin: NSView {
    
    @IBOutlet var view: NSView!
    
    @IBOutlet weak var previewView: NSView!
    @IBOutlet weak var lblResolution: NSTextField!
    @IBOutlet weak var deviceFrameImage: NSImageView!
    
    @IBOutlet weak var resizeHandle: NSImageView!
    
    var session : AVCaptureSession!     // Provided by the parent window/controller
    var input   : AVCaptureDeviceInput?
    var device = DeviceUtils(deviceType: .iPhone)
    
    let notifications = NotificationManager()
    internal var ownerWindow : NSWindow?
    
    var videoPreviewLayer : AVCaptureVideoPreviewLayer?
    var originalPreviewViewBounds : NSRect = NSRect()
    
    var initialLocation : NSPoint?
    var initialMouseDrag : NSPoint?
    var isResize = false
    var trackingArea : NSTrackingArea?
    
    let ResizeHandleSize : CGFloat = 30
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.frame = frameRect
        
        self.loadSkinForDevice()
    }
    
    override var mouseDownCanMoveWindow : Bool {
        get {
            return true
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder:coder)
        self.loadSkinForDevice()
    }
    
    private func loadSkinForDevice() {
        
        let newDev = DeviceUtils.initWithDimensions(self.device.videDimensions)
        if( self.device.type != newDev.type || self.view == nil ) {
            self.device = newDev
            
            loadSkinFromNib(self.device.skin)
            
            let size = newDev.getWindowSize()
            let frame = NSMakeRect(0, 0, size.width, size.height)
            self.ownerWindow?.setFrame(frame, display: true)
            
            
        }
        
    }

    
    private func loadSkinFromNib(skin : String) {
        
        if(self.view != nil) {
            self.view.removeFromSuperview()
        }
        
        if ( NSBundle.mainBundle().loadNibNamed(skin, owner: self, topLevelObjects: nil)) {
            self.view.frame = self.bounds
            self.addSubview(self.view)
            
            // Custom view set to render concurrently in order to have its own layer
            let previewViewLayer = self.previewView.layer
            previewViewLayer!.backgroundColor = CGColorGetConstantColor(kCGColorBlack)
            
            self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            self.videoPreviewLayer!.frame = previewViewLayer!.bounds
            self.videoPreviewLayer!.autoresizingMask = [CAAutoresizingMask.LayerWidthSizable, CAAutoresizingMask.LayerHeightSizable]
            self.videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
            
            previewViewLayer?.addSublayer(self.videoPreviewLayer!)
            
            originalPreviewViewBounds = self.previewView.bounds
            
            //self.session?.startRunning()
            
           
        }
    }
    
    func registerNotifications() {
        self.notifications.registerObserver(
            NSWindowDidResizeNotification, forObject: self.window!, dispatchAsyncToMainQueue: true, block: {note in
                self.updateViewsToWindow(self.window!.frame.size)
        })
    }
    
    func initWithDevice(device: AVCaptureDevice) {
        
        self.session = AVCaptureSession()
        
        // Custom view set to render concurrently in order to have its own layer
        let previewViewLayer = self.previewView.layer
        previewViewLayer!.backgroundColor = CGColorGetConstantColor(kCGColorWhite)
        
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.videoPreviewLayer!.frame = previewViewLayer!.bounds
        //newPreviewLayer.autoresizingMask = CAAutoresizingMask.LayerWidthSizable | CAAutoresizingMask.LayerHeightSizable
        self.videoPreviewLayer!.videoGravity = AVLayerVideoGravityResize
        previewViewLayer?.addSublayer(self.videoPreviewLayer!)
        
        
        self.selectedDevice = device
        self.session.startRunning()
        
    }
    
    var selectedDevice : AVCaptureDevice? {
        get {
            return self.input?.device
        }
        set {
            self.session.beginConfiguration()
            
            if(input != nil) {
                session.removeInput(self.input)
                self.input = nil
            }
            
            if newValue != nil {
                
                do {
                    let newDeviceInput = try AVCaptureDeviceInput(device: newValue)
                
                    self.session.sessionPreset = AVCaptureSessionPresetHigh
                    self.session.addInput(newDeviceInput)
                    self.input = newDeviceInput
                    
                    // Register for notifications in format change which imply orientation change
                    self.notifications.registerObserver(AVCaptureInputPortFormatDescriptionDidChangeNotification, dispatchAsyncToMainQueue: true, block: {notif in
                        self.updateAspect()
                    })
                    
                } catch let error as NSError {
                    self.displayError(error)
                }
                
            }
            
            self.session.commitConfiguration()
            
            self.updateAspect()
            
        }
    }
    
    func getVideoDimensions() -> CMVideoDimensions {
        
        // let window = self.windowForSheet
        if( window != nil) {
            if let port = self.input?.ports.first as? AVCaptureInputPort? {
                if let description = port!.formatDescription {
                    return CMVideoFormatDescriptionGetDimensions(description)
                }
            }
        }
        return CMVideoDimensions(width: 0,height: 0)
    }
    

    
    
    func updateAspect() {
        
        let dimensions = self.getVideoDimensions()
        
        if( dimensions.width != 0 && dimensions.height != 0 ) {
            
            if (dimensions.width != self.device.videDimensions.width || dimensions.height != self.device.videDimensions.height) {
                
                self.device.videDimensions = dimensions
                self.loadSkinForDevice()
                
                let size = self.device.getSkinSize()
                var windowSize = self.window!.frame.size //self.device.getWindowSize()
                windowSize = windowSize.orientation != self.device.orientation ? windowSize.rotated() : windowSize

                let screenFrame = NSScreen.mainScreen()?.frame
                
                
                centerWindow(windowSize)
               
                updateViewsToWindow(windowSize)
                
                self.window!.setFrame(NSRect(origin: CGPoint(), size: windowSize), display: true)
            }
            return
            
        }
        
    }
    
    func updateViewsToWindow(windowSize : NSSize) {
        
        self.setFrameSize(windowSize)
        self.setFrameOrigin(NSPoint(x: 0,y: 0))
        self.view.frame = self.bounds
        
        self.deviceFrameImage.image = NSImage(named: self.device.getSkinDeviceImage())
        self.deviceFrameImage.translatesAutoresizingMaskIntoConstraints = true
        self.deviceFrameImage.setFrameSize(self.bounds.size)
        self.deviceFrameImage.setFrameOrigin(NSPoint(x: 0,y: 0))
        self.deviceFrameImage.needsDisplay = true
        
        let scale  = windowSize.width / ( self.device.orientation == .Portrait ? self.device.skinSize.width : self.device.skinSize.height )
        var size = NSSize(width: originalPreviewViewBounds.size.width * scale, height: originalPreviewViewBounds.size.height * scale)
        if self.device.orientation == .Landscape {
            size = size.rotated()
        }
        
        self.previewView.translatesAutoresizingMaskIntoConstraints = true
        self.previewView.setFrameSize(size)

        let origin = NSPoint(
            x: windowSize.width / 2 - size.width / 2,
            y: windowSize.height / 2 - size.height / 2)
        
        self.previewView.setFrameOrigin(origin)

        self.videoPreviewLayer?.frame = self.previewView.bounds
        
        self.needsDisplay = true
        self.window!.invalidateShadow()
        
        if trackingArea != nil {
            self.removeTrackingArea(trackingArea!)
        }
        trackingArea = NSTrackingArea(rect: self.bounds,
            options: [NSTrackingAreaOptions.ActiveAlways, .MouseEnteredAndExited], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea!)
    }
    
    func centerWindow(windowSize : NSSize) {
        
        // Center window
        let screenFrame = NSScreen.mainScreen()?.frame
        let origin = NSPoint(
            x: screenFrame!.width / 2 - windowSize.width / 2,
            y: screenFrame!.height / 2 - windowSize.height / 2 )
        self.window!.aspectRatio = windowSize
        self.window!.setFrame(DeviceUtils.getCenteredRect(windowSize), display:true)
        
    }
    
    func displayError(error: NSError?) {
        dispatch_async(dispatch_get_main_queue(), {
            let err = error as NSError!
            self.presentError(err)
        })
    }
    
    
    func endSession() {
        self.notifications.deregisterAll()
        self.session.stopRunning()
        self.ownerWindow = nil
    }
    

    
//    override func drawRect(dirtyRect: NSRect) {
//        super.drawRect(dirtyRect)
//        
//        NSColor.grayColor().set()
//
//        var mySimpleRect = NSMakeRect(0, 0, self.bounds.size.width, self.bounds.size.height)
//        NSRectFill(mySimpleRect)
//
//        NSColor.redColor().set()
//        mySimpleRect = NSMakeRect(self.deviceFrameImage.bounds.origin.x + 4, self.deviceFrameImage.bounds.origin.y + 4, self.deviceFrameImage.bounds.size.width-8, self.deviceFrameImage.bounds.size.height-8)
//        NSRectFill(mySimpleRect)
//        
//        self.needsDisplay = true
//    }
    
    override func mouseEntered(theEvent: NSEvent) {
        self.resizeHandle.hidden = false
    }
    override func mouseExited(theEvent: NSEvent) {
        self.resizeHandle.hidden = true
        self.window?.invalidateShadow()
    }
    override func mouseDown(theEvent: NSEvent) {
        initialLocation = NSEvent.mouseLocation()
        
        initialLocation?.x -= self.window!.frame.origin.x
        initialLocation?.y -= self.window!.frame.origin.y
        
        isResize = (initialLocation!.x > self.deviceFrameImage!.bounds.size.width - ResizeHandleSize)
            && (initialLocation!.y < ResizeHandleSize)
        
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        
        if isResize {
            return
        }
        let curLocation = NSEvent.mouseLocation()
        
        var newOrigin = NSPoint(
            x: curLocation.x - initialLocation!.x,
            y: curLocation.y - initialLocation!.y)
        
        let screenFrame = NSScreen.mainScreen()?.frame
        if((newOrigin.y + window!.frame.size.height) > (screenFrame!.origin.y + screenFrame!.size.height)) {
            newOrigin.y = screenFrame!.origin.y + (screenFrame!.size.height - window!.frame.size.height)
        }
        
        self.window!.setFrameOrigin(newOrigin)
        
    }
    
}
