//
//  GHTQuad.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 28.07.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>

@interface GHTQuad : NSObject

//Indices
@property (nonatomic) NSUInteger vertexIndex;
@property (nonatomic) NSUInteger textureCoordinateIndex;

//Dimensions
@property (nonatomic) CGSize size;
@property (nonatomic) CGRect bounds;
@property (nonatomic, readonly) float aspect;

- (instancetype)initWithDevice:(id <MTLDevice>)device;

- (BOOL)update;

- (void)encode:(id <MTLRenderCommandEncoder>)renderEncoder;

@end
