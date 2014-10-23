//
//  GHTModel.mm
//  GHTMetalDetector
//
//  Created by Per Schulte on 02.08.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTModel.h"
#import "GHTSharedTypes.h"

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
        _path       = path;
        _offset     = 0;
    }
    
    return self;
}

- (void)dealloc
{
    _path       = nil;
    _buffer     = nil;
}

- (GHT::model *)referenceData
{
    NSString *dataString = [NSString stringWithContentsOfFile:_path encoding:NSUTF8StringEncoding error:nil];
    
    if (!dataString)
    {
        NSLog(@"Error(%@): Failed to load the data string from file", self.class);
        dataString = nil;
        return nil;
    }
    
    NSArray *dataRowsArray = [dataString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    _length = (uint)dataRowsArray.count;
    
    GHT::model *dataModelArray = (GHT::model *)malloc(sizeof(GHT::model) * _length);
    
    for (int i = 0; i < _length; i++)
    {
        NSArray *entryArray = [[dataRowsArray objectAtIndex:i] componentsSeparatedByString:@" "];
        
        GHT::model model;
        model.referenceId   = [[entryArray objectAtIndex:0] intValue];
        model.x             = [[entryArray objectAtIndex:1] floatValue];
        model.y             = [[entryArray objectAtIndex:2] floatValue];
        model.phi           = [[entryArray objectAtIndex:3] floatValue];
        model.weight        = [[entryArray objectAtIndex:4] floatValue];
        model.length        = (int)_length;
        model.size          = {0,0}; // TODO: Set source image size
        dataModelArray[i]   = model;
    }
    
    return dataModelArray;
}

- (BOOL)finalize:(id<MTLDevice>)device
{
    GHT::model *data = [self referenceData];
    
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
    for (int i = 0 ; i < modelArray[0].length; i++)
    {
        NSLog(@"%d", modelArray[i].referenceId);
    }
}

- (void)debugPrintModelArrayFromBuffer
{
    GHT::model *model = (GHT::model *)[_buffer contents];
    for (int i = 0 ; i < model[0].length; i++)
    {
        NSLog(@"%f", model[i].x);
    }
}
@end
