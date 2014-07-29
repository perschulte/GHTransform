//
//  GHTTexture.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 28.07.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <UIKit/UIKit.h>

@interface GHTTexture : NSObject

@property (nonatomic, readonly) id <MTLTexture> texture;
@property (nonatomic, readonly) MTLTextureType  target;
@property (nonatomic, readonly) uint32_t        width;
@property (nonatomic, readonly) uint32_t        height;
@property (nonatomic, readonly) uint32_t        depth;
@property (nonatomic, readonly) uint32_t        format;
@property (nonatomic, readonly) NSString        *path;
@property (nonatomic, readonly) BOOL            hasAlpha;
@property (nonatomic, readwrite)BOOL            flip;

- (instancetype)initWithResourceName:(NSString *)name extension:(NSString *)extension;

- (BOOL)finalize:(id<MTLDevice>)device;

@end
