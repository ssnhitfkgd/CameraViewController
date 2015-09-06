//
//  FiltersViewController.m
//
//
//  Created by wangyong on 15-5-20.
//  Copyright (c) 2014年 Whisper. All rights reserved.
//

#import "WPMessageVideoFiltersViewController.h"
#import "WPCreateWhisperViewContrlller.h"

@interface WPMessageVideoFiltersViewController () <UIScrollViewDelegate>

@property (nonatomic, copy) NSString *user_id;
@property (nonatomic, copy) NSString *app_id;



@end

@implementation WPMessageVideoFiltersViewController


+ (instancetype)sharedInstance {
    static WPMessageVideoFiltersViewController *instance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        instance = [[self alloc] initWithAppID:nil];
    });
    
    return instance;
}


#pragma mark - UI Setup
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (id)initWithUserID:(NSString*)user_id
{
    self = [super init];
    if(self)
    {
        self.user_id = user_id;
        self.app_id = @"";

    }
    
    return self;
}

- (id)initWithAppID:(NSString*)app_id
{
    self = [super init];
    if(self)
    {
        self.app_id = app_id;
        self.user_id = @"";
    }
    
    return self;
}

- (id)initWithDelegate:(id<MessageVideoFiltersViewControllerDelegate>) delegate
{
    self = [super init];
    if(self)
    {
        self.app_id = @"";
        self.user_id = @"";
        self.delegate = delegate;
    }
    
    return self;
}

- (void)setCameraEnable:(BOOL)enable
{
    [super setCameraEnable:enable];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame = CGRectMake(15, ScreenHeight - 55, 40, 40);
    [leftButton addTarget:self action:@selector(leftButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [leftButton setImage:[UIImage imageNamed:@"navigationbar_dismiss"] forState:UIControlStateNormal];
    [self.bottomView addSubview:leftButton];
    
    
}

- (void)leftButtonPressed:(UIButton*)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}


- (void)showSendImageViewController:(UIImage*)image image_from:(NSString*)image_from
{
    WPCreateWhisperViewContrlller *createWhisperController = [[WPCreateWhisperViewContrlller alloc] initWithWhisperImage:image image_from:image_from user:self.user_id app_id:self.app_id name:self.name];
    
    __block typeof(self) block_self = self;
    [createWhisperController setBlock_dismiss:^(UIImage* image,NSString* image_pire){
        [block_self dismissViewControllerAnimated:NO completion:^{
            if(image && block_self.delegate)
            {
                if([block_self.delegate respondsToSelector:@selector(imageFilterReturn:image_pire:image_from:)])
                {
                    [block_self.delegate imageFilterReturn:image image_pire:image_pire image_from:image_from];
                }
            }
        }];
    }];
    WPNavigationController *navigationController = [[WPNavigationController alloc] initWithRootViewController:createWhisperController];
    [self presentViewController:navigationController animated:NO completion:^{
        [self resumeCameraCapture];
    }];
}

@end
