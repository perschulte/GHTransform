//
//  GHTImageInput.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 26.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTImageInput.h"

@implementation GHTImageInput

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    
    if (self)
    {
        self.width      = 0;
        self.height     = 0;
        self.format     = MTLPixelFormatRGBA8Unorm;
        self.target     = MTLTextureType2D;
        self.texture    = nil;
        _inputImage = image;
    }
    
    return self;
}

- (BOOL)finalize:(id<MTLDevice>)device
{
    if (!_inputImage)
    {
        NSLog(@"Error(%@): No image", self.class);
        return NO;
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (!colorSpace)
    {
        NSLog(@"Error(%@): Could not create colorspace", self.class);
        return NO;
    }
    
    self.width  = (uint32_t)CGImageGetWidth(self.inputImage.CGImage);
    self.height = (uint32_t)CGImageGetHeight(self.inputImage.CGImage);
    
    uint32_t width      = self.width;
    uint32_t height     = self.height;
    uint32_t rowBytes   = width * 4;
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 width,
                                                 height,
                                                 8,
                                                 rowBytes,
                                                 colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    if (!context)
    {
        NSLog(@"Error(%@): Could not create context", self.class);
        return NO;
    }
    
    CGRect bounds = CGRectMake(0.0f, 0.0f,  self.width,  self.height);
    
    CGContextClearRect(context, bounds);
    
    //Vertical reflect
    CGContextTranslateCTM(context, width, height);
    CGContextScaleCTM(context, -1.0, -1.0);
    
    
    CGContextDrawImage(context, bounds,  self.inputImage.CGImage);
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:width height:height mipmapped:NO];
    
    self.target     = textureDescriptor.textureType;
    self.texture    = [device newTextureWithDescriptor:textureDescriptor];
    
    textureDescriptor = nil;
    
    if(!self.texture)
    {
        CGContextRelease(context);
        NSLog(@"Error(%@): Could not create texture", self.class);
        return NO;
    }
    
    //Read pixel information from the context and place them on the texture
    const void *pixels = CGBitmapContextGetData(context);
    
    if (pixels != NULL)
    {
        MTLRegion region = MTLRegionMake2D(0, 0, width, height);
        [self.texture replaceRegion:region
                    mipmapLevel:0
                      withBytes:pixels
                    bytesPerRow:rowBytes];
    }
    
    CGContextRelease(context);
    
    return YES;
}
@end
