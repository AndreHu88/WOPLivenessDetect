//
//  WOPLivenessDetectViewController.m
//  FaceDetection
//
//  Created by Jack on 2023/10/26.
//

#import "WOPLivenessDetectViewController.h"
#import "WOPLivenessDetector.h"
#import <Masonry/Masonry.h>

@interface WOPLivenessDetectViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, WOPLivenessDetectorDelegate>

@property (nonatomic, strong) dispatch_queue_t sessionQueue;

@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureVideoDataOutput *output;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) UIImageView *resultImageView;

@property (nonatomic, strong) UIVisualEffectView *effectView;

@property (nonatomic, strong) UIImageView *loadingImageView;

@property (nonatomic, strong) UIImageView *errorImageView;

@property (nonatomic, strong) UILabel *tipsLabel;

@property (nonatomic, assign) CGRect previewRect;

@property (nonatomic, strong) UIButton *tryAgainButton;

@property (nonatomic, strong) UIButton *backButton;

@property (nonatomic, strong) NSMutableArray<UIImage *> *resultImageArray;

@property (nonatomic, strong) WOPLivenessDetector *faceDetector;

@end

@implementation WOPLivenessDetectViewController

static NSString *const sessionQueueLabel = @"com.livenessDetect.sessionQueue";


#pragma mark - Life cycle
- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
   
    [self initData];
    [self setUpCaptureSessionInputOutPut];
    [self setupSubViews];
    [self setupViewLayouts];
    [self setupFaceDetector];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopCaptureSession];
}

- (void)initData {
    
    _previewRect = CGRectMake((DEVICE_WIDTH - 240) / 2, IPHONE_NAVIGATIONBAR_HEIGHT + 140,  240, 240);
    _resultImageArray = [NSMutableArray array];
}

- (void)setupSubViews {
    
    [self.view addSubview: self.backButton];
    [self.view addSubview: self.resultImageView];
    [self.view addSubview: self.loadingImageView];
    [self.view addSubview: self.errorImageView];
    [self.view addSubview: self.tipsLabel];
    [self.view addSubview: self.tryAgainButton];
    
    [self.view.layer addSublayer:_previewLayer];
}

- (void)setupViewLayouts {
    
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(16);
        make.top.offset(IPHONE_STATUSBAR_HEIGHT + 6);
        make.width.height.mas_equalTo(20);
    }];
    
    [_tipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(IPHONE_NAVIGATIONBAR_HEIGHT + 40);
        make.left.offset(100);
        make.right.offset(-100);
    }];
    
    [_tryAgainButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(-100);
        make.width.mas_equalTo(140);
        make.height.mas_equalTo(40);
        make.centerX.equalTo(self.view);
    }];
    
    [_errorImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(80);
        make.top.offset(IPHONE_NAVIGATIONBAR_HEIGHT + 40);
        make.centerX.equalTo(self.view);
    }];
    
    [_loadingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(80);
        make.center.equalTo(self.resultImageView);
    }];
}

#pragma mark - Action
- (void)backAction {
    [self dismissViewControllerAnimated: true completion: false];
}

- (void)tryAgainButtonAction {
    
    [self startCaptureSession];
    [self endLoading];
    
    self.resultImageArray = [NSMutableArray array];
    
    self.previewLayer.hidden = false;
    self.resultImageView.hidden = true;
    
    self.tryAgainButton.hidden = true;
    self.errorImageView.hidden = true;
    
    [self.tipsLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(IPHONE_NAVIGATIONBAR_HEIGHT + 40);
        make.left.offset(60);
        make.right.offset(-60);
    }];
    
    [self.faceDetector reset];
}

/** 识别超时 */
- (void)detectTimeOut {
    
    [self stopCaptureSession];
    
    self.previewLayer.hidden = true;
    self.resultImageView.hidden = false;
    
    self.tryAgainButton.hidden = false;
    self.errorImageView.hidden = false;
    
    [self.tipsLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.errorImageView.mas_bottom).offset(30);
        make.centerX.equalTo(self.view);
    }];
}

