//
//  PictureViewController.swift
//  ChitChat
//
//  Created by next-shot on 5/8/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit

class ShareableImageView : UIImageView {
    weak var ctrler: PictureViewController?
    
    override init(image: UIImage?) {
        super.init(image: image)
        
        let tapGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ShareableImageView.handleTapGesture))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func handleTapGesture(sender: UILongPressGestureRecognizer) {
        if( sender.state == .ended && self.becomeFirstResponder() ) {
            let sharedMenu = UIMenuController.shared
            let loc = sender.location(in: self)
            sharedMenu.setTargetRect(CGRect(origin: loc, size: CGSize(width: 0, height: 0)), in: self)
            sharedMenu.menuItems = [UIMenuItem(title: "Save", action: #selector(ShareableImageView.saveImage))]
            sharedMenu.setMenuVisible(true, animated: true)
        }
    }
    
    override var canBecomeFirstResponder : Bool {
        get {
           return true
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if( action == #selector(UIResponderStandardEditActions.copy(_:)) ) {
            return true
        }
        if( action == #selector(ShareableImageView.saveImage) ) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    override func copy(_ sender: Any?) {
        UIPasteboard.general.image = self.image
    }
    
    @objc func saveImage(_sender: Any?) {
        UIImageWriteToSavedPhotosAlbum(self.image!, self, #selector(ShareableImageView.handleSaveToPhotoAlbumError), nil)
    }
    
    @objc func handleSaveToPhotoAlbumError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if( error != nil ) {
            let ac = UIAlertController(title: "Save error", message: error?.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            ctrler?.present(ac, animated: true, completion: nil)
        }
    }
}

class PictureViewController : UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: ShareableImageView!
    @IBOutlet weak var imageCaption: UILabel!
    
    var activityView: UIActivityIndicatorView?
    var message : Message?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if( message != nil && message!.largeImage == nil ) {
            
            activityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            
            model.getMessageLargeImage(message: message!, completion: {
                DispatchQueue.main.async(execute: {
                   if( self.message!.largeImage != nil ) {
                        self.imageView.image = self.message!.largeImage
                        self.initializeScale()
                        self.imageView.setNeedsDisplay()
                    }
                    if( self.activityView != nil ) {
                        self.activityView!.stopAnimating()
                        self.activityView!.removeFromSuperview()
                        self.activityView = nil
                    }
                })
            })
            imageView.image = message?.image
        } else {
            imageView.image = message?.largeImage
        }
        scrollView.delegate = self
        
        imageView.ctrler = self
        imageCaption.text = message?.text
        
        let tapGestureRecognizer = UILongPressGestureRecognizer(target: imageView, action: #selector(ShareableImageView.handleTapGesture))
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        initializeScale()
        
        if( activityView != nil ) {
            activityView!.color = UIColor.blue
            activityView!.center = self.view.center
            activityView!.startAnimating()
            self.view.addSubview(activityView!)
        }

        super.viewWillAppear(animated)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func initializeScale() {
        let minScaleX = scrollView.frame.size.width / imageView.image!.size.width
        let minScaleY = scrollView.frame.size.height / imageView.image!.size.height
        scrollView.minimumZoomScale = min(minScaleX, minScaleY)
        scrollView.maximumZoomScale = 3.0;
        
        scrollView.contentSize = imageView.image!.size
        scrollView.zoomScale = min(minScaleX, minScaleY)
    }
}
