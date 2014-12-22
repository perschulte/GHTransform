//
//  GHTInput.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 26.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <UIKit/UIKit.h>
#import <simd/simd.h>

@protocol GHTInputDelegate <NSObject>

- (void)didChangeResolutionTo:(simd::uint2)size;

@end

@interface GHTInput :NSObject
@property (nonatomic, weak) id <GHTInputDelegate> delegate;
@property (nonatomic, readwrite) id <MTLTexture> texture;
@property (nonatomic, readwrite) MTLTextureType  target;
@property (nonatomic, readwrite) uint32_t        width;
@property (nonatomic, readwrite) uint32_t        height;
@property (nonatomic, readwrite) uint32_t        format;

- (BOOL)finalize:(id<MTLDevice>)device;

@end
