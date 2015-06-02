//
//  SoonObjcShim.m
//  Soon
//
//  Created by Ben Sandofsky on 5/5/15.
//  Copyright (c) 2015 Chroma Noir. All rights reserved.
//

#import "SoonObjcShim.h"
#import <SoonPlatform/SoonPlatform-Swift.h>

const NSString *SoonSystemNotification = @"com.chromanoir.soon.datastoreupdated";

void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
    [[SoonPlatform sharedPlatform] _systemNotificationArrived];
}

@implementation SoonObjcShim
+ (void)load
{
    [super load];
    [self registerSoonSystemObserver];
}
+ (void)registerSoonSystemObserver {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, (CFStringRef)SoonSystemNotification, nil, CFNotificationSuspensionBehaviorDrop);
}
+ (void)fireSoonSystemnotification {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)SoonSystemNotification, nil, nil, YES);
}
@end
