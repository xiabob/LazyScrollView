# LazyScrollView
iOS 高性能异构滚动视图构建方案 —— LazyScrollView

##思路来源
* [苹果核 - iOS 高性能异构滚动视图构建方案 —— LazyScrollView](http://pingguohe.net/2016/01/31/lazyscroll.html)

* https://github.com/HistoryZhang/LazyScrollView

~~因为原文并没有提供相关demo，而HistoryZhang的实现还有部分不满足我的需求，所以打算在他们的基础上自己再造个轮子。目前经过Instruments测试，性能已经能够满足日常使用了（但可优化的空间还有很多！）。~~

已开源https://github.com/alibaba/LazyScrollView

##使用

使用方式和tableView类似，具体还是参照工程里面的例子。
###dataSource
<pre>
// ScrollView一共需要展示多少个item
- (NSUInteger)numberOfItemInScrollView:(LazyScrollView *)scrollView;
// 要求根据index直接返回RectModel
- (LSVRectModel *)scrollView:(LazyScrollView *)scrollView rectModelAtIndex:(NSUInteger)index;
// 返回下标所对应的view
- (UIView *)scrollView:(LazyScrollView *)scrollView itemByLsvId:(NSString *)lsvId;
</pre>
其中LSVRectModel的定义如下：
<pre>
// view转换后的绝对值rect
@property (nonatomic, assign) CGRect absRect;

// 业务下标，如果初始化时没有提供，LSVRectModel内部会自动生成
@property (nonatomic, copy) NSString *lsvId;
</pre>
关键在于方法- (LSVRectModel *)scrollView:(LazyScrollView *)scrollView rectModelAtIndex:(NSUInteger)index，具体可以参见demo工程。

###delegate
<pre>
//处理点击事件
- (void)scrollView:(LazyScrollView *)scrollView didClickItemAtIndex:(NSUInteger)index;
</pre>

###调用核心API
<pre>
- (void)reloadData;
</pre>

重新走一遍DataSource的这些方法，等同于TableView中的reloadData
<pre>
- (UIView *)dequeueReusableItemWithIdentifier:(NSString *)identifier
</pre>

根据identifier获取可以复用的View。和TableView的dequeueReusableCellWithIdentifier:(NSString *)identifier方法意义相同。通常是在LazyScrollViewDatasource第三个方法，返回View的时候使用。

<pre>
- (void)registerClass:(Class)viewClass forViewReuseIdentifier:(NSString *)identifier
</pre>

功能和TableView的registerClass:(nullable Class)cellClass forCellReuseIdentifier:(NSString *)identifier一样
</pre>tableView
</pre>
