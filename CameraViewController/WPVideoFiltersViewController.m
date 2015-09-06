//
//  FiltersViewController.m
//
//
//  Created by wangyong on 15-5-20.
//  Copyright (c) 2014年 Whisper. All rights reserved.
//

#import "WPVideoFiltersViewController.h"
#import "GPUImage.h"
#import "DoImagePickerController.h"
#import "WPMainViewViewController.h"
#import "WPCreateWhisperViewContrlller.h"
#import "GPUImageSoftEleganceFilter.h"
#import "UIButton+Addition.h"
#import "WPNotificationCountDto.h"

@interface WPVideoFiltersViewController () <UIScrollViewDelegate>
{
//    UILabel *label;
    UIButton *personButton;
    UIButton *messageButton;
}
@end

@implementation WPVideoFiltersViewController

#pragma mark - UI Setup
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
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
    
    
    personButton = [UIButton buttonWithType:UIButtonTypeCustom];
    personButton.frame = CGRectMake(0, ScreenHeight - 65, 44, 44);
    personButton.right = ScreenWidth-(25-(52-22)/2)-5;
    personButton.contentMode = UIViewContentModeCenter;
    [personButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
    [personButton addTarget:self action:@selector(personButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [personButton setBackgroundImage:[UIImage imageNamed:@"camera_right"] forState:UIControlStateNormal];
    
    if(self.bottomView)
    {
        [self.bottomView addSubview:personButton];
    }
    else
    {
        [self.view addSubview:personButton];
    }
    
    messageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    messageButton.frame = CGRectMake(25-(52-22)/2+5, ScreenHeight - 65, 44, 44);
    messageButton.contentMode = UIViewContentModeCenter;
    [messageButton setBackgroundImage:[UIImage imageNamed:@"camera_left"] forState:UIControlStateNormal];
    [messageButton addTarget:self action:@selector(messageButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [messageButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
    if(self.bottomView)
    {
        [self.bottomView addSubview:messageButton];
    }
    else
    {
        [self.view addSubview:messageButton];
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMessageCount) name:NOTIFICATION_UPDATE_MESSAGE_STATUS object:nil];
    
    [self updateMessageCount];
    
}

- (void)updateMessageCount
{
    NSInteger chat_unread_count = [WPNotificationCountDto sharedInstance].chat_unread_count;
    
    if(chat_unread_count > 0)
    {
        [messageButton setTitle:[NSString stringWithFormat:@"%ld",(long)chat_unread_count] forState:UIControlStateNormal];
        [messageButton setBackgroundImage:[UIImage imageNamed:@"camera_message"] forState:UIControlStateNormal];

    }
    else
    {
        [messageButton setTitle:@"" forState:UIControlStateNormal];
        [messageButton setBackgroundImage:[UIImage imageNamed:@"camera_left"] forState:UIControlStateNormal];

    }
    
    
    NSInteger friend_request_unread_count = [WPNotificationCountDto sharedInstance].friend_request_unread_count;
    if(friend_request_unread_count > 0)
    {
        [personButton setTitle:[NSString stringWithFormat:@"%ld",(long)friend_request_unread_count] forState:UIControlStateNormal];
        [personButton setBackgroundImage:[UIImage imageNamed:@"camera_request"] forState:UIControlStateNormal];
    }
    else
    {
        [personButton setTitle:@"" forState:UIControlStateNormal];
        [personButton setBackgroundImage:[UIImage imageNamed:@"camera_right"] forState:UIControlStateNormal];

    }
}


- (void)personButtonPressed:(UIButton*)sender
{
    [super rightButtonPressed:sender];
}

- (void)messageButtonPressed:(UIButton*)sender
{
    [super leftButtonPressed:sender];

}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
