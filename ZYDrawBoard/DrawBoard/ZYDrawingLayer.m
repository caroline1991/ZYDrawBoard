//
//  ZYDrawingLayer.m
//  ZYDrawBoard
//
//  Created by 王志盼 on 2018/5/31.
//  Copyright © 2018年 王志盼. All rights reserved.
//

#import "ZYDrawingLayer.h"
#import <UIKit/UIKit.h>

#define ZYDRAWINGPATHWIDTH 2
#define ZYDRAWINGBUFFER 12
#define ZYDRAWINGORIGINCOLOR [UIColor whiteColor].CGColor
#define ZYDRAWINGSELECTEDCOLOR [UIColor whiteColor].CGColor
#define ZYMaxValue 999999

@interface ZYDrawingLayer ()

@property (nonatomic, assign) CGPoint startPoint;    /**< 起始坐标 */
@property (nonatomic, assign) CGPoint endPoint;    /**< 终点坐标 */

@property (nonatomic, assign, readwrite) CGRect containRect;

@property (nonatomic, assign) CGFloat minX;
@property (nonatomic, assign) CGFloat minY;
@property (nonatomic, assign) CGFloat maxX;
@property (nonatomic, assign) CGFloat maxY;
/**
 虚线layer
 */
@property (nonatomic, strong) CAShapeLayer *dashedLineLayer;
@end

@implementation ZYDrawingLayer

- (instancetype)init {
    if (self = [super init]) {
        self.frame = [UIScreen mainScreen].bounds;
        self.lineJoin = kCALineJoinRound;
        self.lineCap = kCALineCapRound;
        self.strokeColor = self.fillColor = ZYDRAWINGORIGINCOLOR;
        self.lineWidth = ZYDRAWINGPATHWIDTH;
        self.isSelected = NO;
        
        self.minX = ZYMaxValue;
        self.minY = ZYMaxValue;
        self.maxX = -ZYMaxValue;
        self.maxY = -ZYMaxValue;
    }
    return self;
}

- (void)setIsSelected:(BOOL)isSelected
{
    if (_isSelected == isSelected) return;
    _isSelected = isSelected;
    
    if (isSelected)
    {
        self.strokeColor = self.fillColor = [UIColor redColor].CGColor;
        self.dashedLineLayer.hidden = false;
    }
    else
    {
        self.strokeColor = self.fillColor = [UIColor whiteColor].CGColor;
        self.dashedLineLayer.hidden = true;
    }
    
}



+ (ZYDrawingLayer *)createLayerWithStartPoint:(CGPoint)startPoint {
    ZYDrawingLayer *layer = [[[self class] alloc] init];
    layer.startPoint = startPoint;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineJoinStyle = kCGLineJoinRound;
    path.flatness = 0.1;
    [path moveToPoint:startPoint];
    layer.path = path.CGPath;
    
    [layer dealupXYWithPoint:startPoint];
    return layer;
}

- (void)movePathWithEndPoint:(CGPoint)endPoint {
    [self movePathWithEndPoint:endPoint isSelected:self.isSelected];
}

- (void)movePathWithStartPoint:(CGPoint)startPoint {
    [self movePathWithStartPoint:startPoint isSelected:self.isSelected];
}

- (void)movePathWithPreviousPoint:(CGPoint)previousPoint currentPoint:(CGPoint)currentPoint {
    CGPoint startPoint = CGPointMake(self.startPoint.x+currentPoint.x-previousPoint.x, self.startPoint.y+currentPoint.y-previousPoint.y);
    CGPoint endPoint = CGPointMake(self.endPoint.x+currentPoint.x-previousPoint.x, self.endPoint.y+currentPoint.y-previousPoint.y);
    [self movePathWithStartPoint:startPoint endPoint:endPoint isSelected:self.isSelected];
}

- (void)movePathWithStartPoint:(CGPoint)startPoint isSelected:(BOOL)isSelected {
    [self movePathWithStartPoint:startPoint endPoint:self.endPoint isSelected:isSelected];
}

- (void)movePathWithEndPoint:(CGPoint)endPoint isSelected:(BOOL)isSelected{
    [self movePathWithStartPoint:self.startPoint endPoint:endPoint isSelected:isSelected];
}

