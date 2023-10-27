//
//  WOPViewController.m
//  WOPLivenessDetect
//
//  Created by AndreHu88 on 10/26/2023.
//  Copyright (c) 2023 AndreHu88. All rights reserved.
//

#import "WOPViewController.h"
#import <WOPLivenessDetectViewController.h>

@interface WOPViewController ()

@property (nonatomic, strong) WOPLivenessDetectViewController *detectVC;


@end

@implementation WOPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(100, 150, 160, 40);
    [button setTitle:@"开始人脸识别" forState:UIControlStateNormal];
    button.center = self.view.center;
    button.titleLabel.font = [UIFont systemFontOfSize: 14];
    button.layer.cornerRadius = 6;
    button.backgroundColor = UIColor.redColor;
    [button addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview: button];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}

- (void)buttonAction {
    
    _detectVC = [WOPLivenessDetectViewController new];
    
    __weak typeof(self) weakSelf = self;
    _detectVC.livenessDetectSuccessBlock = ^(NSArray<UIImage *> * _Nonnull imageArray) {
        [weakSelf imageCompareWithFace: imageArray.lastObject];
    };
    _detectVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController: _detectVC  animated: true completion: nil];
}

/** 人脸比对 */
- (void)imageCompareWithFace:(UIImage *)image {
    
//    // 创建 AFHTTPSessionManager
//    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
//    [manager.requestSerializer setValue:@"174fc5bc-1f77-4179-900b-cded067d4417" forHTTPHeaderField:@"X-Api-Key"];
//    manager.responseSerializer = [AFJSONResponseSerializer serializer];
//    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"image/jpeg",@"image/png",@"application/octet-stream",@"text/plain",@"application/json",nil];
//    
//    NSString *urlStr = @"http://172.16.1.55:8000/api/v1/recognition/recognize";
//    
//    
//    NSLog(@"开始网络请求");
//    
//    [manager POST: urlStr  parameters: nil headers: nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
//        
//        NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
//        [formData appendPartWithFileData: imageData name:@"file" fileName:@"image.jpg" mimeType:@"image/jpeg"];
//        
//    } progress: nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        
//        NSLog(@"%@", responseObject);
//        NSDictionary *dict = (NSDictionary *)responseObject;
//        NSArray *array = dict[@"result"];
//        DetectorResultModel *resultModel = [DetectorResultModel mj_objectWithKeyValues: array.firstObject];
//        if (resultModel.matchedSubject) {
//            [self.detectVC faceCompareSuccessWithTips:  [NSString stringWithFormat: @"欢迎你 %@", resultModel.matchedSubject.subject]];
//        }
//        else {
//            [self.detectVC faceCompareErrorWithTips: @"人脸与身份信息不匹配"];
//        }
//        
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        NSLog(@"%@", error);
//        
//        [self.detectVC faceCompareErrorWithTips: @"网络错误"];
//    }];
    
}

@end
