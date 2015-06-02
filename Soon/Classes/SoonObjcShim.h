//
//  SoonObjcShim.h
//  Soon
//
//  Created by Ben Sandofsky on 5/5/15.
//  Copyright (c) 2015 Chroma Noir. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SoonObjcShim : NSObject
/** A private method that has to be exposed here for Swift to call it. Don't call this directly. */
+ (void)fireSoonSystemnotification;
@end

/**  The Darwin notification sent from the main iOS app when data is written to the database. Do not observe this property. Observe SoonEventsDatastoreDidUpdateNotification. */
extern const NSString *SoonSystemNotification;
