//
//  FiltersViewController.m
//
//
//  Created by wangyong on 15-5-20.
//  Copyright (c) 2014年 Whisper. All rights reserved.
//

#import "WPBaseVideoFiltersViewController.h"
#import "GPUImage.h"
#import "DoImagePickerController.h"
#import "WPMainViewViewController.h"
#import "WPCreateWhisperViewContrlller.h"
#import "GPUImageSoftEleganceFilter.h"
#import<AssetsLibrary/ALAssetsLibrary.h>
#import "UIView+i7Rotate360.h"

@interface WPBaseVideoFiltersViewController () <UIScrollViewDelegate>
{
}
@property (nonatomic, strong) GPUImageStillCamera *videoCamera;
@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *filter;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, assign) NSInteger currentFilterIndex;
@property (nonatomic, strong) GPUImageFilterGroup *filtersGroup;
@property (nonatomic, strong) GPUImageiOSBlurFilter *blurFilter;

@property (nonatomic, strong) UILabel *tipLabel;

@end

@implementation WPBaseVideoFiltersViewController
@synthesize videoCamera = _videoCamera;
@synthesize filter = _filter;
@synthesize filterView = _filterView;
@synthesize currentFilterIndex;
@synthesize filtersGroup = _filtersGroup;
@synthesize blurFilter = _blurFilter;
@synthesize tipLabel = _tipLabel;

#pragma mark - UI Setup
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
     
        
        self.filtersGroup = [GPUImageFilterGroup new];
        
        //无滤镜
        [_filtersGroup addFilter:[[GPUImageMissEtikateFilter alloc] initWithImage:@"yoyo_filter_none.png"]];
        
        //亮
        [_filtersGroup addFilter:[[GPUImageMissEtikateFilter alloc] initWithImage:@"yoyo_filter_light.jpg"]];
        
        //青春
        [_filtersGroup addFilter:[[GPUImageMissEtikateFilter alloc] initWithImage:@"yoyo_filter_young.jpg"]];
        
        //1987
        [_filtersGroup addFilter:[[GPUImageMissEtikateFilter alloc] initWithImage:@"yoyo_filter_1987.jpg"]];
        
        //黑白
        [_filtersGroup addFilter:[[GPUImageMissEtikateFilter alloc] initWithImage:@"yoyo_filter_black.jpg"]];
        
    }
    return self;
}

- (void)setCameraEnable:(BOOL)enable
{
    if(enable)
    {
        [_videoCamera startCameraCapture];
    }
    else
    {
        [_videoCamera stopCameraCapture];

    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applocatopnDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applocatopnWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    
    
    self.view.backgroundColor = [UIColor blackColor];
    
    NSString *mediaType = AVMediaTypeVideo;
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    if(authStatus == AVAuthorizationStatusNotDetermined)
    {
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            
            if(!granted) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self addOpenCameraErrorView];
                });
            }
            else
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self createSubView];
                });
            }
        
        }];
    }
    else if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        [self addOpenCameraErrorView];
    }
    else
    {
        [self createSubView];
    }
    
}

