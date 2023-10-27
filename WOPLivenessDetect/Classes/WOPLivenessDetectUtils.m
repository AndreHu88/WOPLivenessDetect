//
//  DetectionUtils.m
//  FaceDetection
//
//  Created by Jack on 2023/10/20.
//

#import "WOPLivenessDetectUtils.h"
#import <Accelerate/Accelerate.h>


@interface WOPLivenessDetectUtils ()

@end

@implementation WOPLivenessDetectUtils

#pragma mark - Life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

/** 是否是人脸 */
+ (BOOL)isFacing:(MLKFace *)face {
    
    BOOL isFacing = face.headEulerAngleZ < 25.f && face.headEulerAngleZ > -25.f &&
    face.headEulerAngleY < 60.f && face.headEulerAngleY > -60.f &&
    face.headEulerAngleX < 40.f && face.headEulerAngleX > -40.f;
    
    return isFacing;
}

/** 是否张嘴 */
+ (BOOL)isMouthOpened:(MLKFace *)face {
    
    MLKVisionPoint *left = [face landmarkOfType:MLKFaceLandmarkTypeMouthLeft].position;
    MLKVisionPoint *right = [face landmarkOfType:MLKFaceLandmarkTypeMouthRight].position;
    MLKVisionPoint *bottom = [face landmarkOfType:MLKFaceLandmarkTypeMouthBottom].position;
    
    if (!left || !right || !bottom) {
        return NO;
    }
    
    // 计算三个点之间的距离的平方
    CGFloat a2 = [self lengthSquareBetweenPoint:right andPoint:bottom];
    CGFloat b2 = [self lengthSquareBetweenPoint:left andPoint:bottom];
    CGFloat c2 = [self lengthSquareBetweenPoint:left andPoint:right];
    
    // 计算三个边的长度
    CGFloat a = sqrt(a2);
    CGFloat b = sqrt(b2);
    
    // 根据余弦定理计算夹角 gamma
    CGFloat gamma = acos((a2 + b2 - c2) / (2 * a * b));
    
    // 将弧度转换为角度
    CGFloat gammaDeg = gamma * 180 / M_PI;
    
    return gammaDeg < 120.0;
}

+ (CGFloat)lengthSquareBetweenPoint:(MLKVisionPoint *)point1 andPoint:(MLKVisionPoint *)point2 {
    CGFloat dx = point1.x - point2.x;
    CGFloat dy = point1.y - point2.y;
    return dx * dx + dy * dy;
}

// 高斯模糊
+ (UIImage *)blurImage:(UIImage *)image blur:(CGFloat)blur {
    // 模糊度越界
    if (blur < 0.f || blur > 1.f) {
        blur = 0.5f;
    }
    
    int boxSize = (int)(blur * 200);
    boxSize = 20;
    boxSize = boxSize - (boxSize % 2) + 1;
    
    CGImageRef img = image.CGImage;
    
    vImage_Buffer inBuffer, outBuffer, rgbOutBuffer;
    vImage_Error error;
    
    void *pixelBuffer, *convertBuffer;
    
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    
    convertBuffer = malloc( CGImageGetBytesPerRow(img) * CGImageGetHeight(img) );
    rgbOutBuffer.width = CGImageGetWidth(img);
    rgbOutBuffer.height = CGImageGetHeight(img);
    rgbOutBuffer.rowBytes = CGImageGetBytesPerRow(img);
    rgbOutBuffer.data = convertBuffer;
    
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    inBuffer.data = (void *)CFDataGetBytePtr(inBitmapData);
    
    pixelBuffer = malloc( CGImageGetBytesPerRow(img) * CGImageGetHeight(img) );
    
    if (pixelBuffer == NULL) {
        NSLog(@"No pixelbuffer");
    }
    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    void *rgbConvertBuffer = malloc( CGImageGetBytesPerRow(img) * CGImageGetHeight(img) );
    vImage_Buffer outRGBBuffer;
    outRGBBuffer.width = CGImageGetWidth(img);
    outRGBBuffer.height = CGImageGetHeight(img);
    outRGBBuffer.rowBytes = CGImageGetBytesPerRow(img);//3
    outRGBBuffer.data = rgbConvertBuffer;
    
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    //    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    const uint8_t mask[] = {2, 1, 0, 3};
    
    vImagePermuteChannels_ARGB8888(&outBuffer, &rgbOutBuffer, mask, kvImageNoFlags);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(rgbOutBuffer.data,
                                             rgbOutBuffer.width,
                                             rgbOutBuffer.height,
                                             8,
                                             rgbOutBuffer.rowBytes,
                                             colorSpace,
                                             kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    //clean up
    CGContextRelease(ctx);
    
    free(pixelBuffer);
    free(convertBuffer);
    free(rgbConvertBuffer);
    CFRelease(inBitmapData);
    
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    
    return returnImage;
}


@end
