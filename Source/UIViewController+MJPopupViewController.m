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

#ifdef COCOAPODS_POD_AVAILABLE_CocoaLumberjack
    #import "DDLog.h"
    static const int ddLogLevel = LOG_LEVEL_WARN;
#else 
    #ifdef COCOAPODS_POD_AVAILABLE_StaticLumberjack
        #import "DDLog.h"
        static const int ddLogLevel = LOG_LEVEL_WARN;
    #endif
#endif

#define kPopupModalAnimationDuration 0.35

__strong MJPopupViewStyle _popupStyle = ^(UIView *view) {
    view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
    view.layer.masksToBounds = NO;
    view.layer.shadowOffset = CGSizeMake(5, 5);
    view.layer.shadowRadius = 5;
    view.layer.shadowOpacity = 0.5;
};
MJPopupViewAnimation _defaultAnimation = MJPopupViewAnimationSlideBottomBottom;
Class _backgroundViewClass = nil;
BOOL _useBackgroundView = YES;
BOOL _useOverlayView = YES;
__strong MJPopupViewStyle _backgroundViewProcessor = NULL;
BOOL _phoneCompatibilityMode = NO;

static NSMutableDictionary *_popupControllers = nil;
static NSNumber *_popupControllerId = nil;

static int _AddPopupController(NSArray *popupController) {
    if (_popupControllers == nil) {
        _popupControllers = [[NSMutableDictionary alloc] init];
        //DDLogCVerbose(@"allocated popupControllers dictionary!");
    }
    int pid = [_popupControllerId intValue];
    _popupControllerId = @(pid+1);
    [_popupControllers setObject:popupController forKey:@(pid)];
    //DDLogCVerbose(@"add popupController for %d", pid);
    return pid;
}

static void _RemovePopupControllerWithId (int pid) {
    //DDLogCVerbose(@"remove popupController for %d", pid);
    [_popupControllers removeObjectForKey:@(pid)];
    if ([_popupControllers count] < 1) {
        _popupControllers = nil;
        _popupControllerId = nil;
        //DDLogCVerbose(@"deallocated popupControllers dictionary!");
    }
}

static NSArray *_PopupControllerWithId (int pid) {
    return (NSArray *)[_popupControllers objectForKey:@(pid)];
}

@interface UIViewController (MJPopupViewControllerPrivate)
- (UIView*)topView;
- (void)didDismissPopup:(UIView *)popupView;
- (void)didDismissPopupViewController:(UIViewController *)popupViewController;
- (void)presentPopupView:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType contentInteraction:(MJPopupViewContentInteraction)contentInteraction;
@end



////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public

@implementation UIViewController (MJPopupViewController)

+ (void)setPopupStyle:(MJPopupViewStyle)style {
    _popupStyle = style;
}
+ (void)setPhoneCompatibilityMode:(BOOL)state {
    _phoneCompatibilityMode = state;
}
+ (void)setDefaultAnimation:(MJPopupViewAnimation)animation {
    _defaultAnimation = animation;
}
+ (void)setBackgroundViewClass:(Class)backgroundViewClass {
    _backgroundViewClass = backgroundViewClass;
}
+ (void)setUseBackgroundView:(BOOL)useBackgroundView {
    _useBackgroundView = useBackgroundView;
}
+ (void)setBackgroundViewProcessor:(MJPopupViewStyle)processor {
    _backgroundViewProcessor = processor;
}
+ (void)setUseOverlayView:(BOOL)useOverlayView {
    _useOverlayView = useOverlayView;
}
- (void)presentPopupViewController:(UIViewController*)popupViewController {
    [self presentPopupViewController:popupViewController animationType:_defaultAnimation contentInteraction:MJPopupViewContentInteractionNone];
}
- (void)presentPopupViewController:(UIViewController*)popupViewController contentInteraction:(MJPopupViewContentInteraction)contentInteraction {
    [self presentPopupViewController:popupViewController animationType:_defaultAnimation contentInteraction:contentInteraction];
}
- (void)presentPopupViewController:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType contentInteraction:(MJPopupViewContentInteraction)contentInteraction
{
    if (popupViewController == nil) {
#ifdef COCOAPODS_POD_AVAILABLE_CocoaLumberjack
        DDLogError(@"presentPopupViewController: popupViewController == nil");
#endif
#ifdef COCOAPODS_POD_AVAILABLE_StaticLumberjack
        DDLogError(@"presentPopupViewController: popupViewController == nil");
#endif
        return;
    }
    if (popupViewController.view == nil) {
#ifdef COCOAPODS_POD_AVAILABLE_CocoaLumberjack
        DDLogError(@"presentPopupViewController: popupViewController.view == nil");
#endif
#ifdef COCOAPODS_POD_AVAILABLE_StaticLumberjack
        DDLogError(@"presentPopupViewController: popupViewController.view == nil");
#endif
        return;
    }
    
    if ([popupViewController respondsToSelector:@selector(setPopupParent:)]) {
        [(MJPopupViewController *)popupViewController setPopupParent:self];
    }
    
    [self presentPopupView:popupViewController animationType:animationType contentInteraction:contentInteraction];
}


