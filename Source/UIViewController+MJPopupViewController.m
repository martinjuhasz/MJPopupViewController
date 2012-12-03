//
//  UIViewController+MJPopupViewController.m
//  MJModalViewController
//
//  Created by Martin Juhasz on 11.05.12.
//  Copyright (c) 2012 martinjuhasz.de. All rights reserved.
//

#import "UIViewController+MJPopupViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MJPopupBackgroundView.h"

#define kPopupModalAnimationDuration 0.35
#define kMJSourceViewTag 23941
#define kMJPopupViewTag 23942
#define kMJBackgroundViewTag 23943
#define kMJOverlayViewTag 23945

__strong MJPopupViewStyle _popupStyle = nil;
__strong UIViewController *_popupViewController = nil;

@interface UIViewController (MJPopupViewControllerPrivate)
- (UIView*)topView;
- (void)didDismissPopup:(UIView *)popupView;
- (void)presentPopupView:(UIView*)popupView animationType:(MJPopupViewAnimation)animationType contentInteraction:(MJPopupViewContentInteraction)contentInteraction;
- (void)dismissPopupViewWithAnimationType:(MJPopupViewAnimation)animationType;
@end



////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public

@implementation UIViewController (MJPopupViewController)

+ (void)setPopupStyle:(MJPopupViewStyle)style {
    _popupStyle = style;
}

+ (UIViewController*)popupViewController {
    return _popupViewController;
}

- (void)presentPopupViewController:(UIViewController*)popupViewController {
    [self presentPopupViewController:popupViewController animationType:MJPopupViewAnimationSlideBottomBottom contentInteraction:MJPopupViewContentInteractionNone];
}
- (void)presentPopupViewController:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType contentInteraction:(MJPopupViewContentInteraction)contentInteraction
{
    if (popupViewController == nil) {
        DDLogError(@"presentPopupViewController: popupViewController == nil");
        return;
    }
    if (popupViewController.view == nil) {
        DDLogError(@"presentPopupViewController: popupViewController.view == nil");
        return;
    }
    
    _popupViewController = popupViewController;
    [self presentPopupView:popupViewController.view animationType:animationType contentInteraction:contentInteraction];
}


- (void)dismissPopupViewController {
    [self dismissPopupViewControllerWithAnimationType:MJPopupViewAnimationSlideBottomBottom];
}
- (void)dismissPopupViewControllerWithAnimationType:(MJPopupViewAnimation)animationType
{
    UIView *sourceView = [self topView];
    UIView *popupView = [sourceView viewWithTag:kMJPopupViewTag];
    UIView *overlayView = [sourceView viewWithTag:kMJOverlayViewTag];
    
    if ([[self class] conformsToProtocol:@protocol(MJPopupViewDelegate)] && [self respondsToSelector:@selector(didDismissPopup:)]) {
        [self didDismissPopup:popupView];
    }
    
    switch (animationType) {
        case MJPopupViewAnimationSlideBottomTop:
        case MJPopupViewAnimationSlideBottomBottom:
        case MJPopupViewAnimationSlideRightLeft:
        case MJPopupViewAnimationSlideLeftRight:
            [self slideViewOut:popupView sourceView:sourceView overlayView:overlayView withAnimationType:animationType];
            break;
            
        default:
            [self fadeViewOut:popupView sourceView:sourceView overlayView:overlayView];
            break;
    }
    _popupViewController = nil;
}

- (void)dismissPopupViewWithAnimationType:(MJPopupViewAnimation)animationType {
    [self dismissPopupViewControllerWithAnimationType:animationType];
}


////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark View Handling

