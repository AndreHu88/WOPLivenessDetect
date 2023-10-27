//
//  WOPLivenessDetectViewController.h
//  FaceDetection
//
//  Created by Jack on 2023/10/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WOPLivenessDetectViewControllerDelegate <NSObject>

/** 活体检测成功 */
- (void)livenessDetectSuccessWithAllTaskImage:(NSArray<UIImage *> *)imageArray;

@end

@interface WOPLivenessDetectViewController : UIViewController

@property (nonatomic, assign) id<WOPLivenessDetectViewControllerDelegate> delegate;

/** 活体检测成功 回调 */
@property (nonatomic, copy) void (^livenessDetectSuccessBlock)(NSArray<UIImage *> *imageArray);

/** 人脸比对成功 */
- (void)faceCompareSuccessWithTips:(NSString *)tips;

/** 人脸比对失败 */
- (void)faceCompareErrorWithTips:(NSString *)tips;

@end

NS_ASSUME_NONNULL_END
