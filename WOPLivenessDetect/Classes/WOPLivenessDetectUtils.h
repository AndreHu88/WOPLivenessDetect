//
//  DetectionUtils.h
//  FaceDetection
//
//  Created by Jack on 2023/10/20.
//

#import <Foundation/Foundation.h>
#import "MLKit.h"

NS_ASSUME_NONNULL_BEGIN

// 设备宽度
#define DEVICE_WIDTH ceilf(([[UIScreen mainScreen] respondsToSelector:@selector(nativeBounds)]?[UIScreen mainScreen].nativeBounds.size.width/[UIScreen mainScreen].nativeScale:[UIScreen mainScreen].bounds.size.width))

// 设置高度
#define DEVICE_HEIGHT ceilf(([[UIScreen mainScreen] respondsToSelector:@selector(nativeBounds)]?[UIScreen mainScreen].nativeBounds.size.height/[UIScreen mainScreen].nativeScale:[UIScreen mainScreen].bounds.size.height))

#define UIColorFromRGBA(rgbValue, a) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0 green:((float)((rgbValue & 0xFF00) >> 8)) / 255.0 blue:((float)(rgbValue & 0xFF)) / 255.0 alpha:a]

// 状态栏高度
#define IPHONE_STATUSBAR_HEIGHT \
^(){\
if (@available(iOS 13.0, *)) {\
UIStatusBarManager *statusBarManager = [UIApplication sharedApplication].windows.firstObject.windowScene.statusBarManager;\
return statusBarManager.statusBarFrame.size.height;\
} else {\
return [UIApplication sharedApplication].statusBarFrame.size.height;\
}\
}()

#define IPHONE_NAVIGATIONBAR_HEIGHT  (IPHONE_STATUSBAR_HEIGHT + 44)

// 底部指示条高度
#define INDICATOR_HEIGHT \
^(){\
if (@available(iOS 11.0, *)) {\
UIEdgeInsets safeAreaInsets = [[UIApplication sharedApplication] delegate].window.safeAreaInsets;\
return safeAreaInsets.bottom;\
} else {\
return UIEdgeInsetsMake(0, 0, 0, 0).bottom;\
}\
}()


@interface WOPLivenessDetectUtils : NSObject

/** 是否是人脸 */
+ (BOOL)isFacing:(MLKFace *)face;

/** 是否 张嘴 */
+ (BOOL)isMouthOpened:(MLKFace *)face;

// 高斯模糊
+ (UIImage *)blurImage:(UIImage *)image blur:(CGFloat)blur;

@end

NS_ASSUME_NONNULL_END
