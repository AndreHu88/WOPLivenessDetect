//
//  LivenessDetector.h
//  FaceDetection
//
//  Created by Jack on 2023/10/20.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "MLKit.h"
#import "WOPLivenessDetectTaskShakeHead.h"
#import "WOPLivenessDetectTaskMouthOpen.h"
#import "WOPLivenessDetectTaskSmile.h"
#import "WOPLivenessDetectTaskFace.h"
#import "WOPLivenessDetectUtils.h"


/** 人脸检测错误类型 */
typedef NS_ENUM(NSUInteger, WOPLivenessDetectorError) {
    
    /** 找不到人脸 */
    WOPLivenessDetectorErrorNoFace,
    
    /** 多张人脸 */
    WOPLivenessDetectorErrorMultiFace,
    
    /** 脸不在框内 */
    WOPLivenessDetectorErrorNotInDetectRect,
    
    /** 脸距离太远 */
    WOPLivenessDetectorErrorFaceFast,
    
    /** 超时 */
    WOPLivenessDetectorErrorTimeout
};

NS_ASSUME_NONNULL_BEGIN

@protocol WOPLivenessDetectorDelegate <NSObject>

/** 开始活体检测 */
- (void)detectorStartWithTask:(id<WOPLivenessDetectTaskDelegate>_Nullable)task;

/** 检测完成 */
- (void)detectorCompletedWithTask:(id<WOPLivenessDetectTaskDelegate>_Nullable)task
                       isLastTask:(BOOL)isLastTask resultImage:(UIImage *)image;

/** 检测失败 */
- (void)detectorFailedWithTask:(id<WOPLivenessDetectTaskDelegate>_Nullable)task errorCode:(WOPLivenessDetectorError)errorCode;

/** 正在检测中 */
- (void)detectorProcessingWithTask:(id<WOPLivenessDetectTaskDelegate>_Nullable)task;

@end


@interface WOPLivenessDetector : NSObject

@property (nonatomic, weak) id<WOPLivenessDetectorDelegate> delegate;

/** 用任务初始化 */
- (instancetype)initWithTasks:(NSArray<id<WOPLivenessDetectTaskDelegate>> *)tasksArray;

/** 开始检测 */
- (void)startDetectionWithSampleBuffer:(CMSampleBufferRef)sampleBuffer
                        detectionFrame:(CGRect)detectionFrame
                          preViewLayer:(AVCaptureVideoPreviewLayer *)preViewLayer;

/** 重置识别 */
- (void)reset;

@end

NS_ASSUME_NONNULL_END
