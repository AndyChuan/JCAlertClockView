//
//  JCAlarmClockView.m
//  JCAlarmClockDemo
//
//  Created by apple on 2018/10/8.
//  Copyright © 2018年 chengchuancun. All rights reserved.
//

#import "JCAlarmClockView.h"
#import "NSString+Date.h"

#define ToRad(deg)        ( (M_PI * (deg)) / 180.0 )
#define ToDeg(rad)        ( (180.0 * (rad)) / M_PI )
#define SQR(x)            ( (x) * (x) )
#define UIColorFromHexValue(hexValue) [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16))/255.0 green:((float)((hexValue & 0xFF00) >> 8))/255.0 blue:((float)(hexValue & 0xFF))/255.0 alpha:1.0]

CG_INLINE CGFloat TFScalePoint(CGFloat x) {
    if (x != 0)
    {
        CGRect mainFrme = [[UIScreen mainScreen] bounds];
        CGFloat scale = mainFrme.size.width/375.0;
        return x*scale;
    }
    
    return x;
}

@interface JCAlarmClockView ()
{
    CGFloat _radius;
    Boolean _moveStartDot;
    Boolean _moveEndDot;
    
    GWCycleMovedType _movedType;
    Boolean _isIncrease;          //判断是时间否增加
    uint32_t _cycle;              //循环圈数
    int32_t  _prevAngle;          //保存之前的角度
}

@property (nonatomic, strong) UIImageView *startDot;

@property (nonatomic, strong) UIImageView *endDot;

@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, strong) UIImageView *clockImageView;

@property (nonatomic, strong) NSString *startDate;

@property (nonatomic, strong) NSString *endDate;


@end

@implementation JCAlarmClockView

#pragma mark - super method
-(instancetype)initWithFrame:(CGRect)frame{
    if ([super initWithFrame:frame]) {
        _lineWidth = TFScalePoint(37);
        _startAngle = 270;
        _endAngle = 270;
        _cycle = 0;
        
        //日期
        self.startDate = [self getStartTimeDefaultDate:[NSDate date]];
        _radius = self.frame.size.width/2 - _lineWidth;
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.clockImageView];
        
        [self angleToTime];
    }
    return self;
}

- (void)setContentViewWithStartDate:(NSString *)startDateStr endDate:(NSString *)endDateString cycle:(uint32_t)cycle {
    self.startDate = startDateStr;
    self.endDate = endDateString;
    
    _startAngle = [startDateStr gw_angleOnClockWithDateString];
    _endAngle = [endDateString gw_angleOnClockWithDateString];
    _cycle = cycle >= 1 ? 1 : 0;
    
    [self setNeedsDisplay];
    [self angleToTime];
    
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //3.绘制起点
    CGPoint startHandleCenter =  [self pointFromAngle: (_startAngle)];
    self.startDot.center = startHandleCenter;
    
    //4.绘制终点
    CGPoint endHandleCenter =  [self pointFromAngle: (_endAngle)];
    self.endDot.center = endHandleCenter;
    
    //1.绘制背景圆
    CGContextAddArc(context, self.frame.size.width/2, self.frame.size.height/2, _radius, 0, M_PI*2, 0);
    [UIColorFromHexValue(0xE5E5E5) setStroke];
    CGContextSetLineWidth(context, _lineWidth);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextDrawPath(context, kCGPathStroke);
    
    //2.绘制起点->终点圆弧
    CGContextAddArc(context, self.frame.size.width/2, self.frame.size.height/2, _radius, ToRad(_startAngle), ToRad(_endAngle), 0);
    [UIColorFromHexValue(0xB178FF) setStroke];
    CGContextSetLineWidth(context, _lineWidth);
    CGContextSetLineCap(context, kCGLineCapRound);
    //    CGContextDrawPath(context, kCGPathStroke);
    
    //5.渐变色
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSArray *colorArr = @[
                          (id)UIColorFromHexValue(0x6D6EFE).CGColor,
                          (id)UIColorFromHexValue(0xB178FF).CGColor
                          ];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colorArr, NULL);
    CGColorSpaceRelease(colorSpace);
    colorSpace = NULL;
    
    CGContextReplacePathWithStrokedPath(context);
    // 剪裁路径
    CGContextClip(context);
    //用渐变色填充
    CGContextDrawLinearGradient(context, gradient, [self pointFromAngleForOuterRing:_startAngle], [self pointFromAngleForOuterRing:_startAngle + 180], 0);
    // 释放渐变色
    CGGradientRelease(gradient);
}

