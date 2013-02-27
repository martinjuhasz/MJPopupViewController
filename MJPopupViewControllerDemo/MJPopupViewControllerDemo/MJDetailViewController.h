//
//  MJDetailViewController.h
//  MJPopupViewControllerDemo
//
//  Created by Martin Juhasz on 24.06.12.
//  Copyright (c) 2012 martinjuhasz.de. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MJDetailViewController : UIViewController <UITextFieldDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UITextField *textfield;

@end
