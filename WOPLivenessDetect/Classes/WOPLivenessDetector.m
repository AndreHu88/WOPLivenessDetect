//
//  LivenessDetector.m
//  FaceDetection
//
//  Created by Jack on 2023/10/20.
//

#import "WOPLivenessDetector.h"

@interface WOPLivenessDetector ()

@property (nonatomic, strong) NSArray<id<WOPLivenessDetectTaskDelegate>> *tasksArray;

@property (nonatomic, assign) NSInteger taskIndex;

@property (nonatomic, assign) NSInteger lastTaskIndex;

@property (nonatomic, assign) BOOL detectComplete;



@end

@implementation WOPLivenessDetector

#pragma mark - Life cycle
- (instancetype)initWithTasks:(NSArray<id<WOPLivenessDetectTaskDelegate>> *)tasksArray {
    self = [super init];
    if (self) {
        self.lastTaskIndex = -1;
        self.tasksArray = tasksArray;
    }
    return self;
}

- (void)startDetectionWithSampleBuffer:(CMSampleBufferRef)sampleBuffer
                        detectionFrame:(CGRect)detectionFrame
                          preViewLayer:(nonnull AVCaptureVideoPreviewLayer *)preViewLayer {
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CGFloat imageWidth = CVPixelBufferGetWidth(imageBuffer);
    CGFloat imageHeight = CVPixelBufferGetHeight(imageBuffer);
    
    
    MLKVisionImage *versionImage = [[MLKVisionImage alloc] initWithBuffer:sampleBuffer];
    UIImageOrientation orientation = [self imageOrientationFromDeviceOrientation: UIDevice.currentDevice.orientation
                                                                  cameraPosition: AVCaptureDevicePositionFront];
    
    UIImage *image = [self imageFromSampleBuffer: sampleBuffer orientation: orientation];

    versionImage.orientation = orientation;
    
    MLKFaceDetectorOptions *options = [[MLKFaceDetectorOptions alloc] init];
    options.performanceMode = MLKFaceDetectorPerformanceModeAccurate;
    options.landmarkMode = MLKFaceDetectorLandmarkModeAll;
    options.classificationMode = MLKFaceDetectorClassificationModeAll;
    options.minFaceSize = 0.3;
    
    MLKFaceDetector *faceDetector = [MLKFaceDetector faceDetectorWithOptions:options];
    [faceDetector processImage:versionImage
                    completion:^(NSArray<MLKFace *> *faces,
                                 NSError *error) {
        
        [self handleFaces: faces
               imageWidth: imageWidth
              imageHeight: imageHeight
           detectionFrame: detectionFrame
             preViewLayer: preViewLayer
             currentImage: image];
    }];
}

- (void)handleFaces:(NSArray<MLKFace *> *)faces 
         imageWidth:(CGFloat)imageWidth
        imageHeight:(CGFloat)imageHeight
     detectionFrame:(CGRect)detectionFrame
       preViewLayer:(nonnull AVCaptureVideoPreviewLayer *)preViewLayer
       currentImage:(UIImage *)currentImage {
    
    if (_taskIndex >= _tasksArray.count || _detectComplete) {
        return;
    }
    
    id<WOPLivenessDetectTaskDelegate> task = self.tasksArray[self.taskIndex];
    if (_taskIndex != _lastTaskIndex) {
        
        _lastTaskIndex = _taskIndex;
        [task startWithFace: faces.firstObject];
        if (self.delegate && [self.delegate respondsToSelector: @selector(detectorStartWithTask:)]) {
            [self.delegate detectorStartWithTask: task];
        }
    }
    
    // 只有一张人脸
    if (faces.count == 1) {
        
        MLKFace *face = faces[0];
        CGRect faceRectCoordinates = CGRectMake(face.frame.origin.x / imageWidth, face.frame.origin.y / imageHeight,
                   face.frame.size.width / imageWidth, face.frame.size.height / imageHeight);
        
        // 获取人脸的frame
        CGRect standardizedFaceRect = CGRectStandardize([preViewLayer rectForMetadataOutputRectOfInterest: faceRectCoordinates]);
        
        // 获取人脸相对window的frame
        CGRect faceRectInWindow = [preViewLayer convertRect: standardizedFaceRect toLayer: [UIApplication sharedApplication].keyWindow.layer];
        
        // 计算人脸是否在识别框
        CGFloat overlapScale = [self overlapScaleBetweenRect: faceRectInWindow detectionRect: detectionFrame];
     
        if (task.isTimeout) {
            [self changeTaskError: task errorCode: WOPLivenessDetectorErrorTimeout];
            [self reset];
        }
        else if (overlapScale < 0.3) {
            // 移动人脸到框内
            [self changeTaskError: task errorCode: WOPLivenessDetectorErrorNotInDetectRect];
            return;
        }
        else if (overlapScale < 0.6) {
            // 靠近一些
            [self changeTaskError: task errorCode: WOPLivenessDetectorErrorFaceFast];
            return;
        }
        
        if ([task processWithFace: face]) {
            
            BOOL isLastTask = _taskIndex == (self.tasksArray.count - 1);
            if (self.delegate && [self.delegate respondsToSelector: @selector(detectorCompletedWithTask:isLastTask:resultImage:)]) {
                
                [self.delegate detectorCompletedWithTask: task
                                              isLastTask: isLastTask
                                             resultImage: currentImage];
            }
            
            if (isLastTask) {
                [self reset];
                self.detectComplete = true;
            }
            else {
                _taskIndex++;
            }
            
        }
        else {
            if (self.delegate && [self.delegate respondsToSelector: @selector(detectorProcessingWithTask:)]) {
                [self.delegate detectorProcessingWithTask: task];
            }
        }
    }
    else if (faces.count <= 0) {
        
        if (task.isTimeout) {
            [self changeTaskError: task errorCode: WOPLivenessDetectorErrorTimeout];
        }
        else {
            [self changeTaskError: task errorCode: WOPLivenessDetectorErrorNoFace];
        }
        return;
    }
    else {
        
        [self changeTaskError: task errorCode: WOPLivenessDetectorErrorMultiFace];
      
        return;
    }
}

