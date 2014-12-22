//
//  GHTPhiSettingsViewController.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 17.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTPhiSettingsViewController.h"

@implementation GHTPhiSettingsViewController

- (IBAction)onlyGaussFilterPressed:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        if(((UISwitch *)sender).on)
        {
            [self.computeBuilder addPhiFilter];
            
        } else{
            [self.computeBuilder addDefaultFilters];
        }
    }
}
@end
