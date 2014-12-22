//
//  GHTContextViewController.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 09.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GHTFilterSettingsViewController.h"

@interface GHTContextViewController : UIViewController <GHTContextViewControllerDelegate>
@property (nonatomic, weak) GHTComputeBuilder *computeBuilder;
@end