/** 重置人脸识别 */
- (void)reset {
    
    self.taskIndex = 0;
    self.lastTaskIndex = -1;
    self.detectComplete = false;
}

#pragma mark - Private Method
- (void)changeTaskError:(id<WOPLivenessDetectTaskDelegate>)task errorCode:(WOPLivenessDetectorError)errorCode {
    
    if (self.delegate && [self.delegate respondsToSelector: @selector(detectorFailedWithTask:errorCode:)]) {
        [self.delegate detectorFailedWithTask: task errorCode: errorCode];
    }
}

- (CGFloat)overlapScaleBetweenRect:(CGRect)faceRect detectionRect:(CGRect)detectionRect {
    
    // 计算 rect1 和 rect2 的交集
    CGRect intersectionRect = CGRectIntersection(faceRect, detectionRect);
    
    // 计算交集的面积
    CGFloat areaIntersection = CGRectGetWidth(intersectionRect) * CGRectGetHeight(intersectionRect);
    
    // 计算 faceRect 的面积
    CGFloat detectionArea = CGRectGetWidth(detectionRect) * CGRectGetHeight(detectionRect);
    
    // 计算重叠比例
    CGFloat overlapScale = areaIntersection / detectionArea;
    
    return overlapScale;
}

- (NSMutableArray *)sortedRandomArrayByArray:(NSArray *)array{
    
    NSMutableArray *randomArray = [[NSMutableArray alloc] init];
    while (randomArray.count != array.count) {
        int x = arc4random() % array.count;
        id obj = array[x];
        if(![randomArray containsObject:obj]){
            [randomArray addObject:obj];
        }
    }
    return randomArray;
}

- (UIImageOrientation)imageOrientationFromDeviceOrientation:(UIDeviceOrientation)deviceOrientation
                                             cameraPosition:(AVCaptureDevicePosition)cameraPosition {
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            return cameraPosition == AVCaptureDevicePositionFront ? UIImageOrientationLeftMirrored
            : UIImageOrientationRight;
            
        case UIDeviceOrientationLandscapeLeft:
            return cameraPosition == AVCaptureDevicePositionFront ? UIImageOrientationDownMirrored
            : UIImageOrientationUp;
        case UIDeviceOrientationPortraitUpsideDown:
            return cameraPosition == AVCaptureDevicePositionFront ? UIImageOrientationRightMirrored
            : UIImageOrientationLeft;
        case UIDeviceOrientationLandscapeRight:
            return cameraPosition == AVCaptureDevicePositionFront ? UIImageOrientationUpMirrored
            : UIImageOrientationDown;
        case UIDeviceOrientationUnknown:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            return UIImageOrientationUp;
    }
}

//- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
//    
//    if (!sampleBuffer) {
//        return nil;
//    }
//    
//    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    // 锁定pixel buffer的基地址
//    CVPixelBufferLockBaseAddress(imageBuffer, 0);
//    
//    // 得到pixel buffer的基地址
//    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
//    
//    // 得到pixel buffer的行字节数
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
//    // 得到pixel buffer的宽和高
//    size_t width = CVPixelBufferGetWidth(imageBuffer);
//    size_t height = CVPixelBufferGetHeight(imageBuffer);
//    
//    // 创建一个依赖于设备的RGB颜色空间
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    
//    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
//    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
//                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
//    // 根据这个位图context中的像素数据创建一个Quartz image对象
//    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
//    // 解锁pixel buffer
//    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
//    
//    // 释放context和颜色空间
//    CGContextRelease(context);
//    CGColorSpaceRelease(colorSpace);
//    
//    // 用Quartz image创建一个UIImage对象image
//    UIImage *image = [UIImage imageWithCGImage:quartzImage];
//    
//    // 释放Quartz image对象
//    CGImageRelease(quartzImage);
//    
//    
//    return image;
//}

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer orientation:(UIImageOrientation)orientation {
    
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);

    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    //释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // 用Quartz image创建一个UIImage对象image
//    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation: orientation];
    
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    
    return [self fixImageOrientation: image];
    
}

- (UIImage *)fixImageOrientation:(UIImage *)originImage {
    
    if (originImage.imageOrientation == UIImageOrientationUp) {
        return originImage; // 图像方向正确，不需要修复
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (originImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, originImage.size.width, originImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, originImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, originImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (originImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, originImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, originImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    CGContextRef ctx = CGBitmapContextCreate(NULL, originImage.size.width, originImage.size.height,
                                             CGImageGetBitsPerComponent(originImage.CGImage), 0,
                                             CGImageGetColorSpace(originImage.CGImage),
                                             CGImageGetBitmapInfo(originImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    
    switch (originImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0, 0, originImage.size.height, originImage.size.width), originImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, originImage.size.width, originImage.size.height), originImage.CGImage);
            break;
    }
    
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *fixedImage = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return fixedImage;
}











@end
