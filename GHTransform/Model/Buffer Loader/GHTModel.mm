//
//  GHTModel.mm
//  GHTransform
//
//  Created by Per Schulte on 02.08.14.
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


#import "GHTModel.h"


@implementation GHTModel

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
        self.path   = path;
        _offset     = 0;
    }
    
    return self;
}

- (void)dealloc
{
    _path       = nil;
    _buffer     = nil;
}

- (void)setDelegate:(id<GHTModelBufferDelegate>)delegate
{
    _delegate = delegate;
    if (_modelData)
    {
        [self.delegate didChangeDataWithLength:_length];
    }
}

- (void)setPath:(NSString *)path
{
    _path = path;
    self.modelData = [self loadModelData];
}

- (void)setModelData:(GHT::model *)modelData
{
    _modelData = modelData;
    
    if (self.delegate)
    {
        [self.delegate didChangeDataWithLength:_length];
    }
}

- (GHT::model *)loadModelData
{
    NSString *dataString = [NSString stringWithContentsOfFile:_path encoding:NSUTF8StringEncoding error:nil];
    
    if (!dataString)
    {
        NSLog(@"Error(%@): Failed to load the data string from file", self.class);
        dataString = nil;
        return nil;
    }
    
    NSArray *rawDataRowsArray = [dataString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *dataRowsArray = [NSMutableArray new];
    for (NSUInteger i = 0; i < rawDataRowsArray.count; i++)
    {
        if (![[rawDataRowsArray objectAtIndex:i] isEqualToString:@""])
        {
            [dataRowsArray addObject:[rawDataRowsArray objectAtIndex:i]];
        }
    }
    
    _length = (uint)dataRowsArray.count;
    
    GHT::model *dataModelArray = (GHT::model *)malloc(sizeof(GHT::model) * _length);
    
    for (int i = 0; i < _length; i++)
    {
        NSArray *entryArray = [[dataRowsArray objectAtIndex:i] componentsSeparatedByString:@" "];
        if ([entryArray count])
        {
            GHT::model model;
            model.referenceId   = [[entryArray objectAtIndex:0] intValue];
            model.x             = [[entryArray objectAtIndex:1] floatValue];
            model.y             = [[entryArray objectAtIndex:2] floatValue];
            model.phi           = [[entryArray objectAtIndex:3] floatValue];
            model.weight        = [[entryArray objectAtIndex:4] floatValue];
            dataModelArray[i]   = model;
        }
    }
    
    return dataModelArray;
}

- (BOOL)finalize:(id<MTLDevice>)device
{
    GHT::model *data = [self loadModelData];
    
    _buffer = [device newBufferWithBytes:data
                                  length:sizeof(GHT::model)*_length
                                 options:MTLResourceOptionCPUCacheModeDefault];
    _buffer.label = @"ModelBuffer";
    free(data);
    if(!_buffer)
    {
        NSLog(@"Error(%@): Could not create buffer", self.class);
        return NO;
    }

    return YES;
}

- (void)debugPrintModelArray:(GHT::model *)modelArray
{
    NSLog(@"%ld", sizeof(GHT::model));
    for (int i = 0 ; i < self.length; i++)
    {
        NSLog(@"%d", modelArray[i].referenceId);
    }
}

- (void)debugPrintModelArrayFromBuffer
{
    GHT::model *model = (GHT::model *)[_buffer contents];
    for (int i = 0 ; i < self.length; i++)
    {
        NSLog(@"%f", model[i].x);
    }
}
@end
