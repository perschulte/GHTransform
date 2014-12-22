//
//  GHTBuffer.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 26.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTBuffer.h"

@implementation GHTBuffer

- (BOOL)finalize:(id<MTLDevice>)device
{
    //No-op. Override in subclass
    
    return NO;
}

@end
