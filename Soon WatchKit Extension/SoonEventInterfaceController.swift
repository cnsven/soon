//
//  SoonEventInterfaceController.swift
//  Soon
//
//  Created by Ben Sandofsky on 5/8/15.
//  Copyright (c) 2015 Chroma Noir. All rights reserved.
//

import WatchKit
import SoonPlatform

class SoonEventInterfaceController:WKInterfaceController {

    var soonEvent:SoonEvent!

    @IBOutlet weak var favoriteImage: WKInterfaceImage!

    @IBOutlet weak var nameLabel: WKInterfaceLabel!
    @IBOutlet weak var countdownLabel: WKInterfaceLabel!
    @IBOutlet weak var attachmentImageView: WKInterfaceImage!
    @IBOutlet weak var favoriteImageGroup: WKInterfaceGroup!

    @IBAction func didTapFavorite() {
        if self.soonEvent.isFavorite {
            InterfaceManager.sharedIntefaceManager().unfavoriteEvent(self.soonEvent) { success, errorOrNil in
                NSLog("response: \(success)")
            }
        } else {
            InterfaceManager.sharedIntefaceManager().favoriteEvent(self.soonEvent) {
                success, errorOrNil in
                NSLog("response: \(success)")
            }
        }
    }



    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataStoreDidUpdate:", name: SoonEventsDatastoreDidUpdateNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "imageCacheDidSync:", name: SoonInterfaceManagerDidSyncCacheNotification, object: nil)
        soonEvent = context as! SoonEvent
    }

    override func willActivate() {
        _updateforEvent()
    }

    private func _updateforEvent(){
        nameLabel.setText(soonEvent.name)
        countdownLabel.setText(soonEvent.generateCountdownText() ?? "")
        _updateImageForEvent()
        if soonEvent.isFavorite {
            favoriteImageGroup.setHidden(false)
        } else {
            favoriteImageGroup.setHidden(true)
        }
    }

    private func _updateImageForEvent(){
        InterfaceManager.sharedIntefaceManager().updateInterfaceImage(attachmentImageView, withEvent: soonEvent)
    }

    func dataStoreDidUpdate(notification: NSNotification){
        
    }

    func imageCacheDidSync(notification:NSNotification){
        _updateImageForEvent()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}