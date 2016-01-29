//
//  NotificationManager.swift
//  PresentIO
//
//  Created by Gonçalo Borrêga on 07/03/15.
//  Copyright (c) 2015 Borrega. All rights reserved.
//  Inspired by http://moreindirection.blogspot.pt/2014/08/nsnotificationcenter-swift-and-blocks.html

import Foundation

struct NotificationGroup {
    let entries: [String]
    
    init(_ newEntries: String...) {
        entries = newEntries
    }
    
}

class NotificationManager {
    private var observerTokens: [AnyObject] = []
    
    deinit {
        deregisterAll()
    }
    
    func deregisterAll() {
        for token in observerTokens {
            NSNotificationCenter.defaultCenter().removeObserver(token)
        }
        
        observerTokens = []
    }
    
    func registerObserver(name: String!, block: (NSNotification! -> Void)) {
        let newToken = NSNotificationCenter.defaultCenter().addObserverForName(name, object: nil, queue: nil, usingBlock: {note in
            block(note)
        })
        
        observerTokens.append(newToken)
    }
    func registerObserver(name: String!, dispatchAsyncToMainQueue: Bool, block: (NSNotification! -> Void)) {
        let newToken = NSNotificationCenter.defaultCenter().addObserverForName(name, object: nil, queue: nil, usingBlock: {note in
            if dispatchAsyncToMainQueue {
                dispatch_async(dispatch_get_main_queue(), {
                    block(note)
                })
            } else {
                block(note)
            }
        })
        
        observerTokens.append(newToken)
    }
    
    func registerObserver(name: String!, forObject object: AnyObject!, block: (NSNotification! -> Void)) {
        self.registerObserver(name, forObject: object, dispatchAsyncToMainQueue: false, block: block)
    }
    func registerObserver(name: String!, forObject object: AnyObject!, dispatchAsyncToMainQueue: Bool, block: (NSNotification! -> Void)) {
        let newToken = NSNotificationCenter.defaultCenter().addObserverForName(name, object: object, queue: nil, usingBlock: {note in
            if dispatchAsyncToMainQueue {
                dispatch_async(dispatch_get_main_queue(), {
                    block(note)
                })
            } else {
                block(note)
            }
        })
        
        observerTokens.append(newToken)
    }
    
    
    
    func registerGroupObserver(group: NotificationGroup, block: (NSNotification! -> Void)) {
        for name in group.entries {
            self.registerObserver(name, block: block)
        }
    }
}