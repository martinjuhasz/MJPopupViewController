//
//  MJPopupViewController.h
//  Pods
//
//  Created by Andreas Zeitler on 30.11.12.
//
//

#import <UIKit/UIKit.h>

/*!
 @class MJPopupViewController
 @abstract base class for any view controller you want to display as a popup using the MJPopupViewController extension (it is recommended to use this base class but not required)
 */
@interface MJPopupViewController : UIViewController

@property (nonatomic,readwrite,strong) UIViewController *popupParent;
- (BOOL) providesPopupStartRect;
- (CGRect) popupStartRect;
- (BOOL) providesPopupEndRect;
- (CGRect) popupEndRect;

- (void)dismissPopupViewController;

@end
