//
//  GHTRenderer.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 21.10.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface GHTRenderer : NSObject

@property (nonatomic, readonly) id <MTLDevice> device;

@end