#pragma mark - 监听屏幕touch
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    _movedType = GWCycleMovedTypeNone;
    _prevAngle = 0;
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    if (CGRectContainsPoint(self.startDot.frame, point))
    {
        _movedType = GWCycleMovedTypeStartDot;
        _prevAngle = _startAngle;
    }else if (CGRectContainsPoint(self.endDot.frame, point))
    {
        _movedType = GWCycleMovedTypeEndDot;
        _prevAngle = _endAngle;
    }else
    {
        float dis = [self distanceBetweenCycleCenterAndPoint:point];
        
        int accuracy = 15; //精确度 增加触发几率
        //点击坐标在不在圆环上
        if (dis > _radius+_lineWidth + accuracy|| dis < _radius - accuracy) return;
        
        //判断该点是否在起点->终点圆弧上
        CGFloat angleP = [self angleBetweenCycleCenterAndPoint:point];
        int difAngleP = [self difAngleBetweenStartAngle:_startAngle andEndAngle:angleP];
        int difAngleE = [self difAngleBetweenStartAngle:_startAngle andEndAngle:_endAngle];
        if (difAngleE < difAngleP) return;
        
        _prevAngle = [self angleBetweenCycleCenterAndPoint:point];
        _movedType = GWCycleMovedTypeMiddle;
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    @autoreleasepool {
        switch (_movedType)
        {
            case GWCycleMovedTypeNone:
                return;
            case GWCycleMovedTypeStartDot:
            case GWCycleMovedTypeEndDot:
            {
                UITouch *touch = [touches anyObject];
                CGPoint lastPoint = [touch locationInView:self];
                //根据触摸点移动相应的图片
                [self movehandle:lastPoint];
                //转换成相应的时间
                [self angleToTime];
            }
                break;
            case GWCycleMovedTypeMiddle:
            {
                UITouch *touch = [touches anyObject];
                CGPoint middlePoint = [touch locationInView:self];
                [self moveVirtuaArc:middlePoint];
                [self angleToTime];
            }
                break;
            default:
                break;
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(gwCustomClockView:changTimeWithStartTime:endTime:)]) {
        [self.delegate gwCustomClockView:self changTimeWithStartTime:_startDate endTime:_endDate];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.delegate && [self.delegate respondsToSelector:@selector(gwCustomClockView:TouchesEndedTimeWithStartTime:endTime:)]) {
        [self.delegate gwCustomClockView:self TouchesEndedTimeWithStartTime:_startDate endTime:_endDate];
    }
}

//移动单个点
-(void)movehandle:(CGPoint)lastPoint{
    float currentAngle = [self angleBetweenCycleCenterAndPoint:lastPoint];
    float prevAngle    = 0.f;
    float targetAngle  = 0.f;
    float resAngle = 0.f;
    
    if (_movedType == GWCycleMovedTypeStartDot)
    {
        CGFloat difAngleM = [self difAngleBetweenStartAngle:_endAngle andEndAngle:currentAngle];
        CGFloat difAngleP = [self difAngleBetweenStartAngle:_endAngle andEndAngle:_prevAngle];
        //精确度 防止触发太灵敏出现抖动
        CGFloat accuracy = 2.5;
        if (fabs(difAngleP - difAngleM) < accuracy) {
            return;
        }
        float difAngle = difAngleM - difAngleP;// difAngleM > difAngleP ? 2.5  : -2.5;
        
        //时间以五分钟为单位
        int a = (int)(difAngle/accuracy);
        difAngle = (float)a * 2.5;
        
        prevAngle = _startAngle;
        targetAngle = _endAngle;
        _startAngle = [self sumAngleBetweenStartAngle:_startAngle andDifAngle:difAngle];
        resAngle = _startAngle;
    }
    else
    {
        CGFloat difAngleM = [self difAngleBetweenStartAngle:_startAngle andEndAngle:currentAngle];
        CGFloat difAngleP = [self difAngleBetweenStartAngle:_startAngle andEndAngle:_prevAngle];
        //精确度 防止触发太灵敏出现抖动
        CGFloat accuracy = 2.5;
        if (fabs(difAngleP - difAngleM) < accuracy) {
            return;
        }
        float difAngle = difAngleM - difAngleP;// difAngleM > difAngleP ? 2.5  : -2.5;
        
        //时间以五分钟为单位
        int a = (int)(difAngle/accuracy);
        difAngle = (float)a * 2.5;
        
        prevAngle = _endAngle;
        targetAngle = _startAngle;
        _endAngle = [self sumAngleBetweenStartAngle:_endAngle andDifAngle:difAngle];
        resAngle = _endAngle;
    }
    //滑动时有时会进入两次相同的坐标，防止这一现象
    if (prevAngle != targetAngle) {
        _prevAngle = prevAngle;
    }
    //判断是否需要累计圈数
    if ([self containAngle:targetAngle ByAngleRangeWith:_prevAngle :resAngle]) {
        _cycle = _cycle ? 0 : 1;
    }
    [self setNeedsDisplay];
    
}

