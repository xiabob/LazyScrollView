//
//  ViewController.m
//  LazyScrollView
//
//  Created by xiabob on 16/12/22.
//  Copyright © 2016年 xiabob. All rights reserved.
//

#import "ViewController.h"
#import "LazyScrollView.h"
#import "SingleView.h"

@interface ViewController () <LazyScrollViewDataSource, LazyScrollViewDelegate>

@property (strong, nonatomic) LazyScrollView *lazyScrollView;
@property (copy, nonatomic) NSArray<LSVRectModel *> *rectDatas;
@property (copy, nonatomic) NSDictionary *viewsData;

@end

@implementation ViewController

- (void)loadView {
    [super loadView];
    
    [self loadDatas];
    [self configViews];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)loadDatas {
    
    NSMutableArray *array = @[].mutableCopy;
    NSMutableDictionary *dictionary = @{}.mutableCopy;
    
    NSMutableArray *rectArray  = [[NSMutableArray alloc] init];
    //Create a single column layout with 5 elements;
    for (int i = 0; i < 500 ; i++) {
        [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(10, i *80 + 2 , self.view.bounds.size.width-20, 80-2)]];
    }
    //Create a double column layout with 10 elements;
    for (int i = 0; i < 1000 ; i++) {
        [rectArray addObject:[NSValue valueWithCGRect:CGRectMake((i%2)*self.view.bounds.size.width/2 + 3, 41000 + i/2 *80 + 2 , self.view.bounds.size.width/2 -3, 80 - 2)]];
    }
    //Create a trible column layout with 15 elements;
    for (int i = 0; i < 1500 ; i++) {
        NSUInteger row = 5;
        [rectArray addObject:[NSValue valueWithCGRect:CGRectMake((i%row)*self.view.bounds.size.width/row + 1, 82000 + i/row *80 + 2 , self.view.bounds.size.width/row -4, 80 - 2)]];
    }
    
    for (NSInteger index = 0; index < rectArray.count; ++ index) {
        NSString *lsvId = [NSString stringWithFormat:@"%@/%@", @(index / 10), @(index % 10)];
        LSVRectModel *model = [LSVRectModel modelWithRect:[(NSValue *)(rectArray[index]) CGRectValue] lsvId:lsvId];
        [array addObject:model];
        [dictionary setObject:lsvId forKey:lsvId];
    }
    
    
    //    for (NSInteger index = 0; index < 5000; ++ index) {
    //        NSString *lsvId = [NSString stringWithFormat:@"%@/%@", @(index / 10), @(index % 10)];
    //        CGFloat width = ([UIScreen mainScreen].bounds.size.width - 30) / 2;
    //        LSVRectModel *model = [LSVRectModel modelWithRect:CGRectMake(10 + (index % 2) * (width+10), (index / 2) * (width+10), width, width) lsvId:lsvId];
    //        [array addObject:model];
    //        [dictionary setObject:lsvId forKey:lsvId];
    //    }
    self.rectDatas = array;
    self.viewsData = dictionary;
    
}

- (void)configViews {
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.lazyScrollView];
    self.lazyScrollView.frame = self.view.bounds;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - LazyScrollViewDataSource

- (NSUInteger)numberOfItemInScrollView:(LazyScrollView *)scrollView {
    return self.rectDatas.count;
}

- (LSVRectModel *)scrollView:(LazyScrollView *)scrollView rectModelAtIndex:(NSUInteger)index {
    
    return self.rectDatas[index];
}

- (UIView *)scrollView:(LazyScrollView *)scrollView itemByLsvId:(NSString *)lsvId {
    SingleView *view;
    NSInteger index = [[[lsvId componentsSeparatedByString:@"/"] valueForKeyPath:@"@sum.integerValue"] integerValue];
    if (index % 3 == 1) {
        view = (SingleView *)[self.lazyScrollView dequeueReusableItemWithIdentifier:kViewIdfSingle1];
        view.data = [NSString stringWithFormat:@"Single1 - %@", self.viewsData[lsvId]];
    } else if (index % 5 == 2 || index % 5 == 3) {
        view = (SingleView *)[self.lazyScrollView dequeueReusableItemWithIdentifier:kViewIdfSingle2];
        view.data = [NSString stringWithFormat:@"Single2 - %@", self.viewsData[lsvId]];
    } else if (index % 7 == 3 || index % 7 == 2) {
        view = (SingleView *)[self.lazyScrollView dequeueReusableItemWithIdentifier:kViewIdfSingle3];
        view.data = [NSString stringWithFormat:@"Single3 - %@", self.viewsData[lsvId]];
    } else if (index % 7 == 4 || index % 7 == 5) {
        view = (SingleView *)[self.lazyScrollView dequeueReusableItemWithIdentifier:kViewIdfSingle4];
        view.data = [NSString stringWithFormat:@"Single4 - %@", self.viewsData[lsvId]];
    } else {
        view = (SingleView *)[self.lazyScrollView dequeueReusableItemWithIdentifier:kViewIdfSingle5];
        view.data = [NSString stringWithFormat:@"Single5 - %@", self.viewsData[lsvId]];
    }
    
    return view;
}

#pragma mark - LazyScrollViewDelegate

- (void)scrollView:(LazyScrollView *)scrollView didClickItemAtIndex:(NSUInteger)index withLsvId:(NSString *)lsvId {
    SingleView *view = (SingleView *)[self scrollView:scrollView itemByLsvId:lsvId];
    NSLog(@"didClickItemAtIndex:%@ lsvid:%@ view data:%@", @(index), lsvId, view.data);
    [scrollView reloadData];
}


#pragma mark - getter

- (LazyScrollView *)lazyScrollView {
    if (!_lazyScrollView) {
        _lazyScrollView = [LazyScrollView new];
        _lazyScrollView.dataSource = self;
        _lazyScrollView.delegate = self;
        [_lazyScrollView registerClass:[SingleView class] forViewReuseIdentifier:kViewIdfSingle1];
        [_lazyScrollView registerClass:[SingleView class] forViewReuseIdentifier:kViewIdfSingle2];
        [_lazyScrollView registerClass:[SingleView class] forViewReuseIdentifier:kViewIdfSingle3];
        [_lazyScrollView registerClass:[SingleView class] forViewReuseIdentifier:kViewIdfSingle4];
        [_lazyScrollView registerClass:[SingleView class] forViewReuseIdentifier:kViewIdfSingle5];
    }
    return _lazyScrollView;
}

- (NSArray<LSVRectModel *> *)rectDatas {
    if (!_rectDatas) {
        _rectDatas = [NSArray array];
    }
    return _rectDatas;
}

- (NSDictionary *)viewsData {
    if (!_viewsData) {
        _viewsData = [NSDictionary dictionary];
    }
    return _viewsData;
}

@end
