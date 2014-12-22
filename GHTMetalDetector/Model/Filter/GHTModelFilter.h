//
//  GHTModelFilter.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 24.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GHTFilter.h"
#import "GHTModel.h"
#import "GHTParameter.h"

@interface GHTModelFilter : GHTFilter

@property (nonatomic, strong) GHTModel *modelBuffer;
@property (nonatomic, strong) GHTParameter *parameter;

- (void)addModelKernelToComputeEncoder:(id <MTLComputeCommandEncoder>)computeEncoder
                         outputTexture:(id <MTLTexture>)outTexture;
@end
