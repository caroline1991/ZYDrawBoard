//
//  ZYDrawingView.h
//  ZYDrawBoard
//
//  Created by 王志盼 on 2018/5/31.
//  Copyright © 2018年 王志盼. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZYDrawingLayer.h"

@interface ZYDrawingView : UIView

@property (nonatomic, copy) void (^drawingLayerSelectedBlock)(BOOL isSelected);


/**
 是画板，还是选择撤销
 */
@property (nonatomic, assign) BOOL isDrawing;

- (void)revoke;

@end
