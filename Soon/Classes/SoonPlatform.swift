//
//  SoonPlatform.swift
//  Soon
//
//  Created by Ben Sandofsky on 4/26/15.
//  Copyright (c) 2015 Chroma Noir. All rights reserved.
//

import Foundation
import CoreData

/// The key for the action you wish to take when calling the main app. See `SoonPlatformAppAction` for valid values.
public let SoonPlatformAppActionKey = "SoonPlatformAppActionKey"

/// Contains the keys for actions to send app requests.
public enum SoonPlatformAppAction:String {
    /// Favorite an event
    case Favorite = "SoonPlatformAppAction.Favorite"
    /// Unfavorite an event
    case Unfavorite = "SoonPlatformAppAction.Unfavorite"
}

public let SoonPlatformEventArrayKey = "SoonPlatformEventArrayKey"
public let SoonPlatformEventIDKey = "SoonPlatformEventIDKey"

/// The keys contained in the app response dictionary.
public enum SoonPlatformReplyKeys:String {
    /// Success Status. Contains an `NSNumber` bool.
    case WasSuccessful = "SoonPlatformReplyKeys.WasSuccessful"
    /// In the event of failure, contains an error object.
    case Error = "SoonPlatformReplyKeys.Error"
}

private let PLATFORM_BUNDLE_IDENTIFIER = "com.chromanoir.SoonPlatform"
private let APP_GROUP_IDENTIFER = "group.com.chromanoir.soon"
private let LAST_WRITE_KEY = "LAST_WRITE_KEY"

private let SoonDataURL:NSURL = {
    return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
}()

private let _coordinator:NSPersistentStoreCoordinator = {
    let bundle = NSBundle(identifier: PLATFORM_BUNDLE_IDENTIFIER)!
    let modelURL = bundle.URLForResource("Soon", withExtension: "momd")!
    let model = NSManagedObjectModel(contentsOfURL: modelURL)!

    var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: model)
    let url = SoonDataURL.URLByAppendingPathComponent("Soon.sqlite")
    var error: NSError? = nil
    let options:[NSObject:AnyObject] = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption:true]
    do {
        try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options)
    } catch var error1 as NSError {
        error = error1
        coordinator = nil
        let finalError = generateCoreDataError(error!)
        NSLog("Unresolved error \(finalError), \(finalError.userInfo)")
        abort()
    } catch {
        fatalError()
    }
    
    return coordinator!
}()

/// A notification fired when the data store is updated. This might happen because your app was awakened after a write, or we receive a Darwin Notification. It will attempt to coalesce both events into this one notification.
public let SoonEventsDatastoreDidUpdateNotification = "SoonEventsDatastoreDidUpdateNotification"

public class SoonPlatform:NSObject {
    class public func sharedPlatform() -> SoonPlatform {
        return _sharedPlatform
    }

    public var managedObjectContext:NSManagedObjectContext
    private var userDefaults:NSUserDefaults
    private var lastNotification:NSDate

    override init(){
        managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        userDefaults = NSUserDefaults(suiteName: APP_GROUP_IDENTIFER)!
        lastNotification = NSDate()
        super.init()
        managedObjectContext.persistentStoreCoordinator = _coordinator
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didSave:", name:NSManagedObjectContextDidSaveNotification, object: managedObjectContext)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    public func _systemNotificationArrived(){
        if let lastWrite = (userDefaults.objectForKey(LAST_WRITE_KEY) as! NSDate?) {
            if lastWrite.compare(lastNotification) == NSComparisonResult.OrderedDescending {
                lastNotification = lastWrite
                postAppnotification()
            }
        }
    }
    private func postAppnotification(){
        NSNotificationCenter.defaultCenter().postNotificationName(SoonEventsDatastoreDidUpdateNotification, object: nil)
    }

    func didSave(sender:NSNotification){
        userDefaults.setObject(NSDate(), forKey: LAST_WRITE_KEY)
        userDefaults.synchronize()
        SoonObjcShim.fireSoonSystemnotification()
    }

    /// Favorite an event based on its Core Data URI. Useful for communicating between the extension and main app.
    /// - parameter eventURI: The Core Data URI for the event object.
    public func favoriteEventWithID(eventID:NSString) -> (Bool, NSError?){
        do {
            let object = try self.eventWithID(eventID)
            object.isFavorite = true
            try self.managedObjectContext.save()
            return (true, nil)
        } catch let error as NSError {
            return (false, error)
        }
    }

    public func eventWithID(eventID:NSString) throws -> SoonEvent {
        let fetch = NSFetchRequest(entityName: EVENT_ENTITY_NAME)
        fetch.predicate = NSPredicate(format: "eventID = %@", eventID)
        fetch.fetchLimit = 1
        do {
            let events = try self.managedObjectContext.executeFetchRequest(fetch)
            guard events.count > 0 else {
                throw NSError(domain: "com.chromanoir.soon", code: 404, userInfo: [NSLocalizedDescriptionKey:"Event not found with ID: \(eventID)"])
            }
            return events.first! as! SoonEvent
        } catch let error as NSError {
            throw error
        }
    }

    /// Unfavorite an event based on its Core Data URI. Useful for communicating between the extension and main app.
    /// - parameter eventID: The eventID of the event.
    public func unfavoriteEventWithID(eventID:NSString) -> (Bool, NSError?){
        do {
           let object = try self.eventWithID(eventID)
            object.isFavorite = false
            try self.managedObjectContext.save()
            return (true, nil)
        } catch let error as NSError {
            return (false, error)
        }
    }

    public func deleteAllEvents() throws {
        let fetchRequest = NSFetchRequest(entityName: EVENT_ENTITY_NAME)
        let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try self.managedObjectContext.executeRequest(batchDelete)
        } catch let error as NSError {
            throw error
        }   
    }

    public func ingestEventDictionary(dictionary:NSDictionary){
        let entity = NSEntityDescription.entityForName(EVENT_ENTITY_NAME, inManagedObjectContext: self.managedObjectContext)!
        let event = SoonEvent(entity: entity, insertIntoManagedObjectContext: self.managedObjectContext)
        event.name = dictionary[EventKeys.Name.rawValue] as? String
        event.eventID = dictionary[EventKeys.Id.rawValue] as? String
        event.imageData = dictionary[EventKeys.ImageData.rawValue] as? NSData
        event.date = dictionary[EventKeys.Date.rawValue] as? NSDate
    }
}

private let _sharedPlatform:SoonPlatform = SoonPlatform()
public let SoonPlatformErrorDomain = "com.chromanoir.soon.error"

private func generateCoreDataError(error:NSError) -> NSError {
    let failureReason = "There was an error creating or loading the application's saved data."
    var dict = [String: AnyObject]()
    dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
    dict[NSLocalizedFailureReasonErrorKey] = failureReason
    dict[NSUnderlyingErrorKey] = error
    return NSError(domain: SoonPlatformErrorDomain, code: SoonPlatformErrorCode.CoreDataError.rawValue, userInfo: dict)
}

public enum SoonPlatformErrorCode:Int {
    case InvalidAppRequestDictionary = 1
    case CoreDataError = 2
}