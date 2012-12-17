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
#import "MJPopupViewController.h"

#define kPopupModalAnimationDuration 0.35

__strong MJPopupViewStyle _popupStyle = nil;
static NSMutableDictionary *_popupControllers = nil;
static NSNumber *_popupControllerId = nil;

static int _AddPopupController(NSArray *popupController) {
    if (_popupControllers == nil) {
        _popupControllers = [[NSMutableDictionary alloc] init];
        DDLogCVerbose(@"allocated popupControllers dictionary!");
    }
    int pid = [_popupControllerId intValue];
    _popupControllerId = @(pid+1);
    [_popupControllers setObject:popupController forKey:@(pid)];
    DDLogCVerbose(@"add popupController for %d", pid);
    return pid;
}

static void _RemovePopupControllerWithId (int pid) {
    DDLogCVerbose(@"remove popupController for %d", pid);
    [_popupControllers removeObjectForKey:@(pid)];
    if ([_popupControllers count] < 1) {
        _popupControllers = nil;
        _popupControllerId = nil;
        DDLogCVerbose(@"deallocated popupControllers dictionary!");
    }
}

static NSArray *_PopupControllerWithId (int pid) {
    return (NSArray *)[_popupControllers objectForKey:@(pid)];
}

@interface UIViewController (MJPopupViewControllerPrivate)
- (UIView*)topView;
- (void)didDismissPopup:(UIView *)popupView;
- (void)presentPopupView:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType contentInteraction:(MJPopupViewContentInteraction)contentInteraction;
@end



////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public

@implementation UIViewController (MJPopupViewController)

+ (void)setPopupStyle:(MJPopupViewStyle)style {
    _popupStyle = style;
}

- (void)presentPopupViewController:(UIViewController*)popupViewController {
    [self presentPopupViewController:popupViewController animationType:MJPopupViewAnimationSlideBottomBottom contentInteraction:MJPopupViewContentInteractionNone];
}
- (void)presentPopupViewController:(UIViewController*)popupViewController contentInteraction:(MJPopupViewContentInteraction)contentInteraction {
    [self presentPopupViewController:popupViewController animationType:MJPopupViewAnimationSlideBottomBottom contentInteraction:contentInteraction];
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
    
    if ([popupViewController respondsToSelector:@selector(setPopupParent:)]) {
        [(MJPopupViewController *)popupViewController setPopupParent:self];
    }
    
    [self presentPopupView:popupViewController animationType:animationType contentInteraction:contentInteraction];
}


- (void)dismissPopupViewController:(UIViewController*)popupViewController {
    [self dismissPopupViewController:popupViewController animationType:MJPopupViewAnimationSlideBottomBottom];
}
- (void)dismissPopupViewController:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType
{
    int popupId = popupViewController.view.tag;
    NSArray *popupInfo = _PopupControllerWithId(popupId);
    NSAssert(popupInfo!=nil, @"popupInfo can't be nil!");
    UIView *sourceView = (UIView *)popupInfo[1];
    UIView *overlayView = (UIView *)popupInfo[2];
    UIView *popupView = (UIView *)popupInfo[4];
    DDLogVerbose(@"dismissPopupViewController %d %@", popupId, popupInfo);
    
    if ([[self class] conformsToProtocol:@protocol(MJPopupViewDelegate)] && [self respondsToSelector:@selector(didDismissPopup:)]) {
        [self didDismissPopup:popupView];
    }
    
    [popupViewController viewWillDisappear:YES];
    
    switch (animationType) {
        case MJPopupViewAnimationSlideBottomTop:
        case MJPopupViewAnimationSlideBottomBottom:
        case MJPopupViewAnimationSlideRightLeft:
        case MJPopupViewAnimationSlideLeftRight:
            [self slideViewOut:popupViewController sourceView:sourceView overlayView:overlayView withAnimationType:animationType];
            break;
            
        default:
            [self fadeViewOut:popupViewController sourceView:sourceView overlayView:overlayView];
            break;
    }
}

- (void)dismissPopupViewControllerWithSender:(UIButton *)sender
{
    NSArray *popupInfo = _PopupControllerWithId(sender.tag);
    DDLogVerbose(@"dismissPopupViewControllerWithSender %d %@", sender.tag, popupInfo);
    [self dismissPopupViewController:(UIViewController *)popupInfo[0]];
}

////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark View Handling

