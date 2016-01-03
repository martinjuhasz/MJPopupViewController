# MJPopupViewController

A UIViewController Category to display a ViewController as a popup with different transition effects.

Written by [Martin Juhasz](http://martinjuhasz.de), June 2012.

**Note: You should no longer use this category since it's outdated and there are more modern approaches for facing this problem.** (f.e. [SLPopupViewController](https://github.com/sunlight3d/SLPopupViewController))


## Installation

Just drop the files under `Source` into your Xcode project.
Also you need to add the QuartzCore-Framework to your project.


## Usage

First you have to import the category

	#import "UIViewController+MJPopupViewController.h"
	
then simply use `presentPopupViewController:animationType`, f.e.:
	
	[self presentPopupViewController:detailViewController animationType:MJPopupViewAnimationFade];
	
to dismiss the popup, use `dismissPopupViewControllerWithanimationType`
	
	[self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
	
see the demo for more detailed examples



## Demo

You can open the `MJPopupViewControllerDemo` demo project in Xcode and run it on your iPhone as well as in the Simulator.

<img src="https://raw.github.com/martinjuhasz/MJPopupViewController/master/assets/demo1.png" width="320" height="480"/>
<img src="https://raw.github.com/martinjuhasz/MJPopupViewController/master/assets/demo2.png" width="330" height="480"/>


## Issues and Feature Requests

Please report issues via GitHub's issue tracker.


## ARC

This version is made using Automated Reference Counting.


## TODO

- Rotation Support
- More animation types
- support different background types
