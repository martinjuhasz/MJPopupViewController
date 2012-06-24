//
//  MJViewController.m
//  MJPopupViewControllerDemo
//
//  Created by Martin Juhasz on 24.06.12.
//  Copyright (c) 2012 martinjuhasz.de. All rights reserved.
//

#import "MJViewController.h"
#import "UIViewController+MJPopupViewController.h"
#import "MJDetailViewController.h"
#import "MJSecondDetailViewController.h"

@interface MJViewController () <MJSecondPopupDelegate>{
    MJSecondDetailViewController *secondDetailViewController;
}
@end

@implementation MJViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)fadeIn:(id)sender
{
    MJDetailViewController *detailViewController = [[MJDetailViewController alloc] initWithNibName:@"MJDetailViewController" bundle:nil];
    [self presentPopupViewController:detailViewController animationType:MJPopupViewAnimationFade];
}

- (IBAction)slideInBottomBottom:(id)sender
{
    MJDetailViewController *detailViewController = [[MJDetailViewController alloc] initWithNibName:@"MJDetailViewController" bundle:nil];
    [self presentPopupViewController:detailViewController animationType:MJPopupViewAnimationSlideBottomBottom];
}

- (IBAction)slideInBottomTop:(id)sender
{
    MJDetailViewController *detailViewController = [[MJDetailViewController alloc] initWithNibName:@"MJDetailViewController" bundle:nil];
    [self presentPopupViewController:detailViewController animationType:MJPopupViewAnimationSlideBottomTop];
}

- (IBAction)slideInRightLeft:(id)sender
{
    MJDetailViewController *detailViewController = [[MJDetailViewController alloc] initWithNibName:@"MJDetailViewController" bundle:nil];
    [self presentPopupViewController:detailViewController animationType:MJPopupViewAnimationSlideRightLeft];
}



// This is just a sample how you could use a popup when you need some userinteraction in it. Use a ivar so it gets not dealloced after fade in
- (IBAction)popupWithUserInteraction:(id)sender
{
    secondDetailViewController = nil;
    secondDetailViewController = [[MJSecondDetailViewController alloc] initWithNibName:@"MJSecondDetailViewController" bundle:nil];
    secondDetailViewController.delegate = self;
    [self presentPopupViewController:secondDetailViewController animationType:MJPopupViewAnimationFade];
}

- (void)cancelButtonClicked:(MJSecondDetailViewController *)aSecondDetailViewController
{
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
    secondDetailViewController = nil;
}

@end
