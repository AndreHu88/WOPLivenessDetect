//
//  DetectionTaskFacing.m
//  FaceDetection
//
//  Created by Jack on 2023/10/20.
//

#import "WOPLivenessDetectTaskFace.h"

@interface WOPLivenessDetectTaskFace ()

/** 开始时间 */
@property (nonatomic, assign) double startTime;

@end

@implementation WOPLivenessDetectTaskFace

#pragma mark - Life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - DetectionTaskDelegate
- (NSString *)actionName {
    return @"请将人脸放入检测框中";
}

- (BOOL)processWithFace:(MLKFace *)face {
    
    NSLog(@"x: %.2f  y: %.2f  z: %.2f", face.headEulerAngleX, face.headEulerAngleY, face.headEulerAngleZ);
    return [WOPLivenessDetectUtils isFacing: face];
}

- (void)startWithFace:(MLKFace *)face {
    self.startTime = CFAbsoluteTimeGetCurrent();
}

- (BOOL)isTimeout {
    if ((CFAbsoluteTimeGetCurrent() - self.startTime) * 1000.f >= self.detectionTimeout) {
        return true;
    }
    return false;
}

- (double)detectionTimeout {
    return 8000.f;
}

@end
