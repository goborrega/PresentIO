//
//  AppDelegate.swift
//  PresentIO
//
//  Created by Gonçalo Borrêga on 27/02/15.
//  Copyright (c) 2015 Borrega. All rights reserved.
//

import Cocoa

import AVFoundation
import AVKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet var window: NSWindow!
    
    var session : AVCaptureSession = AVCaptureSession()

    let notifications = NotificationManager()
    var devices : [AVCaptureDevice] = []
    
    var deviceSessions : [AVCaptureDevice: Skin] = [:]

    func applicationDidFinishLaunching(aNotification: NSNotification) {

        
        // Opt-in for getting visibility on connected screen capture devices (iphone/ipad)
        DeviceUtils.registerForScreenCaptureDevices()
        
        self.loadObservers()
        
        // Required to receive the AVCaptureDeviceWasConnectedNotification
        //self.session.startRunning()
        
        self.refreshDevices()
       
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        
        self.notifications.deregisterAll()
    }

    func loadObservers() {
        
        notifications.registerObserver(AVCaptureSessionRuntimeErrorNotification, forObject: session, dispatchAsyncToMainQueue: true, block: {note in
            let err = note.userInfo![AVCaptureSessionErrorKey] as! NSError
            //self.window.presentError( err )
            print(err)
        })
        
        
        notifications.registerObserver(AVCaptureSessionDidStartRunningNotification, forObject: session, block: {note in
            print("Did start running")
            self.refreshDevices()
        })
        notifications.registerObserver(AVCaptureSessionDidStopRunningNotification, forObject: session, block: {note in
            print("Did stop running")
        })

                
        notifications.registerObserver(AVCaptureDeviceWasConnectedNotification, forObject: nil, dispatchAsyncToMainQueue: true, block: {note in
            print("Device connected")
            self.refreshDevices()
        })
        notifications.registerObserver(AVCaptureDeviceWasDisconnectedNotification, forObject: nil, dispatchAsyncToMainQueue: true, block: {note in
            print("Device disconnected")
            self.refreshDevices()
        })
        
        
    }
    
    func startNewSession(device:AVCaptureDevice) -> Skin {
        

        let size = DeviceUtils(deviceType: .iPhone).skinSize
        let frame = DeviceUtils.getCenteredRect(size)
        
        let window = NSWindow(contentRect: frame,
            styleMask: NSBorderlessWindowMask | NSResizableWindowMask,
            backing: NSBackingStoreType.Buffered, `defer`: false)
        
        window.movableByWindowBackground = true
        let frameView = NSMakeRect(0, 0,size.width, size.height)
        
        let skin = Skin(frame: frameView)
        skin.initWithDevice(device)
        skin.ownerWindow = window
        window.contentView!.addSubview(skin)
        
        skin.registerNotifications()
        skin.updateAspect()
        
        window.backgroundColor = NSColor.clearColor()
        window.opaque = false
        
        window.makeKeyAndOrderFront(NSApp)

        return skin
    }

    func refreshDevices() {
        
        self.devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeMuxed)
            +  AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]
        
        // A running device was disconnected?
        for(device, deviceView) in deviceSessions {
            if ( !self.devices.contains(device) ) {
                deviceView.endSession()
                deviceView.window?.close()
                self.deviceSessions[device] = nil
            }
        }
        
        // A new device connected?
        for device in self.devices {
            
            if device.modelID == "iOS Device" {
                if (!self.deviceSessions.keys.contains(device)) {
                    self.deviceSessions[device] = startNewSession(device)
                }
            }
        }

        if self.deviceSessions.count > 0 {
           self.window!.close()
        } else {
           self.window!.makeKeyAndOrderFront(NSApp)
        }
        
//        self.session.beginConfiguration()
//        
//        if( self.selectedDevice != nil && !contains(self.devices, self.selectedDevice!)) {
//            self.selectedDevice = nil
//        }
//        
//        self.session.commitConfiguration()
        
    }

}

