//
//  GlanceController.swift
//  Soon WatchKit Extension
//
//  Created by Ben Sandofsky on 4/26/15.
//  Copyright (c) 2015 Chroma Noir. All rights reserved.
//

import WatchKit
import Foundation
import SoonPlatform

class GlanceController: WKInterfaceController {

    @IBOutlet weak var eventImage: WKInterfaceImage!
    @IBOutlet weak var nameLabel: WKInterfaceLabel!
    @IBOutlet weak var countdownLabel: WKInterfaceLabel!

    private func _updateNextEvent() {
        let ctx = SoonPlatform.sharedPlatform().managedObjectContext
        if let event = SoonEvent.fetchSoonestEventFromContext(ctx, favorited:true) ?? SoonEvent.fetchSoonestEventFromContext(ctx) {
            nameLabel.setText(event.name)
            countdownLabel.setText(event.generateCountdownText() ?? "")
            InterfaceManager.sharedIntefaceManager().updateInterfaceImage(eventImage, withEvent: event)
        } else {
            nameLabel.setText("There are no upcoming events")
            countdownLabel.setText(nil)
            eventImage.setImageData(nil)
        }
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataStoreDidUpdate:", name: SoonEventsDatastoreDidUpdateNotification, object: nil)
        InterfaceManager.sharedIntefaceManager().syncImagesWithDeviceCache()
        _updateNextEvent()
    }

    func dataStoreDidUpdate(notification: NSNotification){
        _updateNextEvent()
    }

    override func willActivate() {
        super.willActivate()
        NSLog("Glance activated")
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
