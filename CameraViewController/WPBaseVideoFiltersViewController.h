//
//  FiltersViewController.h
//
//
//  Created by wangyong on 15-5-20.
//  Copyright (c) 2014年 Whisper. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "WPMainViewViewController.h"
#import "WPBaseScrollView.h"


@interface WPBaseVideoFiltersViewController : UIViewController

@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) WPMainViewViewController *mainViewViewController;


- (id)initWithParentViewController:(WPMainViewViewController*)delegate;
- (void)resumeCameraCapture;
- (void)setCameraEnable:(BOOL)enable;
- (void)rightButtonPressed:(UIButton*)sender;
- (void)leftButtonPressed:(UIButton*)sender;
- (void)showSendImageViewController:(UIImage*)image image_from:(NSString*)image_from;
- (void)didCancelDoImagePickerController;
- (void)pauseCameraCapture;
@end