- (void)presentPopupView:(UIView*)popupView animationType:(MJPopupViewAnimation)animationType contentInteraction:(MJPopupViewContentInteraction)contentInteraction
{
    UIView *sourceView = [self topView];
    sourceView.tag = kMJSourceViewTag;
    //popupView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin |UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    popupView.tag = kMJPopupViewTag;
    
    // check if source view controller is not in destination
    if ([sourceView.subviews containsObject:popupView]) return;
    
    // customize popupView
    popupView.layer.shadowPath = [UIBezierPath bezierPathWithRect:popupView.bounds].CGPath;
    popupView.layer.masksToBounds = NO;
    popupView.layer.shadowOffset = CGSizeMake(5, 5);
    popupView.layer.shadowRadius = 5;
    popupView.layer.shadowOpacity = 0.5;
    
    if (_popupStyle != nil) {
        _popupStyle (popupView);
    }
    
    // Add semi overlay
    UIView *overlayView = [[UIView alloc] initWithFrame:sourceView.bounds];
    overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlayView.tag = kMJOverlayViewTag;
    overlayView.backgroundColor = [UIColor clearColor];
    
    // BackgroundView
    MJPopupBackgroundView *backgroundView = [[MJPopupBackgroundView alloc] initWithFrame:sourceView.bounds];
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    backgroundView.tag = kMJBackgroundViewTag;
    backgroundView.backgroundColor = [UIColor clearColor];
    backgroundView.alpha = 0.0f;
    [overlayView addSubview:backgroundView];
    
    // Make the Background Clickable
    UIButton * dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    dismissButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    dismissButton.backgroundColor = [UIColor clearColor];
    dismissButton.frame = sourceView.bounds;
    [dismissButton addTarget:self action:@selector(dismissPopupViewControllerWithAnimation:) forControlEvents:UIControlEventTouchUpInside];
    [overlayView addSubview:dismissButton];
    
    popupView.alpha = 0.0f;
    [overlayView addSubview:popupView];
    [sourceView addSubview:overlayView];
    
    // Make the Popup Clickable
    UIButton * dismissButton2 = nil;
    if (contentInteraction == MJPopupViewContentInteractionDismiss) {
        dismissButton2 = [UIButton buttonWithType:UIButtonTypeCustom];
        dismissButton2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        dismissButton2.backgroundColor = [UIColor clearColor];
        dismissButton2.frame = popupView.bounds;
        [dismissButton2 addTarget:self action:@selector(dismissPopupViewControllerWithAnimation:) forControlEvents:UIControlEventTouchUpInside];
        [overlayView addSubview:dismissButton2];
    }

    switch (animationType) {
        case MJPopupViewAnimationSlideBottomTop:
        case MJPopupViewAnimationSlideBottomBottom:
        case MJPopupViewAnimationSlideRightLeft:
        case MJPopupViewAnimationSlideLeftRight:
            dismissButton.tag = animationType;
            dismissButton2.tag = animationType;
            [self slideViewIn:popupView sourceView:sourceView overlayView:overlayView withAnimationType:animationType];
            break;
        default:
            dismissButton.tag = MJPopupViewAnimationFade;
            dismissButton2.tag = MJPopupViewAnimationFade;
            [self fadeViewIn:popupView sourceView:sourceView overlayView:overlayView];
            break;
    }    
}

-(UIView*)topView {
    UIViewController *recentView = self;
    
    while (recentView.parentViewController != nil) {
        recentView = recentView.parentViewController;
    }
    return recentView.view;
}

- (void)dismissPopupViewControllerWithAnimation:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton* dismissButton = sender;
        switch (dismissButton.tag) {
            case MJPopupViewAnimationSlideBottomTop:
            case MJPopupViewAnimationSlideBottomBottom:
            case MJPopupViewAnimationSlideRightLeft:
            case MJPopupViewAnimationSlideLeftRight:
                [self dismissPopupViewControllerWithAnimationType:dismissButton.tag];
                break;
            default:
                [self dismissPopupViewControllerWithAnimationType:MJPopupViewAnimationFade];
                break;
        }
    } else {
        [self dismissPopupViewControllerWithAnimationType:MJPopupViewAnimationFade];
    }
}

//////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Animations

#pragma mark --- Slide

