//
//  GHTTexture.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 28.07.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTTexture.h"
#import <QuartzCore/QuartzCore.h>

@implementation GHTTexture

#pragma mark - Init
- (instancetype)initWithResourceName:(NSString *)name extension:(NSString *)extension
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name
                                                     ofType:extension];
    
    if (!path)
    {
        NSLog(@"Error(%@): The file(%@.%@) could not be loaded.", self.class, name, extension);
        return nil;
    }
    
    self = [super init];
    
    if (self)
    {
        _path       = path;
        _width      = 0;
        _height     = 0;
        _depth      = 1;
        _format     = MTLPixelFormatRGBA8Unorm;
        _target     = MTLTextureType2D;
        _texture    = nil;
        _hasAlpha   = YES;
        _flip       = NO;
    }
    
    return self;
}

- (void)dealloc
{
    _path       = nil;
    _texture    = nil;
}

#pragma mark - public

- (BOOL)finalize:(id<MTLDevice>)device
{
    UIImage *image = [UIImage imageWithContentsOfFile:_path];
    
    if (!image)
    {
        image = nil;
        NSLog(@"Error(%@): The image(%@) could not be loaded.", self.class, _path);
        return NO;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (!colorSpace)
    {
        image = nil;
        NSLog(@"Error(%@): Could not create colorspace", self.class);
        return NO;
    }
    
    _width  = (uint32_t)CGImageGetWidth(image.CGImage);
    _height = (uint32_t)CGImageGetHeight(image.CGImage);
    
    uint32_t width      = _width;
    uint32_t height     = _height;
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
    
    CGRect bounds = CGRectMake(0.0f, 0.0f, _width, _height);
    
    CGContextClearRect(context, bounds);
    
    //Vertical reflect
    if (_flip)
    {
        CGContextTranslateCTM(context, width, height);
        CGContextScaleCTM(context, -1.0, -1.0);
    }
    
    CGContextDrawImage(context, bounds, image.CGImage);
    
    image = nil;
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:width height:height mipmapped:NO];
    
    _target     = textureDescriptor.textureType;
    _texture    = [device newTextureWithDescriptor:textureDescriptor];

    textureDescriptor = nil;
    
    if(!_texture)
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
        [_texture replaceRegion:region
                    mipmapLevel:0
                      withBytes:pixels
                    bytesPerRow:rowBytes];
    }
    
    CGContextRelease(context);
    
    return YES;
}
@end