- (void)movePathWithPreviousPoint:(CGPoint)previousPoint currentPoint:(CGPoint)currentPoint isSelected:(BOOL)isSelected {
    CGPoint startPoint = CGPointMake(self.startPoint.x+currentPoint.x-previousPoint.x, self.startPoint.y+currentPoint.y-previousPoint.y);
    CGPoint endPoint = CGPointMake(self.endPoint.x+currentPoint.x-previousPoint.x, self.endPoint.y+currentPoint.y-previousPoint.y);
    [self movePathWithStartPoint:startPoint endPoint:endPoint isSelected:isSelected];
}

- (void)moveGrafiitiPathPreviousPoint:(CGPoint)previousPoint currentPoint:(CGPoint)currentPoint {
    self.maxX += currentPoint.x - previousPoint.x;
    self.minX += currentPoint.x - previousPoint.x;
    self.maxY += currentPoint.y - previousPoint.y;
    self.minY += currentPoint.y - previousPoint.y;
    
    self.startPoint = CGPointMake(self.startPoint.x + currentPoint.x - previousPoint.x, self.startPoint.y + currentPoint.y - previousPoint.y);
    self.endPoint = CGPointMake(self.endPoint.x + currentPoint.x - previousPoint.x, self.endPoint.y + currentPoint.y - previousPoint.y);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithCGPath:self.path];
    [path applyTransform:CGAffineTransformMakeTranslation(currentPoint.x - previousPoint.x, currentPoint.y - previousPoint.y)];
    self.path = path.CGPath;
    
    path = [UIBezierPath bezierPathWithCGPath:_dashedLineLayer.path];
    [path applyTransform:CGAffineTransformMakeTranslation(currentPoint.x - previousPoint.x, currentPoint.y - previousPoint.y)];
    _dashedLineLayer.path = path.CGPath;
    
    _dashedLineLayer.hidden = false;
}

- (void)movePathWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint isSelected:(BOOL)isSelected {
    self.startPoint = startPoint;
    self.endPoint = endPoint;
    self.isSelected = isSelected;
    [self moveGraffitiPathWithStartPoint:startPoint endPoint:endPoint isSelected:isSelected];
    [self dealupXYWithPoint:startPoint];
    [self dealupXYWithPoint:endPoint];
}


- (void)moveArrowPathWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint isSelected:(BOOL)isSelected {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:startPoint];
    [path addLineToPoint:endPoint];
    [path appendPath:[self createArrowWithStartPoint:startPoint endPoint:endPoint]];
    self.path = path.CGPath;
}

- (void)moveLinePathWithStartPoint:(CGPoint)startPoint
                          endPoint:(CGPoint)endPoint
                        isSelected:(BOOL)isSelected {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:startPoint];
    [path addLineToPoint:endPoint];
    self.path = path.CGPath;
}

- (void)moveRulerArrowPathWithStartPoint:(CGPoint)startPoint
                                endPoint:(CGPoint)endPoint
                              isSelected:(BOOL)isSelected {
    self.path = [self createRulerArrowWithStartPoint:startPoint endPoint:endPoint length:0].CGPath;
}

- (void)moveRulerLinePathWithStartPoint:(CGPoint)startPoint
                               endPoint:(CGPoint)endPoint
                             isSelected:(BOOL)isSelected {
    self.path = [self createRulerLinePathWithEndPoint:endPoint andStartPoint:startPoint length:0].CGPath;
}

- (void)moveGraffitiPathWithStartPoint:(CGPoint)startPoint
                              endPoint:(CGPoint)endPoint
                            isSelected:(BOOL)isSelected {
    UIBezierPath *path = [UIBezierPath bezierPathWithCGPath:self.path];
    [path addLineToPoint:endPoint];
    [path moveToPoint:endPoint];
    self.path = path.CGPath;
}

