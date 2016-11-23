# BaiduMapDemo
百度地图自定义标记,和运动轨迹显示的实例
首先,先说说我用到的几个框架:
`BaiduMapAPI_Base.framework` 百度地图使用时必不可少的一个基础框架
`BaiduMapAPI_Map.framework` 百度地图可以自定义轨迹及 Annotation 的框架
`BaiduMapAPI_Location.framework`百度地图中的定位框架

当然首先必不可少的就是根据官方的文档申请一个 key ,做好使用地图前的准备, 此处不再详细谈论.

可是基于默认的地图包来说,我偏偏要做成下图中的效果:
![1222.png](http://upload-images.jianshu.io/upload_images/2752594-1d38c93a6a30b90e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

好了,言归正传,首先,我们先把定位搞好:
- 创建地图,先把地图给显示在屏幕上
````objc
- (void)viewDidLoad {
[super viewDidLoad];
BMKMapView *mapView = [[BMKMapView alloc] initWithFrame:self.view.frame];
mapView.mapType = BMKMapTypeStandard;
mapView.overlookEnabled = NO;
mapView.showsUserLocation = YES;
_mapView = mapView;
[self.view addSubview:_mapView];
}
````
对了按照其官方文档,我们还要实现以下方法(目的是能够释放内存,还是相当重要的),代理的指定也在里面:

````objc
- (void)viewWillAppear:(BOOL)animated{
[_mapView viewWillAppear];
_mapView.delegate = self;
[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated{

[_mapView viewWillDisappear];
_mapView.delegate = nil; //就是这句影响内存释放
}
````

下面,就要来自定义一个小汽车作为Annotation来显示在界面上, 值得注意的是 BMKAnnotationView不是随意就可以创建的,而是需要在本身的 mapView 的 Delegate 方法中返回一个 BMKAnnotationView 对象,简言之就是在代理中创建
- 先获取到定位,添加一个 BMKPointAnnotation

````objc
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation{
[_mapView setCenterCoordinate:userLocation.location.coordinate animated:YES];
[self setAnnotationWithLocation:userLocation]; //定位的 Annotation 调用
[self setMapLineWithLocation:userLocation];
}
````

其实在下面方法中的 Annotation 在定义时候只是表示在地图中添加了一个 Annotation ,而实际的形状则由mapView 的代理方法`- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation`来决定
````objc
/**
*  设置地图的标注
*/
- (void)setAnnotationWithLocation:(BMKUserLocation*)userLocation{
double dir = userLocation.location.course;
CLLocationSpeed speed = userLocation.location.speed;
_pointAnnotation.title = [NSString stringWithFormat:@"我(精确度:%.0f m)",userLocation.location.horizontalAccuracy];
_pointAnnotation.subtitle = [NSString stringWithFormat:@"时速:%0.1fKm/h",(speed<0? 0:speed) * 3.6f];
_pointAnnotation.coordinate = userLocation.location.coordinate;
if (![_mapView.annotations containsObject:_pointAnnotation]) {
[_mapView addAnnotation:_pointAnnotation];
[_mapView selectAnnotation:_pointAnnotation animated:YES];
}

//误差范围指示器
static BMKCircle *circle;
if (circle == nil) {
circle = [BMKCircle circleWithCenterCoordinate:userLocation.location.coordinate radius:userLocation.location.horizontalAccuracy];
[_mapView addOverlay:circle];
}else{

circle.radius = 10;//userLocation.location.horizontalAccuracy;
circle.coordinate = userLocation.location.coordinate;

}

//设置方向角度
MyAnnotation *annotationView = (MyAnnotation*)[_mapView viewForAnnotation:_pointAnnotation];
annotationView.bgImage.transform = CGAffineTransformMakeRotation((dir + 90 - _mapView.rotation) * M_PI / 180);
}
````

来看看地图 annotation 的改变(如果返回 nil 则使用默认)

````objc
- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation{
MyAnnotation *annotationView = (MyAnnotation*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"myAnno"];
if (annotationView == nil) {
annotationView = [[MyAnnotation alloc] initWithAnnotation:annotation reuseIdentifier:@"myAnno"];
}
return annotationView;
}
````
自定义 Annotation 文件`MyAnnotation.m`的实现
````objc
@implementation MyAnnotation
- (id)initWithAnnotation:(id<BMKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier{
self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
if (self) {
//        self.backgroundColor = [UIColor redColor];
self.frame = CGRectMake(0, 0, 30, 30);

UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"location"]];
imgView.frame = CGRectMake(0, 0, 30, 30);
imgView.contentMode = UIViewContentModeScaleAspectFit;
_bgImage = imgView;
self.paopaoView = nil;
[self addSubview:imgView];   
}
return self;
}
@end
````

##notice : 看到这里如果你懂了,那么下面的轨迹,你也很难不懂了...

下面就来证实我上面说的

- 首先你还是要在获取到位置之后用`NSMutableArray`来保存很多个位置信息,也就是这个家伙👉`CLLocation`,当然你要做一些条件过滤(小于5米不记录等等),然后创建`BMKPolyline`来添加到地图中,创建方法用`+ (BMKPolyline *)polylineWithCoordinates:(CLLocationCoordinate2D *)coords count:(NSUInteger)count;`反正我用的这个,随便都行,但是要能显示出来哦,
接着按照`##notice : 看到这里如果你懂了,那么下面的轨迹,你也很难不懂了...`以上的说法,实现 mapView 中的代理方法👉`- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay`,在这个代理方法里面,想怎么搞就怎么搞,想要什么效果就设置什么效果.

代码如下:

- 我们要在地图上添加的轨迹

````objc
/**
*  设置运动轨迹地图路径
*/
- (void)setMapLineWithLocation:(BMKUserLocation*)userLocation{

if (userLocation.location.horizontalAccuracy > 5) {
return;
}

if (lineArray == nil) {
lineArray = [NSMutableArray new];
return;
}

CLLocation *last = lineArray.lastObject;
CLLocationDistance distance = [userLocation.location distanceFromLocation:last];
if ((last.coordinate.longitude == userLocation.location.coordinate.longitude
&&last.coordinate.latitude == userLocation.location.coordinate.latitude)
|| (distance < 4 && lineArray.count != 0)) {
return;
}
[lineArray addObject:userLocation.location];
CLLocationCoordinate2D *coords = new CLLocationCoordinate2D[lineArray.count];
for (int i = 0; i < lineArray.count; i++) {
CLLocation *loc = lineArray[i];
coords[i] = loc.coordinate;
}

if (lineArray.count <= 1) {
return;
}
static BMKPolyline *line;
if (line) {
[line setPolylineWithCoordinates:coords count:lineArray.count];
return;
}
line = [BMKPolyline polylineWithCoordinates:coords count:lineArray.count];
[_mapView addOverlay:line];
}
````

- 我们想要的样式

````objc
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay{

if ([overlay isKindOfClass:[BMKPolyline class]]) {
BMKPolylineView *overlayView = [[BMKPolylineView alloc] initWithOverlay:overlay];
overlayView.lineWidth = 3;
overlayView.isFocus = YES;
overlayView.strokeColor = [UIColor colorWithRed:0.167 green:0.840 blue:0.043 alpha:0.500];
return overlayView;
}

if ([overlay isKindOfClass:[BMKCircle class]]) {
BMKCircleView *circleView = [[BMKCircleView alloc] initWithCircle:overlay];
circleView.fillColor = [UIColor colorWithRed:0.989 green:0.417 blue:0.057 alpha:0.328];
circleView.strokeColor = [UIColor colorWithRed:0.989 green:0.417 blue:0.057 alpha:0.879];
circleView.lineWidth = 0;
return circleView;
}

return nil;
}
````

代码地址 :  https://github.com/voisen/BaiduMapDemo