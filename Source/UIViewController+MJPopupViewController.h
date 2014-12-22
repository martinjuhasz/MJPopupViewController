//
//  UIViewController+MJPopupViewController.h
//  MJModalViewController
//
//  Created by Martin Juhasz on 11.05.12.
//  Copyright (c) 2012 martinjuhasz.de. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "MJPopupBackgroundView.h"
#import <objc/runtime.h>
#import "ConstantValues.h"
#import "NSMutableArray+QueueAddition.h"
#import "Logging.h"

@class MJPopupBackgroundView;

typedef enum {
    MJPopupViewAnimationFade = 0,
    MJPopupViewAnimationSlideBottomTop = 1,
    MJPopupViewAnimationSlideBottomBottom,
    MJPopupViewAnimationSlideTopTop,
    MJPopupViewAnimationSlideTopBottom,
    MJPopupViewAnimationSlideLeftLeft,
    MJPopupViewAnimationSlideLeftRight,
    MJPopupViewAnimationSlideRightLeft,
    MJPopupViewAnimationSlideRightRight,
} MJPopupViewAnimation;

@interface UIViewController (MJPopupViewController)

@property (nonatomic, retain) UIViewController *mj_popupViewController;
@property (nonatomic, retain) MJPopupBackgroundView *mj_popupBackgroundView;

- (void)presentPopupViewController:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType;
- (void)presentPopupViewController:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType dismissed:(void(^)(void))dismissed;
- (void)presentPopupViewController:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType dismissed:(void(^)(void))dismissed backgroundActive:(Boolean*)backgroundActive;

- (void)presentPopupView:(UIView*)popupView animationType:(MJPopupViewAnimation)animationType dismissed:(void(^)(void))dismissed backgroundActive:(Boolean*)backgroundActive;
- (void)dismissPopupViewControllerWithanimationType:(MJPopupViewAnimation)animationType;
- (void)dismissPopupViewControllerWithanimationTypeIfPresent:(MJPopupViewAnimation)animationType;
- (UIView*)topView;
-(void) clearPopupQueue;

@end
