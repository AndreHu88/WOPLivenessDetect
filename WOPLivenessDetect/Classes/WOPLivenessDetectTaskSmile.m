//
//  DetectionTaskSmile.m
//  FaceDetection
//
//  Created by Jack on 2023/10/20.
//

#import "WOPLivenessDetectTaskSmile.h"

@interface WOPLivenessDetectTaskSmile ()

/** 开始时间 */
@property (nonatomic, assign) double startTime;

@end

@implementation WOPLivenessDetectTaskSmile

#pragma mark - Life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - DetectionTaskDelegate
- (NSString *)actionName {
    return @"请保持微笑";
}

- (BOOL)processWithFace:(MLKFace *)face {
    
    if (face.smilingProbability > 0.67 && face.hasSmilingProbability) {
        return [WOPLivenessDetectUtils isFacing: face];
    }
    return false;
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
