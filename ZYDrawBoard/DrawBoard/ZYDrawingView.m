//
//  ZYDrawingView.m
//  ZYDrawBoard
//
//  Created by 王志盼 on 2018/5/31.
//  Copyright © 2018年 王志盼. All rights reserved.
//

#import "ZYDrawingView.h"

@interface ZYDrawingView ()

@property (nonatomic, assign) BOOL isFirstTouch;//区分点击与滑动手势
@property (nonatomic, assign) BOOL isMoveLayer;//区分移动还是创建path
@property (nonatomic, strong) ZYDrawingLayer *drawingLayer;//当前创建的path
@property (nonatomic, strong) ZYDrawingLayer *selectedLayer;//当前选中的path
@property (nonatomic, strong) NSMutableArray *layerArray;//当前创建的path集合

@property (nonatomic, assign) CGPoint startPoint;    //区域选择的起点
@property (nonatomic, assign) CGPoint endPoint;    //区域选择的终点
/**
 选中的区域覆盖view
 */
@property (nonatomic, strong) UIView *areaView;

/**
 现在是否为区域选中
 */
@property (nonatomic, assign) BOOL isAreaSelected;


/**
 被区域选中的所有layer
 */
@property (nonatomic, strong) NSMutableArray *areaLayerArr;
@end

@implementation ZYDrawingView

- (instancetype)init {
    if (self = [super init]) {
        self.userInteractionEnabled = YES;
        self.frame = [UIScreen mainScreen].bounds;
        self.layerArray = [NSMutableArray array];
        self.areaLayerArr = [NSMutableArray array];
        self.backgroundColor = [UIColor blackColor];
        self.isDrawing = true;
        self.isAreaSelected = false;
        [self addSubview:self.areaView];
    }
    return self;
}