//移动有效圆弧
- (void)moveVirtuaArc:(CGPoint)middlePoint {
    float middleAngle = [self angleBetweenCycleCenterAndPoint:middlePoint];
    
    CGFloat difAngleM = [self difAngleBetweenStartAngle:_startAngle andEndAngle:middleAngle];
    CGFloat difAngleP = [self difAngleBetweenStartAngle:_startAngle andEndAngle:_prevAngle];
    
    //精确度 防止触发太灵敏出现抖动
    CGFloat accuracy = 2.5;
    if (fabs(difAngleP - difAngleM) < accuracy) {
        return;
    }
    float difAngle = difAngleM - difAngleP;// difAngleM > difAngleP ? 2.5  : -2.5;
    
    //时间以五分钟为单位
    int a = (int)(difAngle/accuracy);
    difAngle = (float)a * 2.5;
    
    _startAngle = [self sumAngleBetweenStartAngle:_startAngle andDifAngle:difAngle];
    _endAngle   = [self sumAngleBetweenStartAngle:_endAngle andDifAngle:difAngle];
    _prevAngle = middleAngle;
    [self speculateOtherTimeWithDate:self.endDate diffAnle:difAngle isStart:YES];
    [self setNeedsDisplay];
}

- (void)angleToTime {
    CGFloat difAngle = 0.f;
    if (_endAngle >= _startAngle) {
        difAngle = _endAngle - _startAngle;
    }
    else {
        difAngle = 360 - (_startAngle - _endAngle);
    }
    difAngle += _cycle * 360;
    
    NSString *time = nil;
    if (_movedType == GWCycleMovedTypeEndDot) {
        time = [self speculateOtherTimeWithDate:self.startDate diffAnle:difAngle isStart:YES];
    }else {
        time = [self speculateOtherTimeWithDate:self.endDate diffAnle:difAngle isStart:NO];
    }
    [self timeLabelShowString:time];
}


#pragma mark - 算法相关
//计算角度对应内圆弧上的坐标
-(CGPoint)pointFromAngle:(int)angleInt {
    CGPoint centerPoint = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    CGPoint result;
    result.y = round(centerPoint.y + _radius * sin(ToRad(angleInt))) ;
    result.x = round(centerPoint.x + _radius * cos(ToRad(angleInt)));
    
    return result;
}

//计算外圆弧的坐标
- (CGPoint)pointFromAngleForOuterRing:(int)angleInt {
    CGPoint centerPoint = CGPointMake(self.frame.size.width/2,
                                      self.frame.size.height/2);
    CGPoint result;
    result.y = round(centerPoint.y + (_radius + _lineWidth) * sin(ToRad(angleInt))) ;
    result.x = round(centerPoint.x + (_radius + _lineWidth) * cos(ToRad(angleInt)));
    
    return result;
}

//计算中心点到任意点的的距离
- (CGFloat)distanceBetweenCycleCenterAndPoint:(CGPoint)point {
    CGPoint centerPoint = CGPointMake(self.frame.size.width/2,
                                      self.frame.size.height/2);
    CGFloat result;
    result = sqrt(pow((centerPoint.x - point.x), 2) + pow((centerPoint.y - point.y), 2));
    return result;
}