- (void)slideViewIn:(UIView*)popupView sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView withAnimationType:(MJPopupViewAnimation)animationType
{
    UIView *backgroundView = [overlayView viewWithTag:kMJBackgroundViewTag];
    // Generating Start and Stop Positions
    CGSize sourceSize = sourceView.bounds.size;
    CGSize popupSize = popupView.bounds.size;
    CGRect popupStartRect;
    switch (animationType) {
        case MJPopupViewAnimationSlideBottomTop:
        case MJPopupViewAnimationSlideBottomBottom:
            popupStartRect = CGRectMake((sourceSize.width - popupSize.width) / 2, 
                                        sourceSize.height, 
                                        popupSize.width, 
                                        popupSize.height);

            break;
        case MJPopupViewAnimationSlideLeftRight:
            popupStartRect = CGRectMake(-sourceSize.width, 
                                        (sourceSize.height - popupSize.height) / 2,
                                        popupSize.width, 
                                        popupSize.height);
            break;
            
        default:
            popupStartRect = CGRectMake(sourceSize.width, 
                                        (sourceSize.height - popupSize.height) / 2,
                                        popupSize.width, 
                                        popupSize.height);
            break;
    }        
    CGRect popupEndRect = CGRectMake((sourceSize.width - popupSize.width) / 2, 
                                     (sourceSize.height - popupSize.height) / 2,
                                     popupSize.width, 
                                     popupSize.height);
    
    // Set starting properties
    popupView.frame = popupStartRect;
    popupView.alpha = 1.0f;
    [UIView animateWithDuration:kPopupModalAnimationDuration delay:0.0f options:UIViewAnimationCurveEaseOut animations:^{
        backgroundView.alpha = 1.0f;
        popupView.frame = popupEndRect;
    } completion:^(BOOL finished) {
    }];
}

- (void)slideViewOut:(UIView*)popupView sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView withAnimationType:(MJPopupViewAnimation)animationType
{
    UIView *backgroundView = [overlayView viewWithTag:kMJBackgroundViewTag];
    // Generating Start and Stop Positions
    CGSize sourceSize = sourceView.bounds.size;
    CGSize popupSize = popupView.bounds.size;
    CGRect popupEndRect;
    switch (animationType) {
        case MJPopupViewAnimationSlideBottomTop:
            popupEndRect = CGRectMake((sourceSize.width - popupSize.width) / 2, 
                                      -popupSize.height, 
                                      popupSize.width, 
                                      popupSize.height);
            break;
        case MJPopupViewAnimationSlideBottomBottom:
            popupEndRect = CGRectMake((sourceSize.width - popupSize.width) / 2, 
                                      sourceSize.height, 
                                      popupSize.width, 
                                      popupSize.height);
            break;
        case MJPopupViewAnimationSlideLeftRight:
            popupEndRect = CGRectMake(sourceSize.width, 
                                      popupView.frame.origin.y, 
                                      popupSize.width, 
                                      popupSize.height);
            break;
        default:
            popupEndRect = CGRectMake(-popupSize.width, 
                                      popupView.frame.origin.y, 
                                      popupSize.width, 
                                      popupSize.height);
            break;
    }
    
    [UIView animateWithDuration:kPopupModalAnimationDuration delay:0.0f options:UIViewAnimationCurveEaseIn animations:^{
        popupView.frame = popupEndRect;
        backgroundView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [popupView removeFromSuperview];
        [overlayView removeFromSuperview];
    }];
}

#pragma mark --- Fade

- (void)fadeViewIn:(UIView*)popupView sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView
{
    UIView *backgroundView = [overlayView viewWithTag:kMJBackgroundViewTag];
    // Generating Start and Stop Positions
    CGSize sourceSize = sourceView.bounds.size;
    CGSize popupSize = popupView.bounds.size;
    CGRect popupEndRect = CGRectMake((sourceSize.width - popupSize.width) / 2, 
                                     (sourceSize.height - popupSize.height) / 2,
                                     popupSize.width, 
                                     popupSize.height);
    
    // Set starting properties
    popupView.frame = popupEndRect;
    popupView.alpha = 0.0f;
    
    [UIView animateWithDuration:kPopupModalAnimationDuration animations:^{
        backgroundView.alpha = 0.5f;
        popupView.alpha = 1.0f;
    } completion:^(BOOL finished) {
    }];
}

- (void)fadeViewOut:(UIView*)popupView sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView
{
    UIView *backgroundView = [overlayView viewWithTag:kMJBackgroundViewTag];
    [UIView animateWithDuration:kPopupModalAnimationDuration animations:^{
        backgroundView.alpha = 0.0f;
        popupView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [popupView removeFromSuperview];
        [overlayView removeFromSuperview];
    }];
}


@end
