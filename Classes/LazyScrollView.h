//
//  LazyScrollView.h
//  LazyScrollView
//
//  Created by xiabob on 16/12/22.
//  Copyright © 2016年 xiabob. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LSVRectModel;
@class LazyScrollView;

typedef NS_ENUM(NSUInteger, LazyScrollViewDirection) {
    LazyScrollViewDirectionHorizontal,
    LazyScrollViewDirectionVertical,
};


#pragma mark - LazyScrollViewDataSource

@protocol LazyScrollViewDataSource <NSObject>

@required
// ScrollView一共展示多少个item
- (NSUInteger)numberOfItemInScrollView:(LazyScrollView *)scrollView;
// 要求根据index直接返回RectModel
- (LSVRectModel *)scrollView:(LazyScrollView *)scrollView rectModelAtIndex:(NSUInteger)index;
// 返回下标所对应的view
- (UIView *)scrollView:(LazyScrollView *)scrollView itemByLsvId:(NSString *)lsvId;

@end

#pragma mark - LazyScrollViewDelegate

@protocol LazyScrollViewDelegate<UIScrollViewDelegate>

@optional
- (void)scrollView:(LazyScrollView *)scrollView didClickItemAtIndex:(NSUInteger)index;

@end


#pragma mark - LazyScrollView

@interface LazyScrollView : UIScrollView

@property (nonatomic, weak) id<LazyScrollViewDataSource> dataSource;
@property (nonatomic, weak) id<LazyScrollViewDelegate> delegate;

/**
 *  滚动方向
 *  暂时只支持 `LazyScrollViewDirectionVertical`
 */
//@property (nonatomic, assign) LazyScrollViewDirection direction;

- (void)reloadData;
- (UIView *)dequeueReusableItemWithIdentifier:(NSString *)identifier;
- (void)registerClass:(Class)viewClass forViewReuseIdentifier:(NSString *)identifier;

@end


#pragma mark - LSVRectModel

@interface LSVRectModel : NSObject
// view转换后的绝对值rect
@property (nonatomic, assign) CGRect absRect;

// 业务下标，如果初始化时没有提供，LSVRectModel内部会自动生成
@property (nonatomic, copy) NSString *lsvId;

+ (instancetype)modelWithRect:(CGRect)rect;
+ (instancetype)modelWithRect:(CGRect)rect lsvId:(NSString *)lsvId;

@end
