# EWCustomCoverCemara

一个带自定制蒙层的前置相机.
---

# 实现思路:

1. 新建一个ViewController,在其中使用AVFoundation框架中AVCaptureSession,AVCaptureVideoPreviewLayer,AVCaptureDevice实现前置相机功能.

2. 绘制自定义蒙层View,实现页面效果.

3. 遵循AVCaptureVideoDataOutputSampleBufferDelegate.实现拍照功能.

4. 新建ViewController实现photo预览

5. 使用protocol实现相片回调.
   

![效果图预览](https://github.com/WangLiquan/EWCoverPhotoPicker/raw/master/images/demonstration.gif)
