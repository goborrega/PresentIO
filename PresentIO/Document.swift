//
//  Document.swift
//  PresentIO
//
//  Created by Gonçalo Borrêga on 27/02/15.
//  Copyright (c) 2015 Borrega. All rights reserved.
//

import Cocoa
import AVFoundation
import AVKit



class Document: NSDocument {
    
    @IBOutlet weak var cmbSource: NSPopUpButton!
    @IBOutlet weak var previewView: NSView!
    @IBOutlet weak var lblResolution: NSTextField!
    
    var session : AVCaptureSession = AVCaptureSession()
    var input   : AVCaptureDeviceInput?
    var aspectXonY : CGFloat = 1024/768
    var videoDimensions = CMVideoDimensions(width: 1024,height: 768)
    
    dynamic var devices : [AVCaptureDevice] = []
    
    let notifications = NotificationManager()
    
    override init() {
        super.init()
        
        self.loadObservers()
        
        self.refreshDevices()
        
        // Select devices if any exist
        let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeMuxed)
        if( videoDevice != nil ) {
            self.selectedDevice = videoDevice
        } else {
            self.selectedDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        }
        
    }
    

    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
        
        self.windowForSheet?.movableByWindowBackground = true
        
        
        // Custom view set to render concurrently in order to have its own layer
        let previewViewLayer = self.previewView.layer
        previewViewLayer!.backgroundColor = CGColorGetConstantColor(kCGColorBlack)
        
        let newPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        newPreviewLayer.frame = previewViewLayer!.bounds
        newPreviewLayer.autoresizingMask = CAAutoresizingMask.LayerWidthSizable | CAAutoresizingMask.LayerHeightSizable
        newPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect
        
        previewViewLayer?.addSublayer(newPreviewLayer)
        
        self.session.startRunning()

        // Update Aspect will run recurrently to account for changes in orientation we cannot catch
        // TODO: Optimize to only do this for ios devices and listening for changes to the formatDescription of the video AVCaptureInputPort associated with the device.
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("updateAspect"), userInfo: nil, repeats: true)
        
    }
    
    
    
    func update() {
        self.updateAspect()
    }
    
    func refreshDevices() {
        
        self.devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
            +  AVCaptureDevice.devicesWithMediaType(AVMediaTypeMuxed) as [AVCaptureDevice]
        
        self.session.beginConfiguration()
        
        if( self.selectedDevice != nil && !contains(self.devices, self.selectedDevice!)) {
            self.selectedDevice = nil
        }
        
        self.session.commitConfiguration()
        
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
                var error: NSError?
                let newDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(newValue, error: &error) as AVCaptureDeviceInput?
                
                if (newDeviceInput == nil) {
                    self.displayError(error)
                } else {
                    self.session.sessionPreset = AVCaptureSessionPresetHigh
                    self.session.addInput(newDeviceInput)
                    self.input = newDeviceInput
                }
                
            }
            
            self.session.commitConfiguration()
            
            self.updateAspect()
        }
    }
    
    func updateAspect() {
        
        let port = self.input?.ports.first as AVCaptureInputPort?
        let window = self.windowForSheet
        
        if (port != nil && window != nil) {
            if let description = port!.formatDescription {
                let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                if( dimensions.width != 0 && dimensions.height != 0
                    && (dimensions.width != self.videoDimensions.width || dimensions.height != dimensions.height) ) {
                        
                        self.videoDimensions = dimensions
                        self.aspectXonY = CGFloat(dimensions.width) / CGFloat(dimensions.height)
                        
                        let windowFrame = window!.frame
                        let newFrame = CGRectMake(windowFrame.origin.x, windowFrame.origin.y, windowFrame.size.width, windowFrame.size.width / self.aspectXonY)
                        
                        //window!.setFrame(newFrame, display: true, animate: true)
                        //window!.aspectRatio = NSSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))
                        
                        lblResolution?.stringValue = "w:\(dimensions.width), h:\(dimensions.height)"
                        println("w:\(dimensions.width), h:\(dimensions.height)")
                        
                    
                }
                return
            }
        }
        
        // If unable to calculate, reset ratio & try again
        self.windowForSheet?.resizeIncrements = CGSize(width:1.0,height:1.0)
        lblResolution?.stringValue = "Calculating resolution"
        
    }
    
    func displayError(error: NSError?) {
        dispatch_async(dispatch_get_main_queue(), {
            let err = error as NSError!
            self.presentError(err)
        })
    }
    
    func loadObservers() {
        
        notifications.registerObserver(AVCaptureSessionRuntimeErrorNotification, forObject: session, dispatchAsyncToMainQueue: true, block: {note in
            let err = note.userInfo![AVCaptureSessionErrorKey] as NSError
            self.presentError( err )
        })
        
        
        notifications.registerObserver(AVCaptureSessionDidStartRunningNotification, forObject: session, block: {note in
            println("Did start running")
        })
        notifications.registerObserver(AVCaptureSessionDidStopRunningNotification, forObject: session, block: {note in
            println("Did stop running")
        })
        
        notifications.registerObserver(AVCaptureDeviceWasConnectedNotification, forObject: nil, block: {note in
            println("Device connected")
            self.refreshDevices()
        })
        notifications.registerObserver(AVCaptureDeviceWasDisconnectedNotification, forObject: nil, block: {note in
            println("Device disconnected")
            self.refreshDevices()
        })
        
        
    }
    
    func windowWillClose(notification: NSNotification) {
        self.session.stopRunning()
        self.notifications.deregisterAll()
    }
    
    //    override class func autosavesInPlace() -> Bool {
    //        return true
    //    }
    
    override var windowNibName: String? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return "Document"
    }
    
    override func dataOfType(typeName: String, error outError: NSErrorPointer) -> NSData? {
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        outError.memory = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        return nil
    }
    
    override func readFromData(data: NSData, ofType typeName: String, error outError: NSErrorPointer) -> Bool {
        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
        outError.memory = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        return false
    }
    
    
    
}