- (UIBezierPath *)createRulerLinePathWithEndPoint:(CGPoint)endPoint andStartPoint:(CGPoint)startPoint length:(CGFloat)length
{
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:startPoint];
    CGFloat angle = [self angleWithFirstPoint:startPoint andSecondPoint:endPoint];
    CGPoint pointMiddle = CGPointMake((startPoint.x+endPoint.x)/2, (startPoint.y+endPoint.y)/2);
    CGFloat offsetX = length*cos(angle);
    CGFloat offsetY = length*sin(angle);
    CGPoint pointMiddle1 = CGPointMake(pointMiddle.x-offsetX, pointMiddle.y-offsetY);
    CGPoint pointMiddle2 = CGPointMake(pointMiddle.x+offsetX, pointMiddle.y+offsetY);
    [bezierPath addLineToPoint:pointMiddle1];
    [bezierPath moveToPoint:pointMiddle2];
    [bezierPath addLineToPoint:endPoint];
    [bezierPath moveToPoint:endPoint];
    angle = [self angleEndWithFirstPoint:startPoint andSecondPoint:endPoint];
    CGPoint point1 = CGPointMake(endPoint.x+10*sin(angle), endPoint.y+10*cos(angle));
    CGPoint point2 = CGPointMake(endPoint.x-10*sin(angle), endPoint.y-10*cos(angle));
    [bezierPath addLineToPoint:point1];
    [bezierPath addLineToPoint:point2];
    CGPoint point3 = CGPointMake(point1.x-(endPoint.x-startPoint.x), point1.y-(endPoint.y-startPoint.y));
    CGPoint point4 = CGPointMake(point2.x-(endPoint.x-startPoint.x), point2.y-(endPoint.y-startPoint.y));
    [bezierPath moveToPoint:point3];
    [bezierPath addLineToPoint:point4];
    [bezierPath setLineWidth:4];
    
    return bezierPath;
}

- (UIBezierPath *)createRulerArrowWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint length:(CGFloat)length {
    CGFloat angle = [self angleWithFirstPoint:startPoint andSecondPoint:endPoint];
    CGPoint pointMiddle = CGPointMake((startPoint.x+endPoint.x)/2, (startPoint.y+endPoint.y)/2);
    CGFloat offsetX = length*cos(angle);
    CGFloat offsetY = length*sin(angle);
    CGPoint pointMiddle1 = CGPointMake(pointMiddle.x-offsetX, pointMiddle.y-offsetY);
    CGPoint pointMiddle2 = CGPointMake(pointMiddle.x+offsetX, pointMiddle.y+offsetY);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:startPoint];
    [path addLineToPoint:pointMiddle1];
    [path moveToPoint:pointMiddle2];
    [path addLineToPoint:endPoint];
    [path appendPath:[self createArrowWithStartPoint:pointMiddle1 endPoint:startPoint]];
    [path appendPath:[self createArrowWithStartPoint:pointMiddle2 endPoint:endPoint]];
    return path;
}

- (UIBezierPath *)createArrowWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint {
    CGPoint controllPoint = CGPointZero;
    CGPoint pointUp = CGPointZero;
    CGPoint pointDown = CGPointZero;
    CGFloat distance = [self distanceBetweenStartPoint:startPoint endPoint:endPoint];
    CGFloat distanceX = 8.0 * (ABS(endPoint.x - startPoint.x) / distance);
    CGFloat distanceY = 8.0 * (ABS(endPoint.y - startPoint.y) / distance);
    CGFloat distX = 4.0 * (ABS(endPoint.y - startPoint.y) / distance);
    CGFloat distY = 4.0 * (ABS(endPoint.x - startPoint.x) / distance);
    if (endPoint.x >= startPoint.x)
    {
        if (endPoint.y >= startPoint.y)
        {
            controllPoint = CGPointMake(endPoint.x - distanceX, endPoint.y - distanceY);
            pointUp = CGPointMake(controllPoint.x + distX, controllPoint.y - distY);
            pointDown = CGPointMake(controllPoint.x - distX, controllPoint.y + distY);
        }
        else
        {
            controllPoint = CGPointMake(endPoint.x - distanceX, endPoint.y + distanceY);
            pointUp = CGPointMake(controllPoint.x - distX, controllPoint.y - distY);
            pointDown = CGPointMake(controllPoint.x + distX, controllPoint.y + distY);
        }
    }
    else
    {
        if (endPoint.y >= startPoint.y)
        {
            controllPoint = CGPointMake(endPoint.x + distanceX, endPoint.y - distanceY);
            pointUp = CGPointMake(controllPoint.x - distX, controllPoint.y - distY);
            pointDown = CGPointMake(controllPoint.x + distX, controllPoint.y + distY);
        }
        else
        {
            controllPoint = CGPointMake(endPoint.x + distanceX, endPoint.y + distanceY);
            pointUp = CGPointMake(controllPoint.x + distX, controllPoint.y - distY);
            pointDown = CGPointMake(controllPoint.x - distX, controllPoint.y + distY);
        }
    }
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    [arrowPath moveToPoint:endPoint];
    [arrowPath addLineToPoint:pointDown];
    [arrowPath addLineToPoint:pointUp];
    [arrowPath addLineToPoint:endPoint];
    return arrowPath;
}

