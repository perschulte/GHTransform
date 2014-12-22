//
//  GHTBuffer.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 26.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

@interface GHTBuffer : NSObject

@property (nonatomic, readwrite) id <MTLBuffer> buffer;
@property (nonatomic, readwrite) NSUInteger offset;
@property (nonatomic, readwrite) NSUInteger length;

- (BOOL)finalize:(id<MTLDevice>)device;
@end