- (void)createSubView
{

    self.videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    _videoCamera.horizontallyMirrorRearFacingCamera = NO;
    
    self.filter = [self.filtersGroup filterAtIndex:0];//[[GPUImageSepiaFilter alloc] init];
    [_videoCamera addTarget:_filter];
    
    self.filterView = [[GPUImageView alloc] initWithFrame:self.view.bounds];//(GPUImageView *)self.view;
    _filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    [_filterView setEnabled:YES];
    [_filterView setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:_filterView];
    
    [_filter addTarget:_filterView];
    [_videoCamera startCameraCapture];
    
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    scrollView.contentSize = CGSizeMake(ScreenWidth, ScreenHeight*2);
    scrollView.pagingEnabled = YES;
    scrollView.clipsToBounds = YES;
    scrollView.bounces = NO;
    scrollView.showsVerticalScrollIndicator = false;
    [scrollView setContentOffset:CGPointMake(0, ScreenHeight)];
    scrollView.delegate = self;
    [scrollView setTag:11];
    
    
    [self.view addSubview:scrollView];
    
    
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, ScreenHeight, ScreenWidth, ScreenHeight)];
    [scrollView addSubview:bottomView];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewTap:)];
    [bottomView addGestureRecognizer:tapGestureRecognizer];
    self.bottomView = bottomView;
    
    int icon_size_width = 43;
    int icon_size_height = 50;
    
    int image_spacing = (icon_size_width-20)/2;
    int nSpacing = (ScreenWidth - (25-image_spacing)*2 - (4*icon_size_width))/3;
    UIButton *photosButton = [UIButton buttonWithType:UIButtonTypeCustom];
    photosButton.frame = CGRectMake(25-image_spacing, 20-image_spacing, icon_size_width, icon_size_height);
    [photosButton setImage:[UIImage imageNamed:@"camera_album"] forState:UIControlStateNormal];
    [photosButton addTarget:self action:@selector(photoButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:photosButton];
    
    
    UIButton *flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    flashButton.frame = CGRectMake(photosButton.right+nSpacing, 20-image_spacing, icon_size_width, icon_size_height);
    [flashButton setImage:[UIImage imageNamed:@"camera_flash_off"] forState:UIControlStateNormal];
    [flashButton setImage:[UIImage imageNamed:@"camera_flash_on"] forState:UIControlStateSelected];
    [flashButton addTarget:self action:@selector(flashButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:flashButton];
    
    UIButton *filterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    filterButton.frame = CGRectMake(flashButton.right+nSpacing, 20-image_spacing, icon_size_width, icon_size_height);
    [filterButton setImage:[UIImage imageNamed:@"camera_filter"] forState:UIControlStateNormal];
    [filterButton addTarget:self action:@selector(filterButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:filterButton];
    
    UIButton *switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    switchButton.frame = CGRectMake(filterButton.right+nSpacing, 20-image_spacing, icon_size_width, icon_size_height);
    [switchButton setImage:[UIImage imageNamed:@"camera_switch"] forState:UIControlStateNormal];
    [switchButton addTarget:self action:@selector(switchButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:switchButton];
    
    self.tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 30)];
    self.tipLabel.top = switchButton.bottom;
    self.tipLabel.centerX = bottomView.width/2.f;
    self.tipLabel.backgroundColor = [UIColor clearColor];
    self.tipLabel.font = [UIFont boldSystemFontOfSize:18.f];
    self.tipLabel.textAlignment = NSTextAlignmentCenter;
    self.tipLabel.textColor = [UIColor whiteColor];
    [bottomView addSubview:self.tipLabel];
    
    
    UIButton *shootButton = [UIButton buttonWithType:UIButtonTypeCustom];
    shootButton.frame = CGRectMake((ScreenWidth-56)/2, ScreenHeight - 70, 56, 56);
    [shootButton setImage:[UIImage imageNamed:@"camera_shot"] forState:UIControlStateNormal];
    [shootButton addTarget:self action:@selector(shootButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:shootButton];
    

//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applocatopnWillTerminateNotification:) name:UIApplicationWillTerminateNotification object:nil];

    
    
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined) {
        
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        
        [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            
            if (*stop) {
                [self addDoImagePickerControllerView:scrollView];
                
            }
            *stop = TRUE;
            
        } failureBlock:^(NSError *error) {
            [self addOpenPhotoErrorView:scrollView];
            
        }];
    }
    else
    {
        
        ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
        if (author == kCLAuthorizationStatusRestricted || author ==kCLAuthorizationStatusDenied)
        {
            [self addOpenPhotoErrorView:scrollView];
        }
        else
        {
            [self addDoImagePickerControllerView:scrollView];
        }
    }
    
   
}

