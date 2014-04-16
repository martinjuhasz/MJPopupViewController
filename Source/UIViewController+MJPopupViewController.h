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
    MJPopupViewAnimationSlideLeftLeft,
    MJPopupViewAnimationSlideRightRight,
    MJPopupViewAnimationFade
} MJPopupViewAnimation;

typedef enum {
    MJPopupViewContentInteractionNone = 1, // no tap interaction, dismiss manually or from outside
    MJPopupViewContentInteractionDismissEverywhere, // tapping the background or the viewcontroller will dismiss the popup
    MJPopupViewContentInteractionDismissBackgroundOnly, // only tapping the background will dismiss the popup
} MJPopupViewContentInteraction;

typedef void(^MJPopupViewStyle)(UIView *view);

extern __strong MJPopupViewStyle _popupStyle;
extern BOOL _phoneCompatibilityMode;
extern MJPopupViewAnimation _defaultAnimation;

/*! used to deliver events to an external delegate */
@protocol MJPopupViewDelegate <NSObject>
@optional
- (void)didDismissPopup:(UIView *)popupView;
- (void)didDismissPopupViewController:(UIViewController *)popupViewController;
@end

@interface UIViewController (MJPopupViewController)

/*! standard style applied to all popups, for example a set of instructions modifying the view's CALayer */
+ (void)setPopupStyle:(MJPopupViewStyle)style;

/*! default animation to be used when none is passed */
+ (void)setDefaultAnimation:(MJPopupViewAnimation)animation;

/*! makes sure the presented dialog does not exceed screen on iphone */
+ (void)setPhoneCompatibilityMode:(BOOL)state;

/*! set the class that should be used for background, can also be nil
 default is @ref MJPopupBackgroundView */
+ (void)setBackgroundViewClass:(Class)backgroundViewClass;

/*! disable use of background view */
+ (void)setUseBackgroundView:(BOOL)useBackgroundView;

/*! this block is processed for each new background view that is allocated */
+ (void)setBackgroundViewProcessor:(MJPopupViewStyle)processor;

/*! disable use of Overlay view (necessary, if using MJPopupViewController as a side menu) */
+ (void)setUseOverlayView:(BOOL)useOverlayView;

/*! present popup with standard animation (slide in and out from bottom) and standard content interaction MJPopupViewContentInteractionNone 
 @param popupViewController: instance of a UIViewController based class
 @remarks it is recommended to subclass MJPopupViewController */
- (void)presentPopupViewController:(UIViewController*)popupViewController;
/*! present popup with standard animation (slide in and out from bottom)
 @param popupViewController: instance of a UIViewController based class
 @param contentInteraction: @ref MJPopupViewContentInteraction value that determines how to handle taps on content and background
 @remarks it is recommended to subclass MJPopupViewController */
- (void)presentPopupViewController:(UIViewController*)popupViewController contentInteraction:(MJPopupViewContentInteraction)contentInteraction;
/*! present popup with standard animation (slide in and out from bottom)
 @param popupViewController: instance of a UIViewController based class
 @param animationType: @ref MJPopupViewAnimation value
 @param contentInteraction: @ref MJPopupViewContentInteraction value that determines how to handle taps on content and background
 @remarks it is recommended to subclass MJPopupViewController */
- (void)presentPopupViewController:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType contentInteraction:(MJPopupViewContentInteraction)contentInteraction;


/*! dismiss popup with standard animation (slide in and out from bottom)
 @param popupViewController: instance of a UIViewController based class to dismiss */
- (void)dismissPopupViewController:(UIViewController*)popupViewController;
/*! dismiss popup with standard animation (slide in and out from bottom)
 @param popupViewController: instance of a UIViewController based class to dismiss
 @param animationType: @ref MJPopupViewAnimation value */
- (void)dismissPopupViewController:(UIViewController*)popupViewController animationType:(MJPopupViewAnimation)animationType;
/*! dismiss the popupViewController from an control inside it
 @remarks stay away from this, only for internal use */
- (void)dismissPopupViewControllerWithSender:(UIButton *)sender;


@end