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
#import <objc/runtime.h>

#define kPopupModalAnimationDuration 0.35
#define kMJPopupViewController @"kMJPopupViewController"
#define kMJPopupBackgroundView @"kMJPopupBackgroundView"
#define kMJSourceViewTag 23941
#define kMJPopupViewTag 23942
#define kMJOverlayViewTag 23945

@interface UIViewController (MJPopupViewControllerPrivate)
- (UIView*)topView;
- (void)presentPopupView:(UIView*)popupView;
@end


////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public

@implementation UIViewController (MJPopupViewController)

static void * const keypath = (void*)&keypath;

- (UIViewController*)mj_popupViewController {
    return objc_getAssociatedObject(self, kMJPopupViewController);
}

- (void)setMj_popupViewController:(UIViewController *)mj_popupViewController {
    objc_setAssociatedObject(self, kMJPopupViewController, mj_popupViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

- (MJPopupBackgroundView*)mj_popupBackgroundView {
    return objc_getAssociatedObject(self, kMJPopupBackgroundView);
}

- (void)setMj_popupBackgroundView:(MJPopupBackgroundView *)mj_popupBackgroundView {
    objc_setAssociatedObject(self, kMJPopupBackgroundView, mj_popupBackgroundView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

- (void)presentPopupViewController:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType
{
    self.mj_popupViewController = popupViewController;
    [self presentPopupView:popupViewController.view animationType:animationType];
}

- (void)dismissPopupViewControllerWithanimationType:(MJPopupViewAnimation)animationType
{
    UIView *sourceView = [self topView];
    UIView *popupView = [sourceView viewWithTag:kMJPopupViewTag];
    UIView *overlayView = [sourceView viewWithTag:kMJOverlayViewTag];
    
    switch (animationType) {
        case MJPopupViewAnimationSlideBottomTop:
        case MJPopupViewAnimationSlideBottomBottom:
        case MJPopupViewAnimationSlideTopTop:
        case MJPopupViewAnimationSlideTopBottom:
        case MJPopupViewAnimationSlideLeftLeft:
        case MJPopupViewAnimationSlideLeftRight:
        case MJPopupViewAnimationSlideRightLeft:
        case MJPopupViewAnimationSlideRightRight:
            [self slideViewOut:popupView sourceView:sourceView overlayView:overlayView withAnimationType:animationType];
            break;
            
        default:
            [self fadeViewOut:popupView sourceView:sourceView overlayView:overlayView];
            break;
    }
    self.mj_popupViewController = nil;
}



////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark View Handling

- (void)presentPopupView:(UIView*)popupView animationType:(MJPopupViewAnimation)animationType
{
    UIView *sourceView = [self topView];
    sourceView.tag = kMJSourceViewTag;
    popupView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin |UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    popupView.tag = kMJPopupViewTag;
    
    // check if source view controller is not in destination
    if ([sourceView.subviews containsObject:popupView]) return;
    
    // customize popupView
    popupView.layer.shadowPath = [UIBezierPath bezierPathWithRect:popupView.bounds].CGPath;
    popupView.layer.masksToBounds = NO;
    popupView.layer.shadowOffset = CGSizeMake(5, 5);
    popupView.layer.shadowRadius = 5;
    popupView.layer.shadowOpacity = 0.5;
    
    // Add semi overlay
    UIView *overlayView = [[UIView alloc] initWithFrame:sourceView.bounds];
    overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlayView.tag = kMJOverlayViewTag;
    overlayView.backgroundColor = [UIColor clearColor];
    
    // BackgroundView
    self.mj_popupBackgroundView = [[MJPopupBackgroundView alloc] initWithFrame:sourceView.bounds];
    self.mj_popupBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mj_popupBackgroundView.backgroundColor = [UIColor clearColor];
    self.mj_popupBackgroundView.alpha = 0.0f;
    [overlayView addSubview:self.mj_popupBackgroundView];
    
    // Make the Background Clickable
    UIButton * dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    dismissButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    dismissButton.backgroundColor = [UIColor clearColor];
    dismissButton.frame = sourceView.bounds;
    [overlayView addSubview:dismissButton];
    
    popupView.alpha = 0.0f;
    [overlayView addSubview:popupView];
    [sourceView addSubview:overlayView];
    
    [dismissButton addTarget:self action:@selector(dismissPopupViewControllerWithanimation:) forControlEvents:UIControlEventTouchUpInside];
    switch (animationType) {
        case MJPopupViewAnimationSlideBottomTop:
        case MJPopupViewAnimationSlideBottomBottom:
        case MJPopupViewAnimationSlideTopTop:
        case MJPopupViewAnimationSlideTopBottom:
        case MJPopupViewAnimationSlideLeftLeft:
        case MJPopupViewAnimationSlideLeftRight:
        case MJPopupViewAnimationSlideRightLeft:
        case MJPopupViewAnimationSlideRightRight:
            dismissButton.tag = animationType;
            [self slideViewIn:popupView sourceView:sourceView overlayView:overlayView withAnimationType:animationType];
            break;
        default:
            dismissButton.tag = MJPopupViewAnimationFade;
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

- (void)dismissPopupViewControllerWithanimation:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton* dismissButton = sender;
        switch (dismissButton.tag) {
            case MJPopupViewAnimationSlideBottomTop:
            case MJPopupViewAnimationSlideBottomBottom:
            case MJPopupViewAnimationSlideTopTop:
            case MJPopupViewAnimationSlideTopBottom:
            case MJPopupViewAnimationSlideLeftLeft:
            case MJPopupViewAnimationSlideLeftRight:
            case MJPopupViewAnimationSlideRightLeft:
            case MJPopupViewAnimationSlideRightRight:
                [self dismissPopupViewControllerWithanimationType:dismissButton.tag];
                break;
            default:
                [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
                break;
        }
    } else {
        [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    }
}

//////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Animations

#pragma mark --- Slide

- (void)slideViewIn:(UIView*)popupView sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView withAnimationType:(MJPopupViewAnimation)animationType
{
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
        case MJPopupViewAnimationSlideLeftLeft:
        case MJPopupViewAnimationSlideLeftRight:
            popupStartRect = CGRectMake(-sourceSize.width,
                                        (sourceSize.height - popupSize.height) / 2,
                                        popupSize.width,
                                        popupSize.height);
            break;
            
        case MJPopupViewAnimationSlideTopTop:
        case MJPopupViewAnimationSlideTopBottom:
            popupStartRect = CGRectMake((sourceSize.width - popupSize.width) / 2,
                                        -popupSize.height,
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
    [UIView animateWithDuration:kPopupModalAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.mj_popupViewController viewWillAppear:NO];
        self.mj_popupBackgroundView.alpha = 1.0f;
        popupView.frame = popupEndRect;
    } completion:^(BOOL finished) {
        [self.mj_popupViewController viewDidAppear:NO];
    }];
}

- (void)slideViewOut:(UIView*)popupView sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView withAnimationType:(MJPopupViewAnimation)animationType
{
    // Generating Start and Stop Positions
    CGSize sourceSize = sourceView.bounds.size;
    CGSize popupSize = popupView.bounds.size;
    CGRect popupEndRect;
    switch (animationType) {
        case MJPopupViewAnimationSlideBottomTop:
        case MJPopupViewAnimationSlideTopTop:
            popupEndRect = CGRectMake((sourceSize.width - popupSize.width) / 2,
                                      -popupSize.height,
                                      popupSize.width,
                                      popupSize.height);
            break;
        case MJPopupViewAnimationSlideBottomBottom:
        case MJPopupViewAnimationSlideTopBottom:
            popupEndRect = CGRectMake((sourceSize.width - popupSize.width) / 2,
                                      sourceSize.height,
                                      popupSize.width,
                                      popupSize.height);
            break;
        case MJPopupViewAnimationSlideLeftRight:
        case MJPopupViewAnimationSlideRightRight:
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
    
    [UIView animateWithDuration:kPopupModalAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        [self.mj_popupViewController viewWillDisappear:NO];
        popupView.frame = popupEndRect;
        self.mj_popupBackgroundView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [popupView removeFromSuperview];
        [overlayView removeFromSuperview];
        [self.mj_popupViewController viewDidDisappear:NO];
        self.mj_popupViewController = nil;
    }];
}

#pragma mark --- Fade

- (void)fadeViewIn:(UIView*)popupView sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView
{
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
        [self.mj_popupViewController viewWillAppear:NO];
        self.mj_popupBackgroundView.alpha = 0.5f;
        popupView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [self.mj_popupViewController viewDidAppear:NO];
    }];
}

- (void)fadeViewOut:(UIView*)popupView sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView
{
    [UIView animateWithDuration:kPopupModalAnimationDuration animations:^{
        [self.mj_popupViewController viewWillDisappear:NO];
        self.mj_popupBackgroundView.alpha = 0.0f;
        popupView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [popupView removeFromSuperview];
        [overlayView removeFromSuperview];
        [self.mj_popupViewController viewDidDisappear:NO];
        self.mj_popupViewController = nil;
    }];
}


@end
