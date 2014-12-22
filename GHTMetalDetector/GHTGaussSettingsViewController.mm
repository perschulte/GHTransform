//
//  GHTGaussSettingsViewController.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 09.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTGaussSettingsViewController.h"
#import "GHTGaussFilter.h"

@interface GHTGaussSettingsViewController ()

@end

@implementation GHTGaussSettingsViewController

- (IBAction)onlyGaussFilterPressed:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        if(((UISwitch *)sender).on)
        {
            [self.computeBuilder addGaussFilter];
            
        } else{
            [self.computeBuilder addDefaultFilters];
        }
    }
}

@end
