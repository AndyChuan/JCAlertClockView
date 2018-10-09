//
//  JCAlarmClockView.h
//  JCAlarmClockDemo
//
//  Created by apple on 2018/10/8.
//  Copyright © 2018年 chengchuancun. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, GWCycleMovedType) {
    GWCycleMovedTypeNone = 0,
    GWCycleMovedTypeStartDot,          //移动起始点
    GWCycleMovedTypeEndDot,            //移动终点
    GWCycleMovedTypeMiddle             //移动中间位置
};

@class JCAlarmClockView;
@protocol GWCustomClockViewDelegate <NSObject>

- (void)gwCustomClockView:(JCAlarmClockView *)clockView changTimeWithStartTime:(NSString *)startTime endTime:(NSString *)endTime;

- (void)gwCustomClockView:(JCAlarmClockView *)clockView TouchesEndedTimeWithStartTime:(NSString *)startTime endTime:(NSString *)endTime;

@end


@interface JCAlarmClockView : UIView

@property (nonatomic, assign) int32_t lineWidth;

@property (nonatomic, setter=changeStartAngle:) CGFloat startAngle;

@property (nonatomic, setter=changeEndAngle:) CGFloat endAngle;

@property (nonatomic, setter=changeCycle:) uint32_t cycle;

@property (nonatomic, weak) id<GWCustomClockViewDelegate> delegate;


- (void)setContentViewWithStartDate:(NSString *)startDateStr endDate:(NSString *)endDateString cycle:(uint32_t)cycle;

@end
