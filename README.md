# WOPLivenessDetect

[![Version](https://img.shields.io/cocoapods/v/WOPLivenessDetect.svg?style=flat)](https://cocoapods.org/pods/WOPLivenessDetect)
[![License](https://img.shields.io/cocoapods/l/WOPLivenessDetect.svg?style=flat)](https://cocoapods.org/pods/WOPLivenessDetect)
[![Platform](https://img.shields.io/cocoapods/p/WOPLivenessDetect.svg?style=flat)](https://cocoapods.org/pods/WOPLivenessDetect)

`WOPLivenessDetect` is a third party for iOS liveness detection, We provide basic face feature detection and require users to cooperate with some actions to prove that they are real people.

`WOPLivenessDetect`checks for the following actions and properties
- Only one face
- The face is in the specified display view
- Smile
- Open mouth
- Shaking head left and right

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

WOPLivenessDetect works on iOS 10.0+. It depends on the Google MLKit, AVFoundation


## Installation

WOPLivenessDetect is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'WOPLivenessDetect'
```
## Usage
Using `WOPLivenessDetect` is easy, you can only init  and show `WOPLivenessDetectViewController`, all the detect will complete in the `WOPLivenessDetectViewController`, We provide the block or delegate callback for the detect result photos. The caller can execute your face compare logic

you can use block to get callback after success
```
WOPLivenessDetectViewController *detectVC = [WOPLivenessDetectViewController new];
    
detectVC.livenessDetectSuccessBlock = ^(NSArray<UIImage *> * _Nonnull imageArray) {
    # do something
};
detectVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
[self presentViewController: detectVC  animated: true completion: nil];
```

or use detect success delegate
```
/** 活体检测成功 */
- (void)livenessDetectSuccessWithAllTaskImage:(NSArray<UIImage *> *)imageArray;
```

## Author

Jack, 229376483@qq.com

## License

WOPLivenessDetect is available under the MIT license. See the LICENSE file for more info.
