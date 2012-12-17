//
//  UIViewController+MJPopupViewController.h
//  MJModalViewController
//
//  Created by Martin Juhasz on 11.05.12.
//  Copyright (c) 2012 martinjuhasz.de. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    MJPopupViewAnimationSlideBottomTop = 1,
    MJPopupViewAnimationSlideRightLeft,
    MJPopupViewAnimationSlideLeftRight,
    MJPopupViewAnimationSlideBottomBottom,
    MJPopupViewAnimationFade
} MJPopupViewAnimation;

typedef enum {
    MJPopupViewContentInteractionNone = 1,
    MJPopupViewContentInteractionDismissEverywhere,
    MJPopupViewContentInteractionDismissBackgroundOnly,
} MJPopupViewContentInteraction;

typedef void(^MJPopupViewStyle)(UIView *view);

extern __strong MJPopupViewStyle _popupStyle;

@protocol MJPopupViewDelegate <NSObject>
- (void)didDismissPopup:(UIView *)popupView;
@end

@interface UIViewController (MJPopupViewController)
+ (void)setPopupStyle:(MJPopupViewStyle)style;

- (void)presentPopupViewController:(UIViewController*)popupViewController;
- (void)presentPopupViewController:(UIViewController*)popupViewController contentInteraction:(MJPopupViewContentInteraction)contentInteraction;
- (void)presentPopupViewController:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType contentInteraction:(MJPopupViewContentInteraction)contentInteraction;
- (void)dismissPopupViewController:(UIViewController*)popupViewController;
- (void)dismissPopupViewController:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType;
- (void)dismissPopupViewControllerWithSender:(UIButton *)sender;


@end