//
//  FiltersViewController.h
//
//
//  Created by wangyong on 15-5-20.
//  Copyright (c) 2014年 Whisper. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WPBaseVideoFiltersViewController.h"

@protocol MessageVideoFiltersViewControllerDelegate
- (void)imageFilterReturn:(UIImage*)image image_pire:(NSString*)image_pire image_from:(NSString*)image_from;
@end

@interface WPMessageVideoFiltersViewController : WPBaseVideoFiltersViewController

+ (instancetype)sharedInstance;

- (void)setCameraEnable:(BOOL)enable;
- (id)initWithUserID:(NSString*)user_id;
- (id)initWithAppID:(NSString*)user_id;
@property (nonatomic, assign) id delegate;

@property (nonatomic, copy) NSString *name;

- (id)initWithDelegate:(id<MessageVideoFiltersViewControllerDelegate>) delegate;
@end
