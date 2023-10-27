//
//  DetectionTaskShake.m
//  FaceDetection
//
//  Created by Jack on 2023/10/20.
//

#import "WOPLivenessDetectTaskShakeHead.h"

@interface WOPLivenessDetectTaskShakeHead ()

/** 开始时间 */
@property (nonatomic, assign) double startTime;

@property (nonatomic, assign) CGFloat previousYaw;

@end

@implementation WOPLivenessDetectTaskShakeHead

#pragma mark - Life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - DetectionTaskDelegate
- (NSString *)actionName {
    return @"请左右摇头";
}

- (BOOL)processWithFace:(MLKFace *)face {
        
    NSLog(@"x: %.2f, y: %.2f z: %.2f", face.headEulerAngleX, face.headEulerAngleY, face.headEulerAngleZ);
    
    CGFloat yawChange = fabs(face.headEulerAngleY - self.previousYaw);
    // 设置一个Yaw角度变化的阈值，根据需要进行调整
    CGFloat yawThreshold = 20.0;
    if (yawChange > yawThreshold) {
        NSLog(@"摇头了！");
        return true;
    }
    else {
        return false;
    }
}

- (void)startWithFace:(MLKFace *)face {
    self.startTime = CFAbsoluteTimeGetCurrent();
    self.previousYaw = face.headEulerAngleY;
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
