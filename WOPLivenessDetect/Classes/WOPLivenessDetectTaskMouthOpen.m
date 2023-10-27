//
//  DetectionTaskMouthOpen.m
//  FaceDetection
//
//  Created by Jack on 2023/10/20.
//

#import "WOPLivenessDetectTaskMouthOpen.h"

@interface WOPLivenessDetectTaskMouthOpen ()

/** 开始时间 */
@property (nonatomic, assign) double startTime;

@end

@implementation WOPLivenessDetectTaskMouthOpen

#pragma mark - Life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - DetectionTaskDelegate
- (NSString *)actionName {
    return @"请张开嘴巴";
}

- (BOOL)processWithFace:(MLKFace *)face {

    return [WOPLivenessDetectUtils isMouthOpened: face] && [WOPLivenessDetectUtils isFacing: face];
}

- (void)startWithFace:(MLKFace *)face {
    self.startTime = CFAbsoluteTimeGetCurrent();
}

- (BOOL)isTimeout {
    if (CFAbsoluteTimeGetCurrent() - self.startTime >= self.detectionTimeout) {
        return true;
    }
    return false;
}

- (double)detectionTimeout {
    return 5000;
}

@end