/** 活体检测成功 */
- (void)livenessDetectSuccess {
    
    self.tipsLabel.text = @"请稍后";
    [self stopCaptureSession];
    
    self.resultImageView.image = [WOPLivenessDetectUtils blurImage: self.resultImageArray.lastObject blur: 0.5];
    self.resultImageView.frame = self.previewRect;
    self.resultImageView.hidden = false;
    self.resultImageView.layer.cornerRadius = self.previewRect.size.width / 2;
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle: UIBlurEffectStyleLight];
    _effectView = [[UIVisualEffectView alloc] initWithEffect: blurEffect];
    _effectView.alpha = 0.8;
    _effectView.frame = self.resultImageView.bounds;
    _effectView.layer.cornerRadius = self.resultImageView.layer.cornerRadius;
    [self.resultImageView addSubview: _effectView];
    
    [self.view bringSubviewToFront: self.resultImageView];
    
    if (self.delegate && [self.delegate respondsToSelector: @selector(livenessDetectSuccessWithAllTaskImage:)]) {
        [self.delegate livenessDetectSuccessWithAllTaskImage: [self.resultImageArray copy]];
    }
    
    !self.livenessDetectSuccessBlock ?: self.livenessDetectSuccessBlock([self.resultImageArray copy]);
}

- (void)startLoading {
    
    [self.view bringSubviewToFront: self.loadingImageView];
    self.loadingImageView.hidden = false;
    self.resultImageView.hidden = false;
    
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
    rotationAnimation.duration = 0.6;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 200;
    
    [self.loadingImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}


- (void)endLoading {
    self.loadingImageView.hidden = true;
    self.resultImageView.hidden = true;
    [self.loadingImageView.layer removeAnimationForKey: @"rotationAnimation"];
}

/** 人脸比对成功 */
- (void)faceCompareSuccessWithTips:(NSString *)tips {
    
    [self detectTimeOut];
    [self endLoading];
    
    self.tipsLabel.text = tips;
    self.errorImageView.image = [self imageFromBundleWithName: @"success"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated: true completion: nil];
    });
}

/** 人脸比对失败 */
- (void)faceCompareErrorWithTips:(NSString *)tips {
    
    [self detectTimeOut];
    [self endLoading];

    self.tipsLabel.text = tips;
}

#pragma mark - setup
- (void)setUpCaptureSessionInputOutPut {
    
    _sessionQueue = dispatch_queue_create(sessionQueueLabel.UTF8String, nil);
    
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    
    // 获取前置摄像头
    AVCaptureDevice *captureDevice = [self captureDeviceForPosition: AVCaptureDevicePositionFront];
    
    // 创建输入流
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice: captureDevice error:&error];
    
    if (!error && [self.captureSession canAddInput:input]) {
        [self.captureSession addInput:input];
    }
    
    
    // 创建输出流
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoOutput.videoSettings = @{
        (id)
        kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]
    };
    videoOutput.alwaysDiscardsLateVideoFrames = YES;
    
    [videoOutput setSampleBufferDelegate: self queue: self.sessionQueue];
    
    if ([_captureSession canAddOutput: videoOutput]) {
        [_captureSession addOutput: videoOutput];
    }
    
    // 创建预览
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.frame = _previewRect;
    _previewLayer.cornerRadius = self.previewRect.size.width / 2;
    _previewLayer.masksToBounds = true;
    
    [self startCaptureSession];
}

- (void)setupFaceDetector {
    
    NSArray<id<WOPLivenessDetectTaskDelegate>> *taskArray = @[
        [WOPLivenessDetectTaskShakeHead new],
        [WOPLivenessDetectTaskMouthOpen new],
        [WOPLivenessDetectTaskSmile new]
    ];
    
    taskArray = [self shuffleArray: taskArray];
    NSMutableArray *tempArray = [taskArray mutableCopy];
    
    // 第一步先检测人脸
    [tempArray insertObject: [WOPLivenessDetectTaskFace new] atIndex: 0];
    
    if (!_faceDetector) {
        _faceDetector = [[WOPLivenessDetector alloc] initWithTasks: [tempArray copy]];
        _faceDetector.delegate = self;
    }
    
    [_faceDetector reset];
}

#pragma mark - private
- (AVCaptureDevice *)captureDeviceForPosition:(AVCaptureDevicePosition)position {
    if (@available(iOS 10, *)) {
        AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
                                                             discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera ]
                                                             mediaType:AVMediaTypeVideo
                                                             position:AVCaptureDevicePositionUnspecified];
        
        for (AVCaptureDevice *device in discoverySession.devices) {
            if (device.position == position) {
                return device;
            }
        }
    }
    return nil;
}

- (void)startCaptureSession {
    
    dispatch_async(self.sessionQueue, ^{
        [self.captureSession startRunning];
    });
    
}

- (void)stopCaptureSession {
    [self.captureSession stopRunning];
}

