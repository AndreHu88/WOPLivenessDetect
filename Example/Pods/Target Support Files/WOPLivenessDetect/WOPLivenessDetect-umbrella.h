#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "WOPLivenessDetector.h"
#import "WOPLivenessDetectTaskDelegate.h"
#import "WOPLivenessDetectTaskFace.h"
#import "WOPLivenessDetectTaskMouthOpen.h"
#import "WOPLivenessDetectTaskShakeHead.h"
#import "WOPLivenessDetectTaskSmile.h"
#import "WOPLivenessDetectUtils.h"
#import "WOPLivenessDetectViewController.h"

FOUNDATION_EXPORT double WOPLivenessDetectVersionNumber;
FOUNDATION_EXPORT const unsigned char WOPLivenessDetectVersionString[];

