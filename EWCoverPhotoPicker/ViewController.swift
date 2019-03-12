//
//  ViewController.swift
//  EWCoverPhotoPicker
//
//  Created by Ethan.Wang on 2018/11/7.
//  Copyright © 2018 Ethan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let takePhotoButton: UIButton = {
        let button = UIButton(frame: CGRect(x: (UIScreen.main.bounds.size.width - 150) / 2, y: 100, width: 150, height: 50))
        button.setTitle("调用相机", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIColor.gray
        button.addTarget(self, action: #selector(onClickTakePhotoButton), for: .touchUpInside)
        return button
    }()

    let showImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 200, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.width * 1.5))
        imageView.contentMode = .center
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(takePhotoButton)
        self.view.addSubview(showImageView)
        // Do any additional setup after loading the view, typically from a nib.
    }

    @objc func onClickTakePhotoButton() {
        let vc = EWPhotoPickerViewController()
        vc.delegate = self
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }

}

extension ViewController: EWPhotoFinishDelegate {
    func photo(_ viewController: EWPhotoShowViewController, didFinished photo: UIImage) {
        viewController.navigationController?.dismiss(animated: true, completion: {
            self.showImageView.image = photo
        })
    }

}
