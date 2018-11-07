//
//  EWPhotoPickerViewController.swift
//  EWCoverPhotoPicker
//
//  Created by Ethan.Wang on 2018/11/7.
//  Copyright © 2018 Ethan. All rights reserved.
//

import UIKit
import AVFoundation

class EWPhotoPickerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    public var delegate: EWImageCropperDelegate? ///结束回调代理
    ///
    private let captureSession = AVCaptureSession()
    private var previewLayer:AVCaptureVideoPreviewLayer!
    private var captureDevice:AVCaptureDevice!
    private var takePhoto = false
    /// 遮挡在选中imageView上层的半透明View
    private let overlayView: UIView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        view.backgroundColor = UIColor.black
        view.alpha = 0.5
        view.isUserInteractionEnabled = false
        return view
    }()
    /// 裁切区域View
    private let cropView: UIView = {
        let view = UIView(frame: CGRect(x: 0 , y: (UIScreen.main.bounds.size.height - UIScreen.main.bounds.size.width) / 2, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.width))
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.yellow.cgColor
        return view
    }()
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareCamera()
        drawCoverView()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "拍照", style: .plain, target: self, action: #selector(onClickCamera))
    }
    @objc private func onClickCamera() {
        takePhoto = true
    }
    private func drawCoverView() {
        self.view.addSubview(overlayView)
        self.view.addSubview(cropView)
        let maskLayer = CAShapeLayer()
        let path = CGMutablePath()
        // 裁切View左侧side
        path.addRect(CGRect(x: 0, y: 0, width: self.cropView.frame.origin.x, height: self.overlayView.frame.size.height))
        // 裁切View右侧side
        path.addRect(CGRect(
            x: self.cropView.frame.origin.x + self.cropView.frame.size.width, y: 0, width: self.overlayView.frame.size.width - self.cropView.frame.origin.x - self.cropView.frame.size.width, height: self.overlayView.frame.size.height))
        // 裁切View上方side
        path.addRect(CGRect(x: 0, y: 0, width: self.overlayView.frame.size.width, height: self.cropView.frame.origin.y))
        // 裁切View下方side
        path.addRect(CGRect(x: 0, y: self.cropView.frame.origin.y + self.cropView.frame.size.height, width: self.overlayView.frame.size.width, height: self.overlayView.frame.size.height - self.cropView.frame.origin.y + self.cropView.frame.size.height))
        maskLayer.path = path
        /// 修改overlayView.将裁切View区域空白出来
        self.overlayView.layer.mask = maskLayer
        path.closeSubpath()
    }
    func prepareCamera() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices
        captureDevice = availableDevices.first
        beginSession()
    }
    func beginSession () {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput)
        }catch {
            print(error.localizedDescription)
        }
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer = previewLayer
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.layer.frame
        /// 相机页面展现形式
        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill /// 拉伸充满frame
        /// 修改拍出照片像素
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        captureSession.startRunning()
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString):NSNumber(value:kCVPixelFormatType_32BGRA)] as [String : Any]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        captureSession.commitConfiguration()
        let queue = DispatchQueue(label: "com.brianadvent.captureQueue")
        dataOutput.setSampleBufferDelegate(self, queue: queue)

    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if takePhoto {
            takePhoto = false
            if let image = self.getImageFromSampleBuffer(buffer: sampleBuffer) {
                DispatchQueue.main.async {
                    let photoShowVC = EWPhotoShowViewController()
                    photoShowVC.photoShowImageView.image = image
                    photoShowVC.delegate = self.delegate
                    self.navigationController?.pushViewController(photoShowVC, animated: true)
                    self.stopCaptureSession()
                }
            }
        }
    }
    func getImageFromSampleBuffer (buffer:CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .leftMirrored)
            }
        }
        return nil
    }
    func stopCaptureSession () {
        self.captureSession.stopRunning()
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                self.captureSession.removeInput(input)
            }
        }
    }

}
