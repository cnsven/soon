//
//  SoonEvent.swift
//  Soon
//
//  Created by Ben Sandofsky on 4/25/15.
//  Copyright (c) 2015 Chroma Noir. All rights reserved.
//

import UIKit
import CoreData

public let EVENT_ENTITY_NAME = "SoonEvent"

@objc(SoonEvent)

/// The primary entity that makes up the app.
public class SoonEvent: NSManagedObject {

    /// The name of the upcoming event.
    @NSManaged public var name:String?
    /// A unique ID for use as an image cache key. Whenever a new image is assigned to the event, a new UUID is generated and assigned to this property. It's a bad idea to set this value yourself.
    @NSManaged public var imageID:String?

    /// The date the event will take place.
    @NSManaged public var date:NSDate?

    @NSManaged private var imageData:NSData?
    /// Image data scaled down for use in a watchkit extension. You should perform one more conversion operation within the extension before assigning it to image views.
    @NSManaged public var watchExtensionImageData:NSData?

    @NSManaged private var favoriteNumber:NSNumber?

    public var isFavorite:Bool {
        get {
            return favoriteNumber?.boolValue ?? false
        }
        set(value){
            favoriteNumber = NSNumber(bool: value)
        }
    }

    private func updateWatchExtensionImageData() {
        if let fullSizedImage = self.image {
            watchExtensionImageData = UIImagePNGRepresentation(fullSizedImage.bks_imageScaledToWidth(WATCHKIT_IMAGE_WIDTH, newScale: WATCHKIT_IMAGE_SCALE))
        } else {
            watchExtensionImageData = nil
        }
    }

    /// Generates a human readable date.
    public func generateFormattedDate() -> String {
        if date != nil {
            return _dateFormatter.stringFromDate(date!)
        } else {
            return ""
        }
    }

    private var _imageCache:UIImage?

    /// The image associated with the event.
    public var image:UIImage? {
        get {
            if _imageCache != nil {
                return _imageCache!
            } else {
                if imageData != nil {
                    _imageCache = UIImage(data: imageData!)
                    return _imageCache
                } else {
                    return nil
                }
            }
        }
        set(value){
            _imageCache = value
            if value != nil {
                self.imageData = UIImagePNGRepresentation(value!)
            } else {
                self.imageData = nil
            }
            updateWatchExtensionImageData()
        }
    }

    /// Generates the countdown to the event e.g. "5 Days from now."
    public func generateCountdownText() -> String? {
        if self.date == nil {
            return nil
        }
        let interval = Int(self.date!.timeIntervalSinceNow)
        let day = 60 * 60 * 24
        let hour = 60 * 60
        let minute = 60
        if interval > day {
            var days = interval / day
            if days == 1 {
                return "1 day"
            } else {
                return "\(days) days"
            }
        } else if interval > hour {
            var hours = interval / hour
            if hours == 1 {
                return "1 hour"
            } else {
                return "\(hours) hours"
            }
        } else {
            var minutes = interval / minute
            if minutes == 1 {
                return "1 minute"
            } else {
                return "\(minutes) minutes"
            }
        }
    }

    /// Returns the next upcoming event, for use in a watch Glance.
    public class func fetchSoonestEventFromContext(moc:NSManagedObjectContext, favorited favoritedOrNil:Bool? = nil) -> SoonEvent? {
        let fetch = NSFetchRequest(entityName: EVENT_ENTITY_NAME)
        fetch.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        fetch.fetchLimit = 1
        if let favorited = favoritedOrNil {
            fetch.predicate = NSPredicate(format: "favoriteNumber = %@", favorited)
        }
        var errorOrNil:NSError?
        if let results = moc.executeFetchRequest(fetch, error: &errorOrNil) {
            return results.first as! SoonEvent?
        } else {
            NSLog("Error: \(errorOrNil)")
            return nil
        }
    }

    /// Returns all upcoming events, for use in the main watch app.
    public class func fetchUpcomingEventsFromContext(moc:NSManagedObjectContext) -> [SoonEvent]? {
        let fetch = NSFetchRequest(entityName: EVENT_ENTITY_NAME)
        fetch.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        var fetchErrorOrNil:NSError?
        let resultsOrNil = moc.executeFetchRequest(fetch, error: &fetchErrorOrNil) as! [SoonEvent]?
        if let fetchError = fetchErrorOrNil {
            NSLog("FetchError: \(fetchError)")
        }
        return resultsOrNil
    }

    /// Returns resized image data, compressed as a JPEG, for efficiently sending image data to the watch.
    public func generateImageOptimizedForWatchWithWidth(watchWidth:CGFloat, scale:CGFloat) -> NSData {
        let imageForWatchKitExtension = UIImage(data: self.watchExtensionImageData!)!
        let scaledImage = imageForWatchKitExtension.bks_imageScaledToWidth(watchWidth, newScale:scale)
        return UIImageJPEGRepresentation(scaledImage, 0.8)
    }
}

// NSDateFormatter is notoriously slow to instance, so share one instance.
private let _dateFormatter:NSDateFormatter = {
    var formatter = NSDateFormatter()
    formatter.dateStyle = .LongStyle
    formatter.timeStyle = .NoStyle
    return formatter
}()

private let WATCHKIT_IMAGE_WIDTH:CGFloat = 200.0
private let WATCHKIT_IMAGE_SCALE:CGFloat = 2.0

extension UIImage {
    func bks_imageScaledToWidth(newWidth:CGFloat, newScale:CGFloat) -> UIImage {
        if self.size.width <= newWidth {
            return self
        }
        var newHeight = self.size.height / (self.size.width / newWidth)
        let s = CGSizeMake(newWidth, newHeight)
        UIGraphicsBeginImageContextWithOptions(s, false, newScale)
        self.drawInRect(CGRectMake(0, 0, s.width, s.height))
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return finalImage
    }
}