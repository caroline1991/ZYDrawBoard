//
//  ZYDrawingLayer.h
//  ZYDrawBoard
//
//  Created by 王志盼 on 2018/5/31.
//  Copyright © 2018年 王志盼. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface ZYDrawingLayer : CAShapeLayer

@property (nonatomic, assign) BOOL isSelected;    /**< 是否选中 */
@property (nonatomic, assign, readonly) CGRect containRect;

+ (ZYDrawingLayer *)createLayerWithStartPoint:(CGPoint)startPoint;

- (void)movePathWithStartPoint:(CGPoint)startPoint;
- (void)movePathWithEndPoint:(CGPoint)EndPoint;
- (void)movePathWithPreviousPoint:(CGPoint)previousPoint currentPoint:(CGPoint)currentPoint;

- (void)movePathWithStartPoint:(CGPoint)startPoint isSelected:(BOOL)isSelected;
- (void)movePathWithEndPoint:(CGPoint)EndPoint isSelected:(BOOL)isSelected;
- (void)movePathWithPreviousPoint:(CGPoint)previousPoint
                     currentPoint:(CGPoint)currentPoint
                       isSelected:(BOOL)isSelected;

- (void)moveGrafiitiPathPreviousPoint:(CGPoint)previousPoint currentPoint:(CGPoint)currentPoint;
@end
