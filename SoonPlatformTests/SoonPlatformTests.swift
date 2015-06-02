//
//  SoonPlatformTests.swift
//  SoonPlatformTests
//
//  Created by Ben Sandofsky on 4/28/15.
//  Copyright (c) 2015 Chroma Noir. All rights reserved.
//

import UIKit
import XCTest
import SoonPlatform
import CoreData

class SoonPlatformTests: XCTestCase {

    func testShouldCalculateSingularDate(){
        let entity = NSEntityDescription.entityForName(EVENT_ENTITY_NAME, inManagedObjectContext: SoonPlatform.sharedPlatform().managedObjectContext)
        let event = SoonEvent(entity: entity!, insertIntoManagedObjectContext: nil)

        event.date = NSDate(timeIntervalSinceNow: 25 * 60 * 60)
        let firstText = event.generateCountdownText()!
        XCTAssertEqual("1 day", firstText, "Failed to show the right countdown date: \(firstText)")

        event.date = NSDate(timeIntervalSinceNow: 49 * 60 * 60)
        let secondText = event.generateCountdownText()!
        XCTAssertEqual("2 days", secondText, "Failed to show the right countdown date: \(secondText)")
    }
    
}