- (void)addDoImagePickerControllerView:(UIScrollView*)scrollView
{
    DoImagePickerController *imagePickerController = [[DoImagePickerController alloc] initWithNibName:@"DoImagePickerController" bundle:nil];
    imagePickerController.delegate = self;
    imagePickerController.nMaxCount = 1;
    imagePickerController.nResultType = DO_PICKER_RESULT_UIIMAGE;
    imagePickerController.nColumnCount = iPhone5_down? 3:4;
    imagePickerController.iCloudPhoto = NO;
    [imagePickerController.view setFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    
    [self addChildViewController:imagePickerController];
    [scrollView addSubview:imagePickerController.view];
}

- (void)addOpenCameraErrorView
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, ScreenWidth-60, 80)];
        [label setText:@"没有权限访问相机\n\n请在iPhone的“设置－隐私”选项中，允许有有相机访问你的相机。"];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[UIColor lLightGrayColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setNumberOfLines:0];
        label.centerY = self.view.centerY - 20;
        [label setFont:[UIFont systemFontOfSize:16]];
        [self.view addSubview:label];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:@"前往设置" forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont systemFontOfSize:14]];

        [button setFrame:CGRectMake(0, 0, 100, 38)];
        [button setCenterX:self.view.centerX];
        [button setTop:label.bottom + 20];
        [button.layer setCornerRadius:4.f];
        [button setClipsToBounds:YES];
        [button setBackgroundColor:[UIColor lBlue]];

        [button addTarget:self action:@selector(openCameraButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        
    }
    else
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, ScreenWidth-60, 40)];
        [label setText:@"请在iPhone的“设置－隐私”选项中，允许有有相机访问你的相机。"];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[UIColor lLightGrayColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setNumberOfLines:2];
        label.centerY = self.view.centerY - 20;
        [label setFont:[UIFont systemFontOfSize:14]];
        [self.view addSubview:label];
        
    }
}

- (void)addOpenPhotoErrorView:(UIScrollView*)scrollView
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, ScreenWidth-60, 80)];
        [label setText:@"啦啦啦\n\n请在iPhone的“设置－隐私”选项中，允许有有相机访问你的相册。"];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[UIColor lLightGrayColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setNumberOfLines:0];
        label.centerY = self.view.centerY - 20;
        [label setFont:[UIFont systemFontOfSize:16]];
        [scrollView addSubview:label];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:@"前往设置" forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont systemFontOfSize:14]];

        [button setFrame:CGRectMake(0, 0, 100, 40)];
        [button setCenterX:self.view.centerX];
        [button setTop:label.bottom + 20];
        [button setBackgroundColor:[UIColor lBlue]];
        [button.layer setCornerRadius:4.f];
        [button setClipsToBounds:YES];
        
        [button addTarget:self action:@selector(openCameraButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [scrollView addSubview:button];
        
    }
    else
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, ScreenWidth-60, 40)];
        [label setText:@"请在iPhone的“设置－隐私”选项中，允许有有相机访问你的相册。"];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[UIColor lLightGrayColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setNumberOfLines:2];
        label.centerY = self.view.centerY - 20;
        [label setFont:[UIFont systemFontOfSize:14]];
        [scrollView addSubview:label];
        
    }
}

