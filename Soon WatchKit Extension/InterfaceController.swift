//
//  InterfaceController.swift
//  Soon WatchKit Extension
//
//  Created by Ben Sandofsky on 4/26/15.
//  Copyright (c) 2015 Chroma Noir. All rights reserved.
//

import WatchKit
import Foundation
import SoonPlatform

let SoonInterfaceManagerDidSyncCacheNotification = "SoonInterfaceManagerDidSyncCacheNotification"

private let SOON_EVENT_PAGE_IDENTIFIER = "com.chromanoir.soonevent.page"
private let SOON_BLANK_PAGE_IDENTIFIER = "com.chromanoir.soonevent.blank"


class InterfaceController: WKInterfaceController {

    override init() {
        super.init()
        InterfaceManager.sharedIntefaceManager().reload()
    }

}

var _sharedIntefaceManager:InterfaceManager?

class InterfaceManager:NSObject {
    enum Mode {
        case Empty
        case Page
    }
    var mode:Mode!
    class func sharedIntefaceManager() -> InterfaceManager {
        if let interfaceManager = _sharedIntefaceManager {
            return interfaceManager
        } else {
            _sharedIntefaceManager = InterfaceManager()
            return _sharedIntefaceManager!
        }
    }

    var currentEvents:[SoonEvent]

    /// Reloads the page view controllers to reflect events in the app.
    func reload(){
        let ctx = SoonPlatform.sharedPlatform().managedObjectContext
        SoonPlatform.sharedPlatform().managedObjectContext.reset()
        if let events = SoonEvent.fetchUpcomingEventsFromContext(ctx) {
            mode = .Page
            var controllerArray:[String] = Array()
            for event in events {
                controllerArray.append(SOON_EVENT_PAGE_IDENTIFIER)
            }
            InterfaceController.reloadRootControllersWithNames(controllerArray, contexts: events)
        } else {
            mode = .Empty
            InterfaceController.reloadRootControllersWithNames([SOON_BLANK_PAGE_IDENTIFIER], contexts:nil)
        }
    }

    override init() {
        currentEvents = Array()
        super.init()
        dispatch_async(dispatch_get_main_queue()) {
            InterfaceManager.sharedIntefaceManager().syncImagesWithDeviceCache()
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataStoreDidUpdate:", name: SoonEventsDatastoreDidUpdateNotification, object: nil)
        reload()
    }

    func dataStoreDidUpdate(notification:NSNotification){
        InterfaceManager.sharedIntefaceManager().syncImagesWithDeviceCache()
        reload()
    }

    typealias AppRequestCallback = (Bool, NSError?) -> ()

    func favoriteEvent(event:SoonEvent, block:AppRequestCallback){
        if event.isFavorite {
            NSLog("Trying to favorite something already favorited")
            return
        }
        event.isFavorite = true
        let info:[NSObject:AnyObject] = [
            SoonPlatformAppActionKey:SoonPlatformAppAction.Favorite.rawValue,
            SoonPlatformAppEventURIKey:event.objectID.URIRepresentation().absoluteString!
        ]
        WKInterfaceController.openParentApplication(info, reply: { (responseOrNil, errorOrNil) -> Void in
            dispatch_async(dispatch_get_main_queue()){
                if let error = errorOrNil {
                    event.isFavorite = false
                    block(false, error)
                } else {
                    block(true, nil)
                }
            }
        })
    }
    func unfavoriteEvent(event:SoonEvent, block:AppRequestCallback){
        if !event.isFavorite {
            NSLog("Trying to unfavorite something that isn't favorited")
            return
        }
        event.isFavorite = false
        let info:[NSObject:AnyObject] = [
            SoonPlatformAppActionKey:SoonPlatformAppAction.Unfavorite.rawValue,
            SoonPlatformAppEventURIKey:event.objectID.URIRepresentation().absoluteString!
        ]
        WKInterfaceController.openParentApplication(info, reply: { (responseOrNil, errorOrNil) -> Void in
            dispatch_async(dispatch_get_main_queue()){
                if let error = errorOrNil {
                    event.isFavorite = true
                    block(false, error)
                } else {
                    block(true, nil)
                }
            }
        })
    }

    func updateInterfaceImage(imageView:WKInterfaceImage, withEvent event:SoonEvent){
        if let imageID = event.imageID {
            if WKInterfaceDevice.currentDevice().cachedImages[imageID] != nil {
                imageView.setImageNamed(imageID)
            } else {
                let device = WKInterfaceDevice.currentDevice()
                let imageData = event.generateImageOptimizedForWatchWithWidth(device.screenBounds.size.width, scale:device.screenScale)
                imageView.setImageData(imageData)
                WKInterfaceDevice.currentDevice().addCachedImageWithData(imageData, name: imageID)
            }
        } else {
            imageView.setImage(nil)
        }
    }

    /// This will purge the device cache of images no longer stored in the app.
    func syncImagesWithDeviceCache(){
        if let allEvents = SoonEvent.fetchUpcomingEventsFromContext(SoonPlatform.sharedPlatform().managedObjectContext) {
            let cacheKeysArray:[String] = (WKInterfaceDevice.currentDevice().cachedImages as NSDictionary).allKeys as! [String]
            let imagesOnDeviceSet:Set<String> = Set(cacheKeysArray)
            var imagesInDatabaseArray = allEvents.filter({ $0.imageID != nil ? true : false }).map({ $0.imageID! }) as [String]
            let imagesInDatabaseSet:Set<String> = Set(imagesInDatabaseArray)

            let imagesToPurge = imagesOnDeviceSet.subtract(imagesInDatabaseSet)
            let imagesToCache = imagesInDatabaseSet.subtract(imagesOnDeviceSet)
            for imageToPurgeID in imagesToPurge {
                WKInterfaceDevice.currentDevice().removeCachedImageWithName(imageToPurgeID)
            }
        } else {
            WKInterfaceDevice.currentDevice().removeAllCachedImages()
        }
        NSNotificationCenter.defaultCenter().postNotificationName(SoonInterfaceManagerDidSyncCacheNotification, object: nil)
    }
}