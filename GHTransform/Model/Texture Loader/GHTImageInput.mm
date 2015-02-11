//
//  GHTImageInput.m
//  GHTransform
//
//  Created by Per Schulte on 26.11.14.
//
//  Copyright (c) 2015 Per Schulte
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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