- (void)revoke
{
    if (self.isAreaSelected)
    {
        NSMutableArray *tmpArr = [NSMutableArray array];
        int length = (int)self.layerArray.count;
        for (int i = 0; i < length; i++)
        {
            ZYDrawingLayer *layer = self.layerArray[i];
            if (layer.isSelected)
            {
                [layer removeFromSuperlayer];
                [tmpArr addObject:layer];
            }
        }
        [self.layerArray removeObjectsInArray:tmpArr];
    }
    else
    {
        [self.layerArray removeObject:self.selectedLayer];
        [self.selectedLayer removeFromSuperlayer];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    self.isFirstTouch = YES;//是否第一次点击屏幕
    self.isMoveLayer = NO;//是否移动layer
    if (!self.isDrawing)
    {
        self.startPoint = currentPoint;
        if (self.isAreaSelected)
        {
            if ([self pointIsOnAreaLayers:currentPoint])
            {
                int length = (int)self.areaLayerArr.count;
                for (int i = 0; i < length; i++)
                {
                    ZYDrawingLayer *layer = self.areaLayerArr[i];
                    if (CGRectContainsPoint(layer.containRect, currentPoint))
                    {
                        self.selectedLayer = layer;
                        break;
                    }
                }
            }
            else
            {
                self.isAreaSelected = false;
                self.selectedLayer.isSelected = NO;
                self.selectedLayer = nil;
                int length = (int)self.areaLayerArr.count;
                for (int i = 0; i < length; i++)
                {
                    ZYDrawingLayer *layer = self.areaLayerArr[i];
                    layer.isSelected = false;
                }
                [self.areaLayerArr removeAllObjects];
            }
        }
        
        if (self.selectedLayer && CGRectContainsPoint(self.selectedLayer.containRect, currentPoint))
        {
            self.selectedLayer.isSelected = true;
        }
        else
        {
            self.selectedLayer.isSelected = NO;
            self.selectedLayer = nil;
            int length = (int)self.layerArray.count;
            for (int i = length - 1; i >= 0; i--)
            {
                ZYDrawingLayer *layer = self.layerArray[i];
                if (CGRectContainsPoint(layer.containRect, currentPoint))
                {
                    self.selectedLayer = layer;
                    self.selectedLayer.isSelected = YES;
                    break;
                }
            }
        }
    }
    else
    {
        self.selectedLayer.isSelected = false;
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    CGPoint previousPoint = [touch previousLocationInView:self];
    if (self.isFirstTouch)
    {
        if (self.selectedLayer && CGRectContainsPoint(self.selectedLayer.containRect, currentPoint) && !self.isDrawing)
        {
            self.isMoveLayer = CGRectContainsPoint(self.selectedLayer.containRect, currentPoint);//计算当前point是否在已绘制的shapes里边
        }
        else if (self.isDrawing)
        {
            self.drawingLayer = [ZYDrawingLayer createLayerWithStartPoint:previousPoint];//创建相应的layer
            [self.layer addSublayer:self.drawingLayer];
        }
    }
    else
    {
        if (self.isMoveLayer && !self.isDrawing)
        {
            if (self.isAreaSelected && self.areaLayerArr.count > 0)
            {
                for (ZYDrawingLayer *layer in self.areaLayerArr)
                {
                    [layer moveGrafiitiPathPreviousPoint:previousPoint currentPoint:currentPoint];//平移涂鸦shape
                }
            }
            else
            {
                [self.selectedLayer moveGrafiitiPathPreviousPoint:previousPoint currentPoint:currentPoint];//平移涂鸦shape
            }
            
        }
        else if (self.isDrawing)
        {
            [self.drawingLayer movePathWithEndPoint:currentPoint];//绘制新创建的shape
        }
        else if (!self.isDrawing)
        {
            self.areaView.hidden = false;
            self.endPoint = currentPoint;
            [self dealupSelectedArea];
        }
    }
    self.isFirstTouch = NO;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (![self.layerArray containsObject:self.drawingLayer] && !self.isFirstTouch && self.isDrawing)
    {
        [self.layerArray addObject:self.drawingLayer];
    }
    
    if (!self.isDrawing)
    {
        self.areaView.hidden = true;
    }
}

- (void)dealupSelectedArea
{
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    CGFloat minX = MIN(self.startPoint.x, self.endPoint.x);
    CGFloat minY = MIN(self.startPoint.y, self.endPoint.y);
    CGFloat width = fabs(self.endPoint.x - self.startPoint.x);
    CGFloat height = fabs(self.endPoint.y - self.startPoint.y);
    self.areaView.frame = CGRectMake(minX, minY, width, height);
    [self performSelector:@selector(dealupSelectedLayer) withObject:nil afterDelay:0.1];
}

- (void)dealupSelectedLayer
{
    self.isAreaSelected = true;
    int length = (int)self.layerArray.count;
    for (int i = 0; i < length; i++)
    {
        ZYDrawingLayer *layer = self.layerArray[i];
        if (CGRectIntersectsRect(self.areaView.frame, layer.containRect))
        {
            layer.isSelected = true;
            if (![self.areaLayerArr containsObject:layer])
            {
                [self.areaLayerArr addObject:layer];
            }
        }
        else
        {
            layer.isSelected = false;
            [self.areaLayerArr removeObject:layer];
        }
    }
}

- (BOOL)pointIsOnAreaLayers:(CGPoint)point
{
    int length = (int)self.areaLayerArr.count;
    for (int i = 0; i < length; i++)
    {
        ZYDrawingLayer *layer = self.areaLayerArr[i];
        if (CGRectContainsPoint(layer.containRect, point))
        {
            return true;
        }
    }
    return false;
}

- (UIView *)areaView
{
    if (!_areaView)
    {
        _areaView = [[UIView alloc] init];
        _areaView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.2];
        _areaView.hidden = true;
        _areaView.layer.borderColor = [[UIColor whiteColor] CGColor];
        _areaView.layer.borderWidth = 1;
    }
    return _areaView;
}
@end
