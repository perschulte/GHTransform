//
//  GHTView.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 28.07.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTView.h"
#import <QuartzCore/CAMetalLayer.h>

@implementation GHTView

+(Class)layerClass
{
    return [CAMetalLayer class];
}
@end
