//
//  NSString+Date.h
//  GWEve
//
//  Created by chuancun cheng on 2018/9/17.
//  Copyright © 2018年 Shenzhen Gowild Intelligent Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Date)

/**
 *  NSString 获取次日零点
 *
 *  @param  aDate 目标日期
 *
 *  @return 次日日期
 */
+ (NSString *)gw_morrowZeroClockDate:(NSDate *)aDate;

/**
 *  NSString 获取一段时间之后(前)的日期
 *
 *  @param  aDateStr   目标日期
 *  @param  second  差值(秒)
 *
 *  @return 次日日期
 */
+ (NSString *)gw_dateAfterPeriodTimeWithDate:(NSString *)aDateStr diffTime:(long long)second;


/**
 *  NSString 获取格式 yyyy-MM-dd HH:mm:ss 日期字符
 *
 *  @param  aDate   目标日期
 *
 *  @return 次日日期 (string)
 */
+ (NSString *)gw_string24HRFormatterFromDate:(NSDate *)aDate;


/**
 *  NSString 获取格式 yyyy-MM-dd HH:mm:ss 日期
 *
 *  @return 次日日期 (date)
 */
- (NSDate *)gw_dateTimeWith24HRFormatter;

/**
 *  NSString 获取24小时制时间
 *
 *  @return  时间
 */
- (NSString *)gw_stringTimeWith24HRFormatter;

/**
 *  NSString 将时间日期换算成表盘上的角度
 *
 *  @return  角度
 */
- (int32_t)gw_angleOnClockWithDateString;

/**
 *   NSString 根据 HH:mm 时间格式换算成 second
 *
 *  @return 秒数
 */

- (int32_t)gw_secondFromDateString;

@end
