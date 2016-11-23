//
//  ViewController.m
//  百度地图轨迹
//
//  Created by 邬志成 on 2016/11/22.
//  Copyright © 2016年 邬志成. All rights reserved.
//

#import "ViewController.h"
#import "MyAnnotation.h"
#import "BaiduMap/BaiduMapAPI_Map.framework/Headers/BMKMapComponent.h"
#import "BaiduMap/BaiduMapAPI_Base.framework/Headers/BMKBaseComponent.h"
#import "BaiduMap/BaiduMapAPI_Location.framework/Headers/BMKLocationComponent.h"

@interface ViewController ()<BMKMapViewDelegate,BMKLocationServiceDelegate>

/** 百度地图 */
@property (nonatomic,weak)  BMKMapView *mapView;

/** 定位服务 */
@property (nonatomic,strong) BMKLocationService *locationService;

/** 点 */
@property (nonatomic,strong) BMKPointAnnotation *pointAnnotation;



@end

@implementation ViewController{

    NSMutableArray *lineArray;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    BMKMapView *mapView = [[BMKMapView alloc] initWithFrame:self.view.frame];
    mapView.mapType = BMKMapTypeStandard;
    mapView.overlookEnabled = NO;
    mapView.showsUserLocation = YES;
    _mapView = mapView;
    [self.view addSubview:_mapView];
    [self baiduMapLocation];
}


- (void)baiduMapLocation{
    BMKLocationService *locationService = [[BMKLocationService alloc] init];
    [locationService startUserLocationService];
    locationService.delegate = self;
    _locationService = locationService;
    BMKPointAnnotation *point = [[BMKPointAnnotation alloc] init];
    [_mapView setZoomLevel:18];
    _pointAnnotation = point;

}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation{
    MyAnnotation *annotationView = (MyAnnotation*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"myAnno"];
    if (annotationView == nil) {
        annotationView = [[MyAnnotation alloc] initWithAnnotation:annotation reuseIdentifier:@"myAnno"];
    }
    return annotationView;
}

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

#pragma mark - BMKLocationServiceDelegate
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation{
    [_mapView setCenterCoordinate:userLocation.location.coordinate animated:YES];
    
    [self setAnnotationWithLocation:userLocation];
    
    [self setMapLineWithLocation:userLocation];
    
}

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


- (void)viewWillAppear:(BOOL)animated{
    [_mapView viewWillAppear];
    _mapView.delegate = self;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated{

    [_mapView viewWillDisappear];
    _mapView.delegate = nil;
    lineArray = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [_locationService stopUserLocationService];
    [lineArray removeAllObjects];
    [_locationService startUserLocationService];
    
}

@end
