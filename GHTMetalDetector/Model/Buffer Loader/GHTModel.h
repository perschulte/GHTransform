//
//  GHTModel.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 02.08.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface GHTModel : NSObject

@property (nonatomic, readonly) id <MTLBuffer>  buffer;
@property (nonatomic, readonly) NSString       *path;
@property (nonatomic, readwrite) NSUInteger     offset;
@property (nonatomic, readwrite) NSUInteger     length;
@property (nonatomic, readonly) uint            width;
@property (nonatomic, readonly) uint            height;

- (instancetype)initWithResourceName:(NSString *)name extension:(NSString *)extension;

- (BOOL)finalize:(id<MTLDevice>)device;

@end