- (void)dismissPopupViewController:(UIViewController*)popupViewController {
    [self dismissPopupViewController:popupViewController animationType:_defaultAnimation];
}
- (void)dismissPopupViewController:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType
{
    int popupId = popupViewController.view.tag;
    NSArray *popupInfo = _PopupControllerWithId(popupId);
    //NSAssert(popupInfo!=nil, @"popupInfo can't be nil!");
    UIView *sourceView = (UIView *)popupInfo[1];
    UIView *overlayView = (UIView *)popupInfo[2];
    UIView *popupView = (UIView *)popupInfo[3];
    //DDLogVerbose(@"dismissPopupViewController %d %@", popupId, popupInfo);
    
    [popupViewController viewWillDisappear:YES];
    
    switch (animationType) {
        case MJPopupViewAnimationSlideBottomTop:
        case MJPopupViewAnimationSlideBottomBottom:
        case MJPopupViewAnimationSlideLeftLeft:
        case MJPopupViewAnimationSlideLeftRight:
        case MJPopupViewAnimationSlideRightRight:
        case MJPopupViewAnimationSlideRightLeft:
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
    MJPopupViewAnimation animation = (MJPopupViewAnimation)[((NSNumber *)popupInfo[4]) intValue];
    //DDLogVerbose(@"dismissPopupViewControllerWithSender %d %@", sender.tag, popupInfo);
    [self dismissPopupViewController:(UIViewController *)popupInfo[0] animationType:animation];
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
    
    if (_popupStyle != nil) {
        _popupStyle(popupView);
    }
    
    [popupViewController viewWillAppear:YES];
    
    // Add semi overlay
    UIView *overlayView = [[UIView alloc] initWithFrame:sourceView.bounds];
    overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlayView.backgroundColor = [UIColor clearColor];
    overlayView.userInteractionEnabled = _useOverlayView;
    
    // BackgroundView
    UIView *backgroundView = nil;
    if (_useBackgroundView) {
        if (!_backgroundViewClass) {
            _backgroundViewClass = [MJPopupBackgroundView class];
        }
        NSAssert([_backgroundViewClass isSubclassOfClass:[UIView class]], @"_backgroundViewClass is not a subclass of UIView");
        backgroundView = (UIView *)[[[_backgroundViewClass class] alloc] initWithFrame:sourceView.bounds];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        backgroundView.backgroundColor = [UIColor clearColor];
        backgroundView.alpha = 0.0f ;
        if (_backgroundViewProcessor != NULL) {
            _backgroundViewProcessor(backgroundView);
        }
        [overlayView addSubview:backgroundView];
    }

    // register
    NSArray *popupInfo = nil;
    if (backgroundView) {
        popupInfo = @[
                      popupViewController,  // 0
                      sourceView,           // 1
                      overlayView,          // 2
                      popupView,            // 3
                      @(animationType),     // 4
                      backgroundView        // 5
                      ];
    }
    else {
        popupInfo = @[ popupViewController, sourceView, overlayView, popupView, @(animationType) ];
    }
    int popupId = _AddPopupController(popupInfo);
    sourceView.tag = popupId;
    overlayView.tag = popupId;
    if (backgroundView) {
        backgroundView.tag = popupId;
    }
    popupView.tag = popupId;
    //DDLogVerbose(@"presentPopupView %d %@", popupId, popupInfo);
    
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
    
    if (_useOverlayView)
    {
        // common setting
        [overlayView addSubview:popupView];
        [sourceView addSubview:overlayView];
    }
    else
    {
        // popupview as sidemenu
        [sourceView addSubview:popupView];
    }

    
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
        case MJPopupViewAnimationSlideLeftLeft:
        case MJPopupViewAnimationSlideRightRight:
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
    __weak UIViewController *backupedPopupViewController = popupViewController;
    int popupId = popupViewController.view.tag;
    NSArray *popupInfo = _PopupControllerWithId(popupId);
    UIView *popupView = (UIView *)popupInfo[3];
    UIView *backgroundView = [popupInfo count] > 5 ? (UIView *)popupInfo[5] : nil;
    
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
        case MJPopupViewAnimationSlideRightRight:
        case MJPopupViewAnimationSlideRightLeft:
            popupStartRect = CGRectMake(sourceSize.width,
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
    
    if (_phoneCompatibilityMode) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            if (popupEndRect.origin.y < 0) {
                popupEndRect.size.height += popupEndRect.origin.y;
                popupEndRect.origin.y = 0;
            }
            if (![[UIApplication sharedApplication] isStatusBarHidden]) {
                popupEndRect.origin.y += 20;
            }
        }
    }
    
    if ([popupViewController conformsToProtocol:@protocol(MJPopupViewControllerDelegate)]) {
        id<MJPopupViewControllerDelegate> mjPopupViewController = (id<MJPopupViewControllerDelegate>)popupViewController;
        if (mjPopupViewController.providesPopupEndRect) {
            popupEndRect = mjPopupViewController.popupEndRect;
        }
        if (mjPopupViewController.providesPopupStartRect) {
            popupStartRect = mjPopupViewController.popupStartRect;
        }
    }
    
    // Set starting properties
    popupView.frame = popupStartRect;
    popupView.alpha = 1.0f;
    [UIView animateWithDuration:kPopupModalAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        if (backgroundView) {
            backgroundView.alpha = 1.0f;
        }
        popupView.frame = popupEndRect;
    } completion:^(BOOL finished) {
        if (finished) {
            [backupedPopupViewController viewDidAppear:YES];
        }
    }];
}

