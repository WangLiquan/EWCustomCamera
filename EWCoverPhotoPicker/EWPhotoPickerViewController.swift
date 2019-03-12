//
//  EWPhotoPickerViewController.swift
//  EWCoverPhotoPicker
//
//  Created by Ethan.Wang on 2018/11/7.
//  Copyright © 2018 Ethan. All rights reserved.
//

import UIKit
import AVFoundation

class EWPhotoPickerViewController: UIViewController {
    public weak var delegate: EWPhotoFinishDelegate? ///结束回调代理
    /// AVCaptureSession是AVFoundation的核心类,用于捕捉视频和音频,协调视频和音频的输入和输出流.
    private let captureSession = AVCaptureSession()
    /// 镜头采集
    private var captureDevice:AVCaptureDevice!
    /// 拍照状态,在相机调用时AVCaptureVideoDataOutputSampleBufferDelegate代理方法在不停调用,所以我们可以通过修改拍照状态bool值来执行拍照动作
    private var takePhoto = false
    /// 遮挡在选中imageView上层的半透明View
    private let overlayView: UIView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        view.backgroundColor = UIColor.black
        view.alpha = 0.5
        view.isUserInteractionEnabled = false
        return view
    }()
    /// 中心透明View
    private let clearView: UIView = {
        let view = UIView(frame: CGRect(x: 0 , y: (UIScreen.main.bounds.size.height - UIScreen.main.bounds.size.width) / 2, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.width))
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.yellow.cgColor
        return view
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// 先添加相机预览,之后在上面添加view蒙层
        drawCamera()
        drawCoverView()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "拍照", style: .plain, target: self, action: #selector(onClickCamera))
    }

    private func drawCoverView() {
        self.view.addSubview(overlayView)
        self.view.addSubview(clearView)
        let maskLayer = CAShapeLayer()
        let path = CGMutablePath()
        // 裁切View左侧side
        path.addRect(CGRect(x: 0, y: 0, width: self.clearView.frame.origin.x, height: self.overlayView.frame.size.height))
        // 裁切View右侧side
        path.addRect(CGRect(
            x: self.clearView.frame.origin.x + self.clearView.frame.size.width, y: 0, width: self.overlayView.frame.size.width - self.clearView.frame.origin.x - self.clearView.frame.size.width, height: self.overlayView.frame.size.height))
        // 裁切View上方side
        path.addRect(CGRect(x: 0, y: 0, width: self.overlayView.frame.size.width, height: self.clearView.frame.origin.y))
        // 裁切View下方side
        path.addRect(CGRect(x: 0, y: self.clearView.frame.origin.y + self.clearView.frame.size.height, width: self.overlayView.frame.size.width, height: self.overlayView.frame.size.height - self.clearView.frame.origin.y + self.clearView.frame.size.height))
        maskLayer.path = path
        /// 修改overlayView.将裁切View区域空白出来
        self.overlayView.layer.mask = maskLayer
        path.closeSubpath()
    }
    private func drawCamera() {
        /// SessionPreset,用于设置output输出流的bitrate或者说画面质量
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        /// 获取输入设备,builtInWideAngleCamera是通用相机,AVMediaType.video代表视频媒体,front表示前置摄像头,如果需要后置摄像头修改为back
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices
        /// 获取前置摄像头
        captureDevice = availableDevices.first
        beginSession()
    }

    @objc private func onClickCamera() {
        takePhoto = true
    }
    /// 开始相机功能
    private func beginSession() {
        captureSession.beginConfiguration()
        do {
            /// 将前置摄像头作为session的input输入流
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput)
        } catch {
            print(error.localizedDescription)
        }
        /// 设定视频预览层,也就是相机预览layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer)
        previewLayer.frame = self.view.layer.frame
        /// 相机页面展现形式
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill /// 拉伸充满frame
        /// 设定输出流
        let dataOutput = AVCaptureVideoDataOutput()
        /// 指定像素格式
        dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString):NSNumber(value:kCVPixelFormatType_32BGRA)] as [String : Any]
        /// 是否直接丢弃处理旧帧时捕获的新帧,默认为True,如果改为false会大幅提高内存使用
        dataOutput.alwaysDiscardsLateVideoFrames = true
        /// 开新线程进行输出流代理方法调用
        let queue = DispatchQueue(label: "com.brianadvent.captureQueue")
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        /// 将输出流加入session
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        /// beginConfiguration()和commitConfiguration()方法中的修改将在commit时同时提交
        captureSession.commitConfiguration()
        captureSession.startRunning()

    }
    /// 根据CMSampleBuffer媒体文件获取相片
    private func getImageFromSampleBuffer (buffer:CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .up)
            }
        }
        return nil
    }
    /// 停止session运行
    private func stopCaptureSession () {
        self.captureSession.stopRunning()
        /// 将输入源删除
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                self.captureSession.removeInput(input)
            }
        }
    }

}
/// 相册输出流代理
extension EWPhotoPickerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    /// 输出流代理方法,实时调用
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        /// 判断takePhoto状态,如果为True代表执行拍照动作
        if takePhoto {
            takePhoto = false
            /// 获取预览photo并将其传到相片预览页
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
}
