//
//  NSString+Date.m
//  GWEve
//
//  Created by chuancun cheng on 2018/9/17.
//  Copyright © 2018年 Shenzhen Gowild Intelligent Technology. All rights reserved.
//

#import "NSString+Date.h"

@implementation NSString (Date)

+ (NSString *)gw_morrowZeroClockDate:(NSDate *)aDate {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:aDate];
    NSDate *startDate = [calendar dateFromComponents:components];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    return [dateFormatter stringFromDate:endDate];
}

+ (NSString *)gw_dateAfterPeriodTimeWithDate:(NSString *)aDateStr diffTime:(long long)second {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSDate *date = [dateFormatter dateFromString:aDateStr];
    
    NSTimeInterval startTimeInterval = [date timeIntervalSince1970];
    NSTimeInterval endTimeInterval = startTimeInterval + second;
    
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:endTimeInterval];
    NSString *dateString = [dateFormatter stringFromDate:endDate];
    
    return dateString;
}

+ (NSString *)gw_string24HRFormatterFromDate:(NSDate *)aDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    return [dateFormatter stringFromDate:aDate];
}

- (NSDate *)gw_dateTimeWith24HRFormatter {
    NSDateFormatter *formatter24HR = [[NSDateFormatter alloc] init];
    [formatter24HR setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [formatter24HR setTimeZone:[NSTimeZone systemTimeZone]];
    NSDate *date24HR = [formatter24HR dateFromString:self];
    return date24HR;
}

- (NSString *)gw_stringTimeWith24HRFormatter {
    NSDateFormatter *formatter24HR = [[NSDateFormatter alloc] init];
    [formatter24HR setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [formatter24HR setTimeZone:[NSTimeZone systemTimeZone]];
    
    NSDate *date24HR = [formatter24HR dateFromString:self];
    
    //转为24小时 时间
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSString *dateStr = [dateFormatter stringFromDate:date24HR];
    
    return dateStr;
}

- (int32_t)gw_angleOnClockWithDateString {
    NSDateFormatter *formatter24HR = [[NSDateFormatter alloc] init];
    [formatter24HR setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [formatter24HR setTimeZone:[NSTimeZone systemTimeZone]];
    
    NSDate *date24HR = [formatter24HR dateFromString:self];
    
    //转为12小时
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh:mm"];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSString *dateStr = [dateFormatter stringFromDate:date24HR];
    
    NSArray *dateCutList = [dateStr componentsSeparatedByString:@":"];
    uint32_t hour = [[dateCutList objectAtIndex:0] intValue];
    uint32_t minute = [[dateCutList objectAtIndex:1] intValue];
    hour = hour > 12 ? hour - 12:hour;
    
    //圆弧的起点与表盘的起点坐标相差M_PI/2
    int32_t diffAngle = - 90;
    int32_t angle = hour * 30 + minute * 0.5 + diffAngle;
    if (angle < 0) angle += 360;
    
    return angle;
}

- (int32_t)gw_secondFromDateString {
    
    @try {
        NSArray *dateCutList = [self componentsSeparatedByString:@":"];
        uint32_t hour = [[dateCutList objectAtIndex:0] intValue];
        uint32_t minute = [[dateCutList objectAtIndex:1] intValue];
        return hour *3600 + minute * 60;
    }
    @catch (NSException *exception){
        return 0;
    }
    
}

@end
