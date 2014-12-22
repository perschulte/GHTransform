//
//  GHTHoughSpaceToTextureFilter.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 03.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTFilter.h"
#import "GHTParameter.h"
#import "GHTHoughSpaceBuffer.h"

@interface GHTHoughSpaceToTextureFilter : GHTFilter

@property (nonatomic, strong) GHTParameter          *parameterBuffer;
@property (nonatomic, strong) GHTHoughSpaceBuffer   *inHoughSpaceBuffer;
@property (nonatomic, strong) id <MTLTexture>       outHoughSpaceTexture;

- (void)addHoughSpaceKernelToComputeEncoder:(id <MTLComputeCommandEncoder>)computeEncoder
                                   inBuffer:(id <MTLBuffer>)houghSpaceBuffer
                              outputTexture:(id <MTLTexture>)houghSpaceTexture;

@end