//计算中心点到任意点的角度
- (CGFloat)angleBetweenCycleCenterAndPoint:(CGPoint)point {
    CGPoint centerPoint = CGPointMake(self.frame.size.width/2,
                                      self.frame.size.height/2);
    
    //计算中心点到任意点的角度
    float currentAngle = AngleFromNorth(centerPoint,
                                        point,
                                        NO);
    return currentAngle;
}

//计算两点间的角度
static inline float AngleFromNorth(CGPoint p1, CGPoint p2, BOOL flipped) {
    CGPoint v = CGPointMake(p2.x-p1.x,p2.y-p1.y);
    float vmag = sqrt(SQR(v.x) + SQR(v.y)), result = 0;
    v.x /= vmag;
    v.y /= vmag;
    double radians = atan2(v.y,v.x);
    result = ToDeg(radians);
    return (result >=0  ? result : result + 360.0);
}

//判断目标值是否在圆弧上两点的最小区间内 如在，则认为重合过
- (Boolean)containAngle:(CGFloat)targetAngle ByAngleRangeWith:(CGFloat)prevAngle :(CGFloat)lastAngle {
    int32_t biggerAngle = MAX(prevAngle, lastAngle);
    int32_t smallAngle  = MIN(prevAngle, lastAngle);
    int32_t diffAngle = biggerAngle - ToDeg(M_PI);
    
    if (biggerAngle > targetAngle && smallAngle < targetAngle)
    {
        return diffAngle < smallAngle ? YES : NO;
        
    }else if (biggerAngle < targetAngle || smallAngle > targetAngle)
    {
        return diffAngle > smallAngle ? YES : NO;
    }
    return NO;
}

//计算角度差
- (CGFloat)difAngleBetweenStartAngle:(CGFloat)a1 andEndAngle:(CGFloat)a2 {
    int difAngle = 0;
    if (a2 >= a1) {
        difAngle = a2 - a1;
    }else{
        difAngle = 360 - (a1 - a2);
    }
    return difAngle;
}

- (CGFloat)sumAngleBetweenStartAngle:(CGFloat)a1 andDifAngle:(CGFloat)a2 {
    CGFloat sumAngle = 0;
    if (a1 + a2 >= 360) {
        sumAngle = a1 + a2 - 360.f;
    }else if (a1 + a2 < 0){
        sumAngle = a1 + a2 + 360.f;
    }else {
        sumAngle = a1 + a2;
    }
    return sumAngle;
}

//返回次日零点
- (NSString *)getStartTimeDefaultDate:(NSDate *)aDate {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:aDate];
    NSDate *startDate = [calendar dateFromComponents:components];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    NSDateFormatter *dateday = [[NSDateFormatter alloc] init];
    [dateday setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateday setTimeZone:[NSTimeZone systemTimeZone]];
    return [dateday stringFromDate:endDate];
}

//根据一个时间和时钟角度推测另一个时间
- (NSString *)speculateOtherTimeWithDate:(NSString *)aDateStr diffAnle:(CGFloat)diffAnle isStart:(Boolean)isStart {
    
    CGFloat diffSecond = 12.f*60.f*60.f*diffAnle/360.f;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    NSDate *date = [dateFormatter dateFromString:aDateStr];
    
    if (isStart) {
        NSTimeInterval startTimeInterval = [date timeIntervalSince1970];
        NSTimeInterval endTimeInterval = startTimeInterval + diffSecond;
        
        NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:endTimeInterval];
        NSString *dateString = [dateFormatter stringFromDate:endDate];
        self.endDate = dateString;
    }else {
        NSTimeInterval endTimeInterval = [date timeIntervalSince1970];
        NSTimeInterval startTimeInterval = endTimeInterval - diffSecond;
        
        NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:startTimeInterval];
        NSString *dateString = [dateFormatter stringFromDate:startDate];
        self.startDate = dateString;
    }
    
    return [self getMMSSFromSS:(int)diffSecond];
}

