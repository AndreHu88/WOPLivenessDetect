//
//  DetectionTaskDelegate.h
//  FaceDetection
//
//  Created by Jack on 2023/10/20.
//

#import <Foundation/Foundation.h>
#import "MLKit.h"

NS_ASSUME_NONNULL_BEGIN

@protocol WOPLivenessDetectTaskDelegate <NSObject>

/** 开始检测 */
- (void)startWithFace:(MLKFace *)face;

/** 开始的时间 */
- (double)startTime;

/** 检测的最大超时 */
- (double)detectionTimeout;

/** 是否识别超时 */
- (BOOL)isTimeout;

/** 动作的名字 */
- (NSString *)actionName;

/** 检测的结果 */
- (BOOL)processWithFace:(MLKFace *)face;

@end


NS_ASSUME_NONNULL_END
