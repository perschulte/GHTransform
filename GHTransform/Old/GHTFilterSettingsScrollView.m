//
//  GHTFilterSettingsScrollView.m
//  GHTMetalDetector
//
//  Created by Per Schulte on 08.12.14.
//  Copyright (c) 2014 de.launchair. All rights reserved.
//

#import "GHTFilterSettingsScrollView.h"
#import "GHTRoundButtons.h"

static const float kSmallButtonSize  = 50.0f;
static const float kBigButtonSize  = 100.0f;
static const float kLevelWidth  = 200.0f;
static const float kBigHorizontalSpacing  = 100.0f;
static const float kSmallHorizontalSpacing  = 50.0f;
static const float kVerticalSpacing  = 8.0f;

@interface GHTFilterSettingsScrollView ()

@property (nonatomic, strong) GHTRoundButtons *camInputButton;
@property (nonatomic, strong) GHTRoundButtons *imgInputButton;
@property (nonatomic, strong) GHTRoundButtons *nextStageButton;

@property (nonatomic, strong) NSDictionary *metrics;
@property (nonatomic, strong) NSMutableDictionary *stages;
@property (nonatomic, strong) NSString *lastStageName;
@end

@implementation GHTFilterSettingsScrollView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        _metrics = @{@"smallButtonSize"         :@50.0,
                     @"bigButtonSize"           :@100,
                     @"levelWidth"              :@200,
                     @"bigHorizontalSpacing"    :@100,
                     @"smallHorizontalSpacing"  :@50,
                     @"verticalSpacing"         :@8};
        _stages = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)start
{
    for (UIView *subview in self.subviews)
    {
        [subview removeFromSuperview];
    }
    
    _stages = [NSMutableDictionary new];
    

    
    _camInputButton = [self camInputButton];
    _imgInputButton = [self imageInputButton];
    _nextStageButton = [self nextStageButton];
    
    [self addSubview:_camInputButton];
    [self addSubview:_imgInputButton];
    [self addSubview:_nextStageButton];
    
    [self addNextStage:@"Input" firstView:_camInputButton];
    [self addNextView:_imgInputButton toStage:@"Input"];
    [self addNextStage:@"Filter" firstView:_nextStageButton];
    
}

- (GHTRoundButtons *)imageInputButton
{
    GHTRoundButtons *button = [self buttonWithTitle:@"Image"];
    [button addTarget:self action:@selector(imgButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (GHTRoundButtons *)camInputButton
{
    GHTRoundButtons *button = [self buttonWithTitle:@"Cam"];
    [button addTarget:self action:@selector(camButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (GHTRoundButtons *)nextStageButton
{
    return [self buttonWithTitle:@"+"];
}

- (GHTRoundButtons *)buttonWithTitle:(NSString *)titleText
{
    GHTRoundButtons *inputButton = [GHTRoundButtons buttonWithType:UIButtonTypeCustom];
    [inputButton setTitle:titleText forState:UIControlStateNormal];
    [inputButton setBackgroundColor:[UIColor lightGrayColor]];
    inputButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *viewsDictionary = @{@"button":inputButton};
    
    NSArray *constraintsV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[button(bigButtonSize)]" options:0 metrics:_metrics views:viewsDictionary];
    NSArray *constraintsH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[button(bigButtonSize)]" options:0 metrics:_metrics views:viewsDictionary];

    [inputButton addConstraints:constraintsV];
    [inputButton addConstraints:constraintsH];
    return inputButton;
}

#pragma mark - Layout

- (void)addNextView:(UIView *)view toStage:(NSString *)stageName
{
    NSDictionary *viewsDictionary = @{@"previousView":[_stages objectForKey:stageName], @"nextView":view};
    
    NSArray *constraintsV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[previousView]-verticalSpacing-[nextView]" options:NSLayoutFormatAlignAllCenterX metrics:_metrics views:viewsDictionary];
    
    [self addConstraints:constraintsV];
    
    [_stages setObject:view forKey:stageName];
}

- (void)addNextStage:(NSString *)stageName firstView:(UIView *)view
{
    if (_lastStageName)
    {
        NSDictionary *viewsDictionary = @{@"previousStageView":[_stages objectForKey:_lastStageName], @"nextStageView":view};
    
        NSArray *constraintsH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousStageView]-bigHorizontalSpacing-[nextStageView]" options:0 metrics:_metrics views:viewsDictionary];
        [self addConstraints:constraintsH];
        
        NSArray *constraintsV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[nextStageView]-|" options:NSLayoutFormatAlignAllCenterY metrics:_metrics views:viewsDictionary];
        [self addConstraints:constraintsV];
        
    } else
    {
        NSDictionary *viewsDictionary = @{@"view":view};
        
        NSArray *constraintsH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-verticalSpacing-[view]" options:0 metrics:_metrics views:viewsDictionary];
        [self addConstraints:constraintsH];

        NSArray *constraintsV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[view]-|" options:NSLayoutFormatAlignAllCenterY metrics:_metrics views:viewsDictionary];
        [self addConstraints:constraintsV];
        
    }
    
    [_stages setObject:view forKey:stageName];
    _lastStageName = [stageName copy];
}

#pragma mark - Button handling

- (void)camButtonPressed:(UIButton *)sender
{

}

- (void)imgButtonPressed:(id)sender
{
    
}
@end
