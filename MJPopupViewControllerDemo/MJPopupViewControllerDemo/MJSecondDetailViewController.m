//
//  MJSecondDetailViewController.m
//  MJPopupViewControllerDemo
//
//  Created by Martin Juhasz on 24.06.12.
//  Copyright (c) 2012 martinjuhasz.de. All rights reserved.
//

#import "MJSecondDetailViewController.h"
#import "UIViewController+MJPopupViewController.h"

@interface MJSecondDetailViewController ()

@end

@implementation MJSecondDetailViewController

- (IBAction)dismissPopup:(id)sender {
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];

}

@end
