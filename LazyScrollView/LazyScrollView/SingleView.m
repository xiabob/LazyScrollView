//
//  SingleView.m
//  LazyScrollView
//
//  Created by xiabob on 16/12/22.
//  Copyright © 2016年 xiabob. All rights reserved.
//

#import "SingleView.h"

NSString * const kViewIdfSingle1 = @"kViewIdfSingle1";
NSString * const kViewIdfSingle2 = @"kViewIdfSingle2";
NSString * const kViewIdfSingle3 = @"kViewIdfSingle3";
NSString * const kViewIdfSingle4 = @"kViewIdfSingle4";
NSString * const kViewIdfSingle5 = @"kViewIdfSingle5";

@interface SingleView ()
@property (nonatomic, strong) UILabel *title;
@end

@implementation SingleView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    
    self.backgroundColor = [self randomColor];
    
    [self addSubview:self.title];
    
    self.title.frame = CGRectMake(0, 0, 100, 50);
}

- (UIColor *)randomColor {
    CGFloat hue = ( arc4random() % 361 / 360.0 );
    CGFloat saturation = ( arc4random() % 101 / 100.0 );
    CGFloat brightness = ( arc4random() % 101 / 100.0 );
    //hsb
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

#pragma mark - setter

- (void)setData:(NSString *)data {
    _data = data;
    self.title.text = data;
}

#pragma mark - getter

- (UILabel *)title {
    if (!_title) {
        _title = [UILabel new];
        _title.font = [UIFont systemFontOfSize:13.f];
        _title.textColor = [UIColor whiteColor];
    }
    return _title;
}

@end

