//
//  GHTHoughSpaceBuffer.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 26.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTBuffer.h"

@interface GHTHoughSpaceBuffer : GHTBuffer

@property (nonatomic, strong) id <MTLBuffer> houghBuffer;


- (instancetype)initWithLength:(NSUInteger)length;
- (void)purgeHoughSpaceBufferWithpurgeHoughSpaceBufferWithBlitCommandEncoder:(id <MTLBlitCommandEncoder>)blitCommandEncoder;
- (void)normalize;
- (void)debugPrintBuffer;
@end
