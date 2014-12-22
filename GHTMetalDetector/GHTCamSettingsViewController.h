//
//  GHTCamSettingsViewController.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 09.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GHTConstants.h"
#import "GHTComputeBuilder.h"
#import "GHTSettingsViewController.h"

@interface GHTCamSettingsViewController : GHTSettingsViewController
@property (nonatomic, assign) kVideoResolution videoResolution;
@property (nonatomic, assign) kVideoCamera videoCamera;
@end
