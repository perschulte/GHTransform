//
//  GHTRoundButtons.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 08.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTRoundButtons.h"
#import <QuartzCore/QuartzCore.h>

@implementation GHTRoundButtons

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.layer.cornerRadius = self.frame.size.height / 2.0;
}

@end