- (void)presentPopupView:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType contentInteraction:(MJPopupViewContentInteraction)contentInteraction
{ 
    UIView *sourceView = [self topView];
    UIView *popupView = popupViewController.view;
    
    // check if source view controller is not in destination
    if ([sourceView.subviews containsObject:popupView]) return;
    
    [popupViewController viewWillAppear:YES];
    
    // customize popupView
    popupView.layer.shadowPath = [UIBezierPath bezierPathWithRect:popupView.bounds].CGPath;
    popupView.layer.masksToBounds = NO;
    popupView.layer.shadowOffset = CGSizeMake(5, 5);
    popupView.layer.shadowRadius = 5;
    popupView.layer.shadowOpacity = 0.5;
    
    if (_popupStyle != nil) {
        _popupStyle(popupView);
    }
    
    // Add semi overlay
    UIView *overlayView = [[UIView alloc] initWithFrame:sourceView.bounds];
    overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlayView.backgroundColor = [UIColor clearColor];
    
    // BackgroundView
    MJPopupBackgroundView *backgroundView = [[MJPopupBackgroundView alloc] initWithFrame:sourceView.bounds];
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    backgroundView.backgroundColor = [UIColor clearColor];
    backgroundView.alpha = 0.0f;
    [overlayView addSubview:backgroundView];
    
    // register
    NSArray *popupInfo = @[ popupViewController, sourceView, overlayView, backgroundView, popupView ];
    int popupId = _AddPopupController(popupInfo);
    sourceView.tag = popupId;
    overlayView.tag = popupId;
    backgroundView.tag = popupId;
    popupView.tag = popupId;
    DDLogVerbose(@"presentPopupView %d %@", popupId, popupInfo);
    
    // Make the Background Clickable
    UIButton * dismissButton = nil;
    if (contentInteraction != MJPopupViewContentInteractionNone) {
        dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
        dismissButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        dismissButton.backgroundColor = [UIColor clearColor];
        dismissButton.frame = sourceView.bounds;
        [dismissButton addTarget:self action:@selector(dismissPopupViewControllerWithSender:) forControlEvents:UIControlEventTouchUpInside];
        [overlayView addSubview:dismissButton];
        dismissButton.tag = popupId;
    }
    
    popupView.alpha = 0.0f;
    [overlayView addSubview:popupView];
    [sourceView addSubview:overlayView];
    
    // Make the Popup Clickable
    UIButton * dismissButton2 = nil;
    if (contentInteraction == MJPopupViewContentInteractionDismissEverywhere) {
        dismissButton2 = [UIButton buttonWithType:UIButtonTypeCustom];
        dismissButton2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        dismissButton2.backgroundColor = [UIColor clearColor];
        dismissButton2.frame = popupView.bounds;
        [dismissButton2 addTarget:self action:@selector(dismissPopupViewControllerWithSender:) forControlEvents:UIControlEventTouchUpInside];
        [overlayView addSubview:dismissButton2];
        dismissButton2.tag = popupId;
    }

    switch (animationType) {
        case MJPopupViewAnimationSlideBottomTop:
        case MJPopupViewAnimationSlideBottomBottom:
        case MJPopupViewAnimationSlideRightLeft:
        case MJPopupViewAnimationSlideLeftRight:
            [self slideViewIn:popupViewController sourceView:sourceView overlayView:overlayView withAnimationType:animationType];
            break;
        default:
            [self fadeViewIn:popupViewController sourceView:sourceView overlayView:overlayView];
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

//////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Animations

#pragma mark --- Slide

- (void)slideViewIn:(UIViewController*)popupViewController sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView withAnimationType:(MJPopupViewAnimation)animationType
{
    __block UIViewController *backupedPopupViewController = popupViewController;
    int popupId = popupViewController.view.tag;
    NSArray *popupInfo = _PopupControllerWithId(popupId);
    UIView *backgroundView = (UIView *)popupInfo[3];
    UIView *popupView = (UIView *)popupInfo[4];
    
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
    CGRect popupEndRect = popupView.frame;/* CGRectMake((sourceSize.width - popupSize.width) / 2,
                                     (sourceSize.height - popupSize.height) / 2,
                                     popupSize.width, 
                                     popupSize.height);*/
    
    // Set starting properties
    popupView.frame = popupStartRect;
    popupView.alpha = 1.0f;
    [UIView animateWithDuration:kPopupModalAnimationDuration delay:0.0f options:UIViewAnimationCurveEaseOut animations:^{
        backgroundView.alpha = 1.0f;
        popupView.frame = popupEndRect;
    } completion:^(BOOL finished) {
        if (finished) {
            [backupedPopupViewController viewDidAppear:YES];
        }
    }];
}

- (void)slideViewOut:(UIViewController*)popupViewController sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView withAnimationType:(MJPopupViewAnimation)animationType
{
    __block int popupId = popupViewController.view.tag;
    NSArray *popupInfo = _PopupControllerWithId(popupId);
    UIView *backgroundView = (UIView *)popupInfo[3];
    UIView *popupView = (UIView *)popupInfo[4];
    DDLogVerbose(@"slideViewOut %d %@", self.view.tag, popupInfo);
    
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
        if (finished) {
            [popupView removeFromSuperview];
            [overlayView removeFromSuperview];
            [popupViewController viewDidDisappear:YES];
            _RemovePopupControllerWithId(popupId);
        }
    }];
}

#pragma mark --- Fade

- (void)fadeViewIn:(UIViewController*)popupViewController sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView
{
    __block UIViewController *backupedPopupViewController = popupViewController;
    int popupId = popupViewController.view.tag;
    NSArray *popupInfo = _PopupControllerWithId(popupId);
    UIView *backgroundView = (UIView *)popupInfo[3];
    UIView *popupView = (UIView *)popupInfo[4];
    
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
        if (finished) {
            [backupedPopupViewController viewDidAppear:YES];
        }
    }];
}

- (void)fadeViewOut:(UIViewController*)popupViewController sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView
{
    __block int popupId = popupViewController.view.tag;
    NSArray *popupInfo = _PopupControllerWithId(popupId);
    UIView *backgroundView = (UIView *)popupInfo[3];
    UIView *popupView = (UIView *)popupInfo[4];
    
    [UIView animateWithDuration:kPopupModalAnimationDuration animations:^{
        backgroundView.alpha = 0.0f;
        popupView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        if (finished) {
            [popupView removeFromSuperview];
            [overlayView removeFromSuperview];
            [popupViewController viewDidDisappear:YES];
            _RemovePopupControllerWithId(popupId);
        }
    }];
}


@end