- (void)slideViewOut:(UIViewController*)popupViewController sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView withAnimationType:(MJPopupViewAnimation)animationType
{
    __weak UIViewController* weakPopupViewController = popupViewController;
    __weak int popupId = popupViewController.view.tag;
    NSArray *popupInfo = _PopupControllerWithId(popupId);
    UIView *popupView = (UIView *)popupInfo[3];
    UIView *backgroundView = [popupInfo count] > 5 ? (UIView *)popupInfo[5] : nil;
    //DDLogVerbose(@"slideViewOut %d %@", self.view.tag, popupInfo);
    
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
        case MJPopupViewAnimationSlideRightRight:
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
    
    if ([popupViewController conformsToProtocol:@protocol(MJPopupViewControllerDelegate)]) {
        id<MJPopupViewControllerDelegate> mjPopupViewController = (id<MJPopupViewControllerDelegate>)popupViewController;
        if (mjPopupViewController.providesPopupStartRect) {
            popupEndRect = mjPopupViewController.popupStartRect;
        }
    }
    
    [UIView animateWithDuration:kPopupModalAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        popupView.frame = popupEndRect;
        if (backgroundView) {
            backgroundView.alpha = 0.0f;
        }
    } completion:^(BOOL finished) {
        if (finished) {
            [popupView removeFromSuperview];
            [overlayView removeFromSuperview];
            [weakPopupViewController didDismissPopupViewController:weakPopupViewController];
            [weakPopupViewController didDismissPopup:popupView];
            [weakPopupViewController viewDidDisappear:YES];
            _RemovePopupControllerWithId(popupId);
        }
    }];
}

#pragma mark --- Fade

- (void)fadeViewIn:(UIViewController*)popupViewController sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView
{
    __weak UIViewController *backupedPopupViewController = popupViewController;
    int popupId = popupViewController.view.tag;
    NSArray *popupInfo = _PopupControllerWithId(popupId);
    UIView *popupView = (UIView *)popupInfo[3];
    UIView *backgroundView = [popupInfo count] > 5 ? (UIView *)popupInfo[5] : nil;
    
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
        if (backgroundView) {
            backgroundView.alpha = 0.5f;
        }
        popupView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        if (finished) {
            [backupedPopupViewController viewDidAppear:YES];
        }
    }];
}

- (void)fadeViewOut:(UIViewController*)popupViewController sourceView:(UIView*)sourceView overlayView:(UIView*)overlayView
{
    __weak UIViewController* weakPopupViewController = popupViewController;
    __weak int popupId = popupViewController.view.tag;
    NSArray *popupInfo = _PopupControllerWithId(popupId);
    UIView *popupView = (UIView *)popupInfo[3];
    UIView *backgroundView = [popupInfo count] > 5 ? (UIView *)popupInfo[5] : nil;
    
    [UIView animateWithDuration:kPopupModalAnimationDuration animations:^{
        if (backgroundView) {
            backgroundView.alpha = 0.0f;
        }
        popupView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        if (finished) {
            [popupView removeFromSuperview];
            [overlayView removeFromSuperview];
            [weakPopupViewController didDismissPopupViewController:weakPopupViewController];
            [weakPopupViewController didDismissPopup:popupView];
            [weakPopupViewController viewDidDisappear:YES];
            _RemovePopupControllerWithId(popupId);
        }
    }];
}
- (void)didDismissPopup:(UIView *)popupView {
    if ([[self class] conformsToProtocol:@protocol(MJPopupViewDelegate)]) {
        if ([self respondsToSelector:@selector(didDismissPopup:)]) {
            [self didDismissPopup:popupView];
        }
    }
}

- (void)didDismissPopupViewController:(UIViewController *)popupViewController {
    if ([[self class] conformsToProtocol:@protocol(MJPopupViewDelegate)]) {
        if ([self respondsToSelector:@selector(didDismissPopupViewController:)]) {
            [self didDismissPopupViewController:popupViewController];
        }
    }
}

@end
