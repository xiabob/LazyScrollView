//
//  LazyScrollView.m
//  LazyScrollView
//
//  Created by xiabob on 16/12/22.
//  Copyright © 2016年 xiabob. All rights reserved.
//

#import "LazyScrollView.h"
#import <objc/runtime.h>

CGFloat const kBufferSize = 20;


#pragma mark - UIView (LSV)

static char kAssociatedObjectKeylsvId;
static char kAssociatedObjectKeyReuseIdentifier;

@interface UIView (LSV)

// 索引过的标识，在LazyScrollView范围内唯一
@property (nonatomic, copy) NSString  *lsvId;
// 重用的ID
@property (nonatomic, copy) NSString *reuseIdentifier;

@end

@implementation UIView (LSV)
- (NSString *)lsvId {
    return objc_getAssociatedObject(self, &kAssociatedObjectKeylsvId);
}

- (void)setLsvId:(NSString *)lsvId {
    objc_setAssociatedObject(self, &kAssociatedObjectKeylsvId, lsvId, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)reuseIdentifier {
    return objc_getAssociatedObject(self, &kAssociatedObjectKeyReuseIdentifier);
}

- (void)setReuseIdentifier:(NSString *)reuseIdentifier {
    objc_setAssociatedObject(self, &kAssociatedObjectKeyReuseIdentifier, reuseIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end


#pragma mark - LazyScrollView

@interface LazyScrollView () <UIScrollViewDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet *> *reuseViewPool;
@property (nonatomic, strong) NSMutableSet<__kindof UIView *> *visibleViews;

@property (nonatomic, strong) NSMutableArray<LSVRectModel *> *allRectModels;
@property (nonatomic, strong) NSMutableArray<LSVRectModel *> *allAscendingRectModels; //按照view顶部的y升序排列allRectModels
@property (nonatomic, strong) NSMutableArray<LSVRectModel *> *allDescendingRectModels; //按照view底部的y降序排列allRectModels

@property (nonatomic, assign) NSUInteger numberOfItems;

@property (nonatomic, strong) NSMutableDictionary<NSString *,Class> *registerClass;

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@end

@implementation LazyScrollView

@dynamic delegate; //消除警告

- (instancetype)init {
    if (self = [super init]) {
        [self addGestureRecognizer:self.tapGesture];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    NSMutableArray *newVisibleViews = [self getVisiableViewModels].mutableCopy;
    NSMutableArray *newVisibleLsvIds = [newVisibleViews valueForKey:@"lsvId"];
    NSMutableArray *removeViews = [NSMutableArray array];
    for (UIView *view in self.visibleViews) {
        if (![newVisibleLsvIds containsObject:view.lsvId]) {
            [removeViews addObject:view];
        }
    }
    
    for (UIView *view in removeViews) {
        [self.visibleViews removeObject:view];
        [self enqueueReusableView:view];
        view.hidden = YES;
    }
    
    NSMutableArray *alreadyVisibles = [self.visibleViews valueForKey:@"lsvId"];
    
    for (LSVRectModel *model in newVisibleViews) {
        if ([alreadyVisibles containsObject:model.lsvId]) {
            continue;
        }
        UIView *view = [self.dataSource scrollView:self itemByLsvId:model.lsvId];
        view.frame = model.absRect;
        view.lsvId = model.lsvId;
        view.hidden = NO;
        
        [self.visibleViews addObject:view];
        [self addSubview:view];
    }
    
}

- (void)reloadData {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.visibleViews removeAllObjects];
    [self.reuseViewPool removeAllObjects];
    
    [self updateModelDatas];
}

- (void)enqueueReusableView:(UIView *)view {
    if (!view.reuseIdentifier) {
        return;
    }
    
    NSString *identifier = view.reuseIdentifier;
    NSMutableSet *reuseSet = self.reuseViewPool[identifier];
    if (!reuseSet) {
        reuseSet = [NSMutableSet set];
        [self.reuseViewPool setValue:reuseSet forKey:identifier];
    }
    [reuseSet addObject:view];
}

- (UIView *)dequeueReusableItemWithIdentifier:(NSString *)identifier {
    if (!identifier) {
        return nil;
    }
    NSMutableSet *reuseSet = self.reuseViewPool[identifier];
    UIView *view = [reuseSet anyObject];
    if (view) {
        [reuseSet removeObject:view];
        return view;
    }
    else {
        Class viewClass = [self.registerClass objectForKey:identifier];
        view = [viewClass new];
        view.reuseIdentifier = identifier;
        return view;
    }
}

- (void)registerClass:(Class)viewClass forViewReuseIdentifier:(NSString *)identifier {
    [self.registerClass setValue:viewClass forKey:identifier];
}

#pragma mark - Utils

- (CGFloat)minEdgeOffset {
    //for UIScrollView the bounds cahnge when scroll
    CGFloat min = CGRectGetMinY(self.bounds);
    return MAX(min - kBufferSize, 0);
}

- (CGFloat)maxEdgeOffset {
    //for UIScrollView the bounds cahnge when scroll
    CGFloat max = CGRectGetMaxY(self.bounds);
    return MIN(max + kBufferSize, self.contentSize.height);
}

- (LSVRectModel *)findFirstAscendModelWithMinEdge:(CGFloat)minEdge {
    // 二分法
    NSInteger minIndex = 0;
    NSInteger maxIndex = self.allAscendingRectModels.count - 1;
    NSInteger midIndex = (minIndex + maxIndex) / 2;
    LSVRectModel *model = self.allAscendingRectModels[midIndex];
    
    while (minIndex < midIndex && midIndex < maxIndex) {
        if (CGRectGetMinY(model.absRect) > minEdge) {
            maxIndex = midIndex;
        }
        else {
            minIndex = midIndex;
        }
        midIndex = (minIndex + maxIndex) / 2;
        model = self.allAscendingRectModels[midIndex];
    }
    
    //处理多个view的y值相同的情况
    LSVRectModel *limitModel = model;
    while (midIndex > 0 && CGRectGetMinY(model.absRect) == CGRectGetMinY(limitModel.absRect)) {
        midIndex = MAX(midIndex - 1, 0);
        model = self.allAscendingRectModels[midIndex];
    }
    
    return model;
}

- (LSVRectModel *)findFirstDescendModelWithMaxEdge:(CGFloat)maxEdge {
    // 二分法
    NSInteger minIndex = 0;
    NSInteger maxIndex = self.allDescendingRectModels.count - 1;
    NSInteger midIndex = (minIndex + maxIndex) / 2;
    LSVRectModel *model = self.allDescendingRectModels[midIndex];
    
    while (minIndex < midIndex && midIndex < maxIndex) {
        if (CGRectGetMaxY(model.absRect) < maxEdge) {
            maxIndex = midIndex;
        }
        else {
            minIndex = midIndex;
        }
        midIndex = (minIndex + maxIndex) / 2;
        model = self.allDescendingRectModels[midIndex];
    }
    
    //处理多个view的y值相同的情况
    LSVRectModel *limitModel = model;
    while (midIndex > 0 && CGRectGetMaxY(model.absRect) == CGRectGetMaxY(limitModel.absRect)) {
        midIndex = MAX(midIndex - 1, 0);
        model = self.allDescendingRectModels[midIndex];
    }
    
    return model;
}

- (NSArray *)getVisiableViewModels {
    // Descend e-----------------|s
    //         --------------------------- Y值
    //                     s|------------e Ascend
    // 实际就是两个firstIndex的交叉部分
    LSVRectModel *firstAscendModel  = [self findFirstAscendModelWithMinEdge:[self minEdgeOffset]];
    LSVRectModel *firstDescendModel = [self findFirstDescendModelWithMaxEdge:[self maxEdgeOffset]];
    
    NSInteger firstIndex = [self.allAscendingRectModels indexOfObject:firstAscendModel];
    NSInteger lastIndex  = [self.allAscendingRectModels indexOfObject:firstDescendModel];
    
    return [self.allAscendingRectModels subarrayWithRange:NSMakeRange(firstIndex, lastIndex-firstIndex+1)];
}

- (void)updateModelDatas {
    [self.allRectModels removeAllObjects];
    self.allAscendingRectModels = nil;
    self.allDescendingRectModels = nil;
    
    _numberOfItems = [self.dataSource numberOfItemInScrollView:self];
    
    for (NSInteger index = 0; index < _numberOfItems; ++ index) {
        LSVRectModel *model = [self.dataSource scrollView:self rectModelAtIndex:index];
        [self.allRectModels addObject:model];
    }
    
    LSVRectModel *model = self.allAscendingRectModels.lastObject;
    self.contentSize = CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetMaxY(model.absRect));
}

- (void)handleTapAction:(UIGestureRecognizer *)gestureRecognizer {
    NSArray *visibleViews = [self getVisiableViewModels];
    CGPoint tapPoint = [gestureRecognizer locationInView:self];
    for (LSVRectModel *model in visibleViews) {
        if (CGRectContainsPoint(model.absRect, tapPoint)) {
            if ([self.delegate respondsToSelector:@selector(scrollView:didClickItemAtIndex:withLsvId:)]) {
                NSInteger index = [self.allRectModels indexOfObject:model];
                [self.delegate scrollView:self didClickItemAtIndex:index withLsvId:model.lsvId];
            }
            
            break;
        }
    }
}

#pragma mark - Setter

- (void)setDataSource:(id<LazyScrollViewDataSource>)dataSource {
    if (dataSource != _dataSource) {
        _dataSource = dataSource;
    }
    if (_dataSource) {
        [self reloadData];
    }
}

#pragma mark - Getter
- (NSMutableDictionary *)reuseViewPool {
    if (!_reuseViewPool) {
        _reuseViewPool = [NSMutableDictionary new];
    }
    return _reuseViewPool;
}

- (NSMutableArray *)allRectModels {
    if (!_allRectModels) {
        _allRectModels = [NSMutableArray new];
    }
    return _allRectModels;
}

- (NSMutableArray *)allAscendingRectModels {
    if (!_allAscendingRectModels) {
        //升序
        _allAscendingRectModels = [[self.allRectModels
                                    sortedArrayUsingComparator:^NSComparisonResult(LSVRectModel *obj1, LSVRectModel *obj2) {
                                        CGFloat y1 = CGRectGetMaxY(obj1.absRect); CGFloat x1 = CGRectGetMinX(obj1.absRect);
                                        CGFloat y2 = CGRectGetMaxY(obj2.absRect); CGFloat x2 = CGRectGetMinX(obj2.absRect);
                                        if (y1 == y2) {
                                            return x1 <= x2 ? NSOrderedAscending: NSOrderedDescending;
                                        } else {
                                            return y1 < y2 ? NSOrderedAscending : NSOrderedDescending;
                                        } }
                                    ] mutableCopy];
    }
    
    return _allAscendingRectModels;
}

- (NSMutableArray *)allDescendingRectModels {
    if (!_allDescendingRectModels) {
        //需要降序，而sortedArrayUsingComparator的结果是ascending order，所以block里面的结果是相反的。
        _allDescendingRectModels = [[self.allRectModels
                                     sortedArrayUsingComparator:^NSComparisonResult(LSVRectModel *obj1, LSVRectModel *obj2) {
                                         CGFloat y1 = CGRectGetMaxY(obj1.absRect); CGFloat x1 = CGRectGetMinX(obj1.absRect);
                                         CGFloat y2 = CGRectGetMaxY(obj2.absRect); CGFloat x2 = CGRectGetMinX(obj2.absRect);
                                         if (y1 == y2) {
                                             return x1 <= x2 ? NSOrderedDescending : NSOrderedAscending;
                                         } else {
                                             return y1 < y2 ? NSOrderedDescending : NSOrderedAscending;
                                         }
                                     }
                                     ] mutableCopy];
    }
    
    return _allDescendingRectModels;
}

- (NSMutableDictionary *)registerClass {
    if (!_registerClass) {
        _registerClass = [NSMutableDictionary new];
    }
    return _registerClass;
}

- (NSMutableSet *)visibleViews {
    if (!_visibleViews) {
        _visibleViews = [NSMutableSet set];
    }
    return _visibleViews;
}

- (UITapGestureRecognizer *)tapGesture {
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                              action:@selector(handleTapAction:)];
    }
    
    return _tapGesture;
}

@end


#pragma mark - LSVRectModel

@implementation LSVRectModel

+ (instancetype)modelWithRect:(CGRect)rect lsvId:(NSString *)lsvId {
    LSVRectModel *model = [[LSVRectModel alloc] init];
    model.absRect = rect;
    
    if (lsvId.length == 0) {
        lsvId = NSStringFromCGRect(rect);
    }
    model.lsvId = lsvId;
    
    return model;
}

+ (instancetype)modelWithRect:(CGRect)rect  {
    return [self modelWithRect:rect lsvId:nil];
}

@end