- (void)openCameraButtonClicked:(id)sender
{
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    BOOL canOpenUrl = [[UIApplication sharedApplication] canOpenURL:url];
    
    if(canOpenUrl)
    {
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)didCancelDoImagePickerController
{
    UIScrollView *scrollView = (UIScrollView*)[self.view viewWithTag:11];
    if(scrollView)
    {
        [UIView animateWithDuration:0.1 animations:^{
            [scrollView setContentOffset:CGPointMake(0, ScreenHeight) animated:NO];

        } completion:^(BOOL finished) {
                    
            [_videoCamera removeAllTargets];
            [_filter removeAllTargets];
            [_blurFilter removeAllTargets];
            [_videoCamera addTarget:_filter];
            [_filter addTarget:_filterView];
            _blurFilter = nil;

        }];
    }
}

//- (void)applocatopnWillTerminateNotification:(NSNotification*)notification
//{
//    [_videoCamera pauseCameraCapture];
//}

- (void)applocatopnWillResignActiveNotification:(NSNotification*)notification
{
    if(_videoCamera)
    [_videoCamera pauseCameraCapture];
    [_bottomView setBackgroundColor:[UIColor blackColor]];
}

- (void)applocatopnDidBecomeActiveNotification:(NSNotification*)notification
{
    if(_videoCamera)
    [_videoCamera resumeCameraCapture];
    [_bottomView setBackgroundColor:[UIColor clearColor]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Map UIDeviceOrientation to UIInterfaceOrientation.
    UIInterfaceOrientation orient = UIInterfaceOrientationPortrait;
    switch ([[UIDevice currentDevice] orientation])
    {
        case UIDeviceOrientationLandscapeLeft:
            orient = UIInterfaceOrientationLandscapeLeft;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            orient = UIInterfaceOrientationLandscapeRight;
            break;
            
        case UIDeviceOrientationPortrait:
            orient = UIInterfaceOrientationPortrait;
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            orient = UIInterfaceOrientationPortraitUpsideDown;
            break;
            
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationUnknown:
            // When in doubt, stay the same.
            orient = fromInterfaceOrientation;
            break;
    }
    _videoCamera.outputImageOrientation = orient;
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES; // Support all orientations.
}

#pragma mark - Button methods
- (void)flashButtonClicked:(UIButton*)sender {
    [sender setSelected:!sender.selected];
    [_videoCamera openCaptureTorch];
 
}

- (void)switchButtonClicked:(id)sender {
    [sender rotate360WithDuration:0.25];// repeatCount:0 timingMode:i7Rotate360TimingModeLinear];

    [_videoCamera swapFrontAndBackCameras];
 
}

- (void)shootButtonPressed:(id)sender {

    [_videoCamera capturePhotoAsJPEGProcessedUpToFilter:_filter withCompletionHandler:^(NSData *processedJPEG, NSError *error) {
        UIImage *image = [UIImage imageWithData:processedJPEG];
//        UIImage *image = [UIImage imageWithUIViewAt2x:self.];
        image =  [image scaleToSize:CGSizeMake(1000, 1000)];
        [self showSendImageViewController:image image_from:@"camera"];
    }];
}

- (void)photoButtonClicked:(id)sender{
    UIScrollView *scrollView = (UIScrollView*)[self.view viewWithTag:11];
    if(scrollView)
    {
        [scrollView setContentOffset:CGPointZero animated:YES];
    }
}

- (void)filterButtonClicked:(id)sender{
  
    [_videoCamera removeAllTargets];
    if(_filter)
    {
        [_filter removeAllTargets];
    }
    
    _filter = [_filtersGroup filterAtIndex:currentFilterIndex++];
    
    [_videoCamera addTarget:_filter];
    [_filter addTarget:_filterView];
    
//    if([_filter isKindOfClass:[GPUImageMissEtikateFilter class]]){
//    [label setText:((GPUImageMissEtikateFilter*)_filter).imageName];
//    NSLog(@"%@",((GPUImageMissEtikateFilter*)_filter).imageName);
//    }
    if(currentFilterIndex >= [_filtersGroup filterCount])
        currentFilterIndex = 0;
    
    switch (currentFilterIndex) {
        case 0:
            self.tipLabel.text = @"黑白";
            break;
        case 1:
            self.tipLabel.text = @"无";
            break;
        case 2:
            self.tipLabel.text = @"亮";
            break;
        case 3:
            self.tipLabel.text = @"青春";
            break;
        case 4:
            self.tipLabel.text = @"1987";
            break;
        default:
            break;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearTipText:) object:nil];
    [self performSelector:@selector(clearTipText:) withObject:nil afterDelay:1.f];
}

- (void)clearTipText:(id)sender
{
    self.tipLabel.text = nil;
}

- (CGSize)properSizeForResizingLargeImage:(UIImage *)originaUIImage {
    float originalWidth = originaUIImage.size.width;
    float originalHeight = originaUIImage.size.height;
    float smallerSide = 0.0f;
    float scalingFactor = 0.0f;
    
    if (originalWidth < originalHeight) {
        smallerSide = originalWidth;
        scalingFactor = 640.0f / smallerSide;
        return CGSizeMake(640.0f, originalHeight*scalingFactor);
    } else {
        smallerSide = originalHeight;
        scalingFactor = 640.0f / smallerSide;
        return CGSizeMake(originalWidth*scalingFactor, 640.0f);
    }
}


- (void)leftButtonPressed:(UIButton*)sender{
    if(self.mainViewViewController){
        [self.mainViewViewController showMessageViewController:YES];
    }
}

- (void)rightButtonPressed:(UIButton*)sender{
    if(self.mainViewViewController){
        [self.mainViewViewController showContactsViewController];
    }
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    NSInteger index = fabs(scrollView.contentOffset.y) / scrollView.frame.size.height;
    if(index == 1)
    {
        [_videoCamera removeAllTargets];
        [_filter removeAllTargets];
        [_blurFilter removeAllTargets];
        [_videoCamera addTarget:_filter];
        [_filter addTarget:_filterView];
        _blurFilter = nil;
        
        if(self.mainViewViewController)
        {
            UIScrollView *scrollView = self.mainViewViewController.scrollView;
            
            [scrollView setScrollEnabled:YES];
        }
    }
    else
    {
        if(self.mainViewViewController)
        {
            UIScrollView *scrollView = self.mainViewViewController.scrollView;
            
            [scrollView setScrollEnabled:NO];
        }
    }
}

- (id)initWithParentViewController:(WPMainViewViewController*)delegate
{
    self = [super init];
    if(self)
    {
        self.mainViewViewController = delegate;
    }
    
    return self;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
    NSInteger index = fabs(scrollView.contentOffset.y) / scrollView.frame.size.height;
    if(index == 1){
        [_videoCamera removeAllTargets];
        [_filter removeAllTargets];
        [_blurFilter removeAllTargets];
        [_videoCamera addTarget:_filter];
        [_filter addTarget:_filterView];
        _blurFilter = nil;
        
        if(self.parentViewController)
        {
            UIScrollView *scrollView = self.mainViewViewController.scrollView;
            
            [scrollView setScrollEnabled:YES];
        }
    }
    else
    {
        if(self.parentViewController)
        {
            UIScrollView *scrollView = self.mainViewViewController.scrollView;
            
            [scrollView setScrollEnabled:NO];
        }
    }
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
   
    
    NSInteger index = fabs(scrollView.contentOffset.y) / scrollView.frame.size.height;
    if(index == 0){
        if(!_blurFilter){
            [_videoCamera removeAllTargets];
            [_filter removeAllTargets];
            _blurFilter = [[GPUImageiOSBlurFilter alloc] init];
            [_videoCamera addTarget:_blurFilter];
            [_blurFilter addTarget:_filterView];
        }
     
        CGFloat factor = iPhone5_down? 0.5:0.8;
        CGFloat pixels = iPhone5_down? 7:10;

        _blurFilter.rangeReductionFactor =  factor - (scrollView.contentOffset.y/100)/10;
        _blurFilter.saturation = 1.5;
        _blurFilter.downsampling = 6.0;
        _blurFilter.blurRadiusInPixels = pixels-(scrollView.contentOffset.y/100);
    }

}

- (void)didSelectPhotosFromDoImagePickerController:(DoImagePickerController *)picker result:(NSArray *)aSelected
{
    if(aSelected && [aSelected count] > 0)
    {
//#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
//        [self showSendImageViewControllerInd:aSelected image_from:@"album"];
//#else
        [self showSendImageViewController:aSelected[0] image_from:@"album"];
//#endif
    }
}

- (void)showSendImageViewControllerInd:(NSArray*)array image_from:(NSString*)image_from
{
    WPCreateWhisperViewContrlller *createWhisperController = [[WPCreateWhisperViewContrlller alloc] initWithWhisperIndexPath:array image_from:@"album" user:nil app_id:nil];
    //
    WPNavigationController *navigationController = [[WPNavigationController alloc] initWithRootViewController:createWhisperController];
    [self.navigationController presentViewController:navigationController animated:NO completion:^{
        [self resumeCameraCapture];
    }];
}

- (void)showSendImageViewController:(UIImage*)image image_from:(NSString*)image_from
{
    WPCreateWhisperViewContrlller *createWhisperController = [[WPCreateWhisperViewContrlller alloc] initWithWhisperImage:image image_from:image_from user:nil app_id:nil name:nil];
    //
    WPNavigationController *navigationController = [[WPNavigationController alloc] initWithRootViewController:createWhisperController];
    [self.navigationController presentViewController:navigationController animated:NO completion:^{
        [self resumeCameraCapture];
    }];
}

- (void)resumeCameraCapture
{
    [_videoCamera resumeCameraCapture];
}

- (void)pauseCameraCapture
{
    [_videoCamera pauseCameraCapture];
}

- (void)dealloc
{
    [self.videoCamera stopCameraCapture];
    self.videoCamera = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -------------touch to focus---------------
- (void)scrollViewTap:(UITapGestureRecognizer*)recognizer
{
    CGPoint translatedPoint = [recognizer locationInView:self.filterView];
  
    if (CGRectContainsPoint(self.filterView.bounds, translatedPoint) == NO) {
        return;
    }
    
    [self focusInPoint:translatedPoint];
}

/**
 *  点击后对焦
 *
 *  @param devicePoint 点击的point
 */
- (void)focusInPoint:(CGPoint)devicePoint {
    [_videoCamera focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:CGPointMake(devicePoint.x/ScreenWidth, devicePoint.y/ScreenHeight) monitorSubjectAreaChange:YES];
}



@end
