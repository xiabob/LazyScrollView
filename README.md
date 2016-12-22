# LazyScrollView
iOS 高性能异构滚动视图构建方案 —— LazyScrollView

##思路来源
* [苹果核 - iOS 高性能异构滚动视图构建方案 —— LazyScrollView](http://pingguohe.net/2016/01/31/lazyscroll.html)

* https://github.com/HistoryZhang/LazyScrollView

因为原文并没有提供相关demo，而HistoryZhang的实现还有部分不满足我的需求，所以打算在他们的基础上自己再造个轮子。

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

