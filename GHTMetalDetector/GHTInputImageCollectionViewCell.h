//
//  GHTInputImageCollectionViewCell.h
//  GHTMetalDetector
//
//  Created by Per Schulte on 27.11.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface GHTInputImageCollectionViewCell : UICollectionViewCell
@property (nonatomic, strong) ALAsset *asset;
@property (nonatomic, readonly) UIImage *image;
@end