-(NSString *)getMMSSFromSS:(int)seconds{
    //format of hour
    NSString *str_hour = [NSString stringWithFormat:@"%d",seconds/3600];
    //format of minute
    NSString *str_minute = [NSString stringWithFormat:@"%d",(seconds%3600)/60];
    //format of second
    //    NSString *str_second = [NSString stringWithFormat:@"%d",seconds%60];
    //format of time
    NSString *format_time = [NSString stringWithFormat:@"%@:%@",str_hour,str_minute];
    
    return format_time;
}

- (void)timeLabelShowString:(NSString *)timeStr {
    NSInteger hourLen, minuteLen;
    NSArray<NSString *> *timeCuts = [timeStr componentsSeparatedByString:@":"];
    hourLen = [timeCuts objectAtIndex:0].length;
    minuteLen = [[timeCuts objectAtIndex:1] integerValue] != 0 ? [timeCuts objectAtIndex:1].length : 0;
    
    if (minuteLen) {
        NSString *timeFormat = [NSString stringWithFormat:@"%@小时%@分 ",[timeCuts objectAtIndex:0],[timeCuts objectAtIndex:1]];
        NSMutableAttributedString *timeAttString = [[NSMutableAttributedString alloc] initWithString:timeFormat];
        [timeAttString addAttribute:NSFontAttributeName
                              value:[UIFont systemFontOfSize:TFScalePoint(28.f)]
                              range:NSMakeRange(0, hourLen)];
        [timeAttString addAttribute:NSFontAttributeName
                              value:[UIFont systemFontOfSize:TFScalePoint(18.f)]
                              range:NSMakeRange(hourLen, 2)];
        [timeAttString addAttribute:NSFontAttributeName
                              value:[UIFont systemFontOfSize:TFScalePoint(28.f)]
                              range:NSMakeRange(hourLen + 2, minuteLen)];
        [timeAttString addAttribute:NSFontAttributeName
                              value:[UIFont systemFontOfSize:TFScalePoint(18.f)]
                              range:NSMakeRange(hourLen+minuteLen+2, 2)];
        self.timeLabel.attributedText = timeAttString;
    }else {
        NSString *timeFormat = [NSString stringWithFormat:@"%@小时",[timeCuts objectAtIndex:0]];
        NSMutableAttributedString *timeAttString = [[NSMutableAttributedString alloc] initWithString:timeFormat];
        [timeAttString addAttribute:NSFontAttributeName
                              value:[UIFont systemFontOfSize:24.f]
                              range:NSMakeRange(0, hourLen)];
        [timeAttString addAttribute:NSFontAttributeName
                              value:[UIFont systemFontOfSize:15.f]
                              range:NSMakeRange(hourLen, 2)];
        self.timeLabel.attributedText = timeAttString;
    }
}

#pragma mark - Getter && Setter
- (UIImageView *)startDot {
    if (!_startDot) {
        _startDot = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _lineWidth -4, _lineWidth -4)];
        _startDot.image = [UIImage imageNamed:@"sleep_start_icon"];
        _startDot.userInteractionEnabled = YES;
        [self addSubview:_startDot];
    }
    return _startDot;
}

- (UIImageView *)endDot {
    if (!_endDot) {
        _endDot = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _lineWidth -4, _lineWidth -4)];
        _endDot.image = [UIImage imageNamed:@"sleep_remind_icon"];
        _endDot.userInteractionEnabled = YES;
        [self addSubview:_endDot];
    }
    return _endDot;
}

- (UIImageView *)clockImageView {
    if (!_clockImageView) {
        _clockImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _radius *2 - _lineWidth,_radius *2- _lineWidth)];
        _clockImageView.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        _clockImageView.image = [UIImage imageNamed:@"sleep_biaopan"];
    }
    return _clockImageView;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, TFScalePoint(180), TFScalePoint(30))];
        _timeLabel.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.textColor = [UIColor blackColor];
        [self addSubview:_timeLabel];
    }
    return _timeLabel;
}

- (void)changeStartAngle:(CGFloat)startAngle{
    _startAngle = startAngle;
    
    [self setNeedsDisplay];
    [self angleToTime];
}

- (void)changeEndAngle:(CGFloat)endAngle {
    _endAngle = endAngle ;
    
    [self setNeedsDisplay];
    [self angleToTime];
}

- (void)changeCycle:(uint32_t)cycle {
    _cycle = cycle;
    [self setNeedsDisplay];
    [self angleToTime];
}



@end
