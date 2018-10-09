//
//  ViewController.m
//  JCAlarmClockDemo
//
//  Created by apple on 2018/10/8.
//  Copyright © 2018年 chengchuancun. All rights reserved.
//

#import "ViewController.h"
#import "JCAlarmClockView.h"

@interface ViewController ()
<
  GWCustomClockViewDelegate
>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    JCAlarmClockView *clockView = [[JCAlarmClockView alloc] initWithFrame:CGRectMake(200, 0.f, 350.f, 350.f)];
    clockView.center = self.view.center;
    
    NSString *startDate = @"2018-10-09 00:00:00";
    NSString *endDate = @"2018-10-10 07:20:00";
    
    [clockView setContentViewWithStartDate:startDate endDate:endDate cycle:0];
    
    clockView.delegate = self;
    [self.view addSubview:clockView];
    

}


@end
