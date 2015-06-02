//
//  EventListTableViewController.swift
//  Soon
//
//  Created by Ben Sandofsky on 4/25/15.
//  Copyright (c) 2015 Chroma Noir. All rights reserved.
//

import UIKit
import CoreData
import SoonPlatform

private let CELL_IDENTIFER = "com.chromanoir.eventcell"

class EventListTableViewController: UITableViewController, EventEditorTableViewControllerDelegate, SoonEventListTableViewCellDelegate {
    var events:[SoonEvent] = Array()
    var managedObjectContext:NSManagedObjectContext!

    // MARK: Storyboards
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let nav = segue.destinationViewController as! UINavigationController
        let controller = nav.viewControllers.first! as! EventEditorTableViewController
        controller.delegate = self
        if segue.identifier == EDITOR_COMPOSE_SEGUE_IDENTIFER {
            controller.soonEvent = _generateNewEvent()
        } else if segue.identifier == EDITOR_EDIT_SEGUE_IDENTIFER {
            let cell = sender! as! UITableViewCell
            let indexPath = self.tableView.indexPathForCell(cell)!
            let event = self.events[indexPath.row]
            controller.soonEvent = event
        }
    }

    // MARK: TableView Editing
    @IBAction func didTapEdit(sender: UIBarButtonItem) {
        self.tableView.setEditing(true, animated: true)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "didTapFinishedEditing:")
    }

    func didTapFinishedEditing(sender:AnyObject){
        self.tableView.setEditing(false, animated: true)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Edit, target: self, action: "didTapEdit:")
    }

    private func _generateNewEvent() -> SoonEvent {
        let entity = NSEntityDescription.entityForName(EVENT_ENTITY_NAME, inManagedObjectContext: self.managedObjectContext)!
        let event = SoonEvent(entity: entity, insertIntoManagedObjectContext: nil)
        return event
    }

    // MARK: UIViewController Lifecycle

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        _refetchEvents()
        self.tableView.reloadData()
    }

    // MARK: Event Editor Delegate

    func eventEditorController(controller: EventEditorTableViewController, didCancelEditingEvent event: SoonEvent) {
        self.managedObjectContext.reset()
        _refetchEvents()
        self.tableView.reloadData()
        self.dismissViewControllerAnimated(true) { }
    }

    func eventEditorController(controller: EventEditorTableViewController, didSaveEvent event: SoonEvent) {
        if event.managedObjectContext == nil {
            self.managedObjectContext.insertObject(event)
        }
        var saveErrorOrNil:NSError?
        self.managedObjectContext.save(&saveErrorOrNil)
        if let saveError = saveErrorOrNil {
            NSLog("Error saving: \(saveError)")
        }
        _refetchEvents()
        self.tableView.reloadData()
        self.dismissViewControllerAnimated(true) { }
    }

    private func _refetchEvents(){
        if let results = SoonEvent.fetchUpcomingEventsFromContext((SoonPlatform.sharedPlatform().managedObjectContext)) {
            self.events = results
        }
    }

    // MARK: UITableView Delegate

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.events.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFER) as! SoonEventListTableViewCell
        let event = self.events[indexPath.row]
        cell.eventTitleLabel.text = event.name
        cell.eventSubtitleLabel.text = event.generateFormattedDate()
        cell.previewImageView.image = event.image ?? UIImage(named: "default_poster")
        cell.delegate = self
        cell.updateWithEvent(event)
        return cell
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle != UITableViewCellEditingStyle.Delete {
            return
        }
        let event = self.events[indexPath.row]
        self.managedObjectContext.deleteObject(event)
        var saveErrorOrNil:NSError?
        self.managedObjectContext.save(&saveErrorOrNil)
        if let saveError = saveErrorOrNil {
            NSLog("Error Saving: \(saveError)")
        } else {
            self._refetchEvents()
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }

    // MARK: Event Cell Delegate
    func didTapFavoriteButtonOnCell(cell: SoonEventListTableViewCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            NSLog("Tapped on index: \(indexPath.row)")
            let event = self.events[indexPath.row]
            event.isFavorite = !event.isFavorite
            cell.updateWithEvent(event)
            SoonPlatform.sharedPlatform().managedObjectContext.save(nil)
        } else {
            NSLog("Tapped on unknown cell")
        }
    }
}