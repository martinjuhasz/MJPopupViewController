//
//  MJPopupViewController.m
//  Pods
//
//  Created by Andreas Zeitler on 30.11.12.
//
//

#import "MJPopupViewController.h"
#import "UIViewController+MJPopupViewController.h"

@interface MJPopupViewController ()

@end

@implementation MJPopupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissPopupViewController {
    [[self popupParent] dismissPopupViewController:self];
}

- (BOOL) providesPopupStartRect { return NO; }
- (CGRect) popupStartRect { return self.view.frame; }
- (BOOL) providesPopupEndRect { return NO; }
- (CGRect) popupEndRect { return self.view.frame; }

@end