- (CGFloat)distanceBetweenStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    CGFloat xDist = (endPoint.x - startPoint.x);
    CGFloat yDist = (endPoint.y - startPoint.y);
    return sqrt((xDist * xDist) + (yDist * yDist));
}

- (CGFloat)angleWithFirstPoint:(CGPoint)firstPoint andSecondPoint:(CGPoint)secondPoint
{
    CGFloat dx = secondPoint.x - firstPoint.x;
    CGFloat dy = secondPoint.y - firstPoint.y;
    CGFloat angle = atan2f(dy, dx);
    return angle;
}

- (CGFloat)angleEndWithFirstPoint:(CGPoint)firstPoint andSecondPoint:(CGPoint)secondPoint
{
    CGFloat dx = secondPoint.x - firstPoint.x;
    CGFloat dy = secondPoint.y - firstPoint.y;
    CGFloat angle = atan2f(fabs(dy), fabs(dx));
    if (dx*dy>0) {
        return M_PI-angle;
    }
    return angle;
}


- (CGRect)containRect
{
    CGFloat minX = self.minX - 2;
    CGFloat minY = self.minY - 2;
    CGFloat maxX = self.maxX + 2;
    CGFloat maxY = self.maxY + 2;
    CGFloat width = maxX - minX;
    CGFloat height = maxY - minY;
    return CGRectMake(minX, minY, width, height);
}

- (CAShapeLayer *)dashedLineLayer
{
    
    if (!_dashedLineLayer)
    {
        _dashedLineLayer = [CAShapeLayer layer];
        [self addSublayer:_dashedLineLayer];
    }
    CGFloat minX = self.minX - 2;
    CGFloat minY = self.minY - 2;
    CGFloat maxX = self.maxX + 2;
    CGFloat maxY = self.maxY + 2;
    CGFloat width = maxX - minX;
    CGFloat height = maxY - minY;
    //layer
    _dashedLineLayer.frame = CGRectMake(minX, minY, width, height);
    [_dashedLineLayer setFillColor:[[UIColor clearColor] CGColor]];
    
    //设置虚线的颜色 - 颜色请必须设置
    [_dashedLineLayer setStrokeColor:[[UIColor whiteColor] CGColor]];
    
    //设置虚线的高度
    [_dashedLineLayer setLineWidth:1.0f];
    
    //设置类型
    [_dashedLineLayer setLineJoin:kCALineJoinRound];
    
    /*
     10.f=每条虚线的长度
     3.f=每两条线的之间的间距
     */
    [_dashedLineLayer setLineDashPattern:
     [NSArray arrayWithObjects:[NSNumber numberWithInt:6.f],
      [NSNumber numberWithInt:3.f],nil]];
    
    // Setup the path
    CGMutablePathRef path1 = CGPathCreateMutable();
    
    CGPathMoveToPoint(path1, NULL,0, 0);
    
    CGPathAddLineToPoint(path1, NULL, width, 0);
    
    CGPathAddLineToPoint(path1, NULL, width, height);
    
    CGPathAddLineToPoint(path1, NULL, 0, height);
    
    CGPathAddLineToPoint(path1, NULL, 0, 0);
    [_dashedLineLayer setPath:path1];
    
    CGPathRelease(path1);
    
    _dashedLineLayer.hidden = true;
    
    return _dashedLineLayer;
}

- (void)dealupXYWithPoint:(CGPoint)point
{
    self.maxX = MAX(self.maxX, point.x);
    self.maxY = MAX(self.maxY, point.y);
    self.minX = MIN(self.minX, point.x);
    self.minY = MIN(self.minY, point.y);
}

@end
