//
//  GHTInputImageCollectionViewCell.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 27.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTInputImageCollectionViewCell.h"

@interface GHTInputImageCollectionViewCell ()
@property (nonatomic, strong) IBOutlet UIImageView *inputImageView;
@property (nonatomic, strong) IBOutlet UILabel *widthLabel;
@property (nonatomic, strong) IBOutlet UILabel *heigthLabel;
@end

@implementation GHTInputImageCollectionViewCell

- (void)setAsset:(ALAsset *)asset
{
    _asset = asset;
    self.inputImageView.image = [UIImage imageWithCGImage:[asset thumbnail]];
    
    CGImageRef imageRef = [asset.defaultRepresentation fullResolutionImage];
    _image = [UIImage imageWithCGImage:imageRef];
    
    self.widthLabel.text = [NSString stringWithFormat:@"w:%ld", CGImageGetWidth(imageRef)];
    self.heigthLabel.text = [NSString stringWithFormat:@"h:%ld", CGImageGetHeight(imageRef)];
}

@end