// 随机打乱数组的方法
- (NSArray *)shuffleArray:(NSArray *)array {
    NSMutableArray *shuffledArray = [array mutableCopy];
    NSUInteger count = [shuffledArray count];
    
    for (NSUInteger i = count - 1; i > 0; i--) {
        NSUInteger j = arc4random_uniform((u_int32_t)(i + 1));
        [shuffledArray exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    
    return [shuffledArray copy];
}

- (UIImage *)imageFromBundleWithName:(NSString *)name {
    
    NSBundle *bundle = [NSBundle bundleForClass: [self class]];
    NSURL *url = [bundle URLForResource:@"WOPLivenessDetect" withExtension:@"bundle"];
    NSBundle *imageBundle = [NSBundle bundleWithURL:url];
    
    UIImage *image = [UIImage imageWithContentsOfFile: [imageBundle pathForResource: name ofType: @"png"]];
    return image;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    [self.faceDetector startDetectionWithSampleBuffer: sampleBuffer
                                       detectionFrame: self.previewRect
                                         preViewLayer: self.previewLayer];
}

#pragma mark - DetectorDelegate
- (void)detectorStartWithTask:(id<WOPLivenessDetectTaskDelegate>)task {
    self.tipsLabel.text = task.actionName;
}

- (void)detectorProcessingWithTask:(id<WOPLivenessDetectTaskDelegate>)task {
    self.tipsLabel.text = task.actionName;
}

- (void)detectorCompletedWithTask:(id<WOPLivenessDetectTaskDelegate>)task
                       isLastTask:(BOOL)isLastTask
                      resultImage:(UIImage *)image {
    
    if (image) {
        [self.resultImageArray addObject: image];
    }
    
    if (isLastTask) {
        [self livenessDetectSuccess];
        [self startLoading];
    }
    
}

- (void)detectorFailedWithTask:(id<WOPLivenessDetectTaskDelegate>)task errorCode:(WOPLivenessDetectorError)errorCode {
    
    if (errorCode == WOPLivenessDetectorErrorTimeout) {
        self.tipsLabel.text = @"识别超时";
        [self detectTimeOut];
    }
    else if (errorCode == WOPLivenessDetectorErrorNoFace) {
        self.tipsLabel.text = @"没有检测到人脸";
    }
    else if (errorCode == WOPLivenessDetectorErrorNotInDetectRect) {
        self.tipsLabel.text = @"请移动人脸到框内";
    }
    else if (errorCode == WOPLivenessDetectorErrorFaceFast) {
        self.tipsLabel.text = @"请靠近一些";
    }
    else if (errorCode == WOPLivenessDetectorErrorMultiFace) {
        self.tipsLabel.text = @"检测到多张人脸";
    }
    else {
        self.tipsLabel.text = task.actionName;
    }
}


#pragma mark - Getter
- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [UILabel new];
        _tipsLabel.textColor = [UIColor blackColor];
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.font = [UIFont boldSystemFontOfSize: 20];
        _tipsLabel.text = @"没有检测到人脸";
        _tipsLabel.numberOfLines = 0;
    }
    return _tipsLabel;
}

- (UIImageView *)resultImageView {
    if (!_resultImageView) {
        _resultImageView = [[UIImageView alloc] init];
        _resultImageView.frame = self.previewRect;
        _resultImageView.layer.cornerRadius = self.previewRect.size.width / 2;
        _resultImageView.clipsToBounds = true;
        _resultImageView.hidden = true;
        _resultImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _resultImageView;
}

- (UIImageView *)errorImageView {
    if (!_errorImageView) {
        _errorImageView = [[UIImageView alloc] init];
        _errorImageView.hidden = true;
        _errorImageView.image = [self imageFromBundleWithName: @"error"];
    }
    return _errorImageView;
}

- (UIImageView *)loadingImageView {
    if (!_loadingImageView) {
        _loadingImageView = [[UIImageView alloc] init];
        _loadingImageView.hidden = true;
        _loadingImageView.image = [self imageFromBundleWithName: @"loading"];
    }
    return _loadingImageView;
}

- (UIButton *)tryAgainButton {
    if (!_tryAgainButton) {
        _tryAgainButton = [UIButton buttonWithType: UIButtonTypeCustom];
        _tryAgainButton.layer.cornerRadius = 6;
        _tryAgainButton.backgroundColor = UIColorFromRGBA(0xF2F2F2, 1.0);
        [_tryAgainButton setTitle: @"再试一次" forState: UIControlStateNormal];
        _tryAgainButton.titleLabel.font = [UIFont systemFontOfSize: 14];
        [_tryAgainButton setTitleColor: UIColor.blackColor forState: UIControlStateNormal];
        [_tryAgainButton addTarget:self action:@selector(tryAgainButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _tryAgainButton.hidden = true;
    }
    return _tryAgainButton;
}

- (UIButton *)backButton{
    
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [_backButton setImage: [self imageFromBundleWithName: @"close"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

@end
