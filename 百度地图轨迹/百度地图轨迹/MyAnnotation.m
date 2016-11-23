//
//  MyAnnotation.m
//  百度地图轨迹
//
//  Created by 邬志成 on 2016/11/22.
//  Copyright © 2016年 邬志成. All rights reserved.
//

#import "MyAnnotation.h"

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
