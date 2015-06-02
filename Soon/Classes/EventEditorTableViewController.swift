//
//  EventEditorTableViewController.swift
//  Soon
//
//  Created by Ben Sandofsky on 4/25/15.
//  Copyright (c) 2015 Chroma Noir. All rights reserved.
//

import UIKit
import SoonPlatform

let EDITOR_EDIT_SEGUE_IDENTIFER = "com.chromanoir.edit"
let EDITOR_COMPOSE_SEGUE_IDENTIFER = "com.chromanoir.compose"

protocol EventEditorTableViewControllerDelegate: class {
    func eventEditorController(controller:EventEditorTableViewController, didSaveEvent event:SoonEvent)
    func eventEditorController(controller:EventEditorTableViewController, didCancelEditingEvent event:SoonEvent)
}

class EventEditorTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    weak var delegate:EventEditorTableViewControllerDelegate?
    var soonEvent:SoonEvent!

    @IBOutlet weak var attachedImageImageView: UIImageView!
    @IBOutlet weak var attachedImageButton: UIButton!
    @IBAction func didTapAddImageButton(sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        self.presentViewController(imagePicker, animated: true) { }
    }

    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!

    @IBAction func didTapSave(sender: UIBarButtonItem) {
        delegate?.eventEditorController(self, didSaveEvent: soonEvent)
    }

    @IBAction func didTapCancel(sender: UIBarButtonItem) {
        NSLog("Tapped Cancel")
        delegate?.eventEditorController(self, didCancelEditingEvent: soonEvent)
    }

    override func viewDidLoad() {
        attachedImageImageView.layer.borderColor = self.view.tintColor.CGColor
        attachedImageImageView.layer.borderWidth = 1.0
        attachedImageImageView.layer.cornerRadius = 3.0
        attachedImageImageView.clipsToBounds = true
        attachedImageImageView.tintColor = UIColor(white: 0.90, alpha: 1.0)
        attachedImageImageView.image = soonEvent.image ?? UIImage(named: "default_poster")
        self.nameTextField.text = soonEvent.name
        self.datePicker.date = soonEvent.date ?? NSDate(timeIntervalSinceNow: 60 * 60 * 24 * 7)
        nameTextField.addTarget(self, action: "nameFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        datePicker.addTarget(self, action: "datePickerDidChange:", forControlEvents: .ValueChanged)
        _updateEditPrompt()
        _updateCountdown()
    }

    func nameFieldDidChange(sender:UITextField){
        self.soonEvent.name = nameTextField.text
    }

    func datePickerDidChange(sender:UIDatePicker){
        NSLog("Date: \(datePicker.date)")
        self.soonEvent.date = datePicker.date
        _updateCountdown()
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.dismissViewControllerAnimated(true) {
            if image != nil {
                self.soonEvent.image = image
                self.soonEvent.imageID = NSUUID().UUIDString
                self.attachedImageImageView.image = image
            } else {
                NSLog("No image picked")
            }
            self._updateEditPrompt()
        }
    }

    private func _updateCountdown(){
        self.countdownLabel.text = soonEvent.generateCountdownText() ?? ""
    }

    private func _updateEditPrompt(){
        if soonEvent.image != nil {
            self.attachedImageButton.setTitle("Change", forState: .Normal)
        } else {
            self.attachedImageButton.setTitle("Add Photo", forState: .Normal)
        }
    }

}
