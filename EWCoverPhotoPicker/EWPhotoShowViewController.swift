//
//  EWPhotoShowViewController.swift
//  EWCoverPhotoPicker
//
//  Created by Ethan.Wang on 2018/11/7.
//  Copyright © 2018 Ethan. All rights reserved.
//

import UIKit
/// 预览后照片返回协议
@objc public protocol EWPhotoFinishDelegate : NSObjectProtocol {
    func photo(_ viewController: EWPhotoShowViewController, didFinished photo: UIImage)
}
open class EWPhotoShowViewController: UIViewController {
    public weak var delegate: EWPhotoFinishDelegate?
    public let photoShowImageView: UIImageView = {
        let imageView = UIImageView(frame: UIScreen.main.bounds)
        imageView.contentMode = .center
        return imageView
    }()

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(photoShowImageView)
        self.view.backgroundColor = UIColor.black
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "完成", style: .plain, target: self, action: #selector(onClickCompleteButton))
    }

    @objc private func onClickCompleteButton() {
        if delegate != nil {
            if self.delegate!.responds(to: #selector(EWPhotoFinishDelegate.photo(_:didFinished:))) {
                self.delegate!.photo(self, didFinished: self.photoShowImageView.image!)
            }
        }
    }
}
