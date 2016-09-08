//
//  FWDrawView.h
//  DrawText
//
//  Created by silver on 16/8/31.
//  Copyright © 2016年 Fsilver. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FWDrawInfo.h"
#import "FWDrawParser.h"
#import "FWDrawConfig.h"


@class FWDrawView;
@protocol FWDrawViewDelegate <NSObject>

@optional
-(void)didClickFWDraw:(FWDrawView*)draw; //单击
-(void)didLongPressFWDraw:(FWDrawView*)draw;//双击
-(void)didClickFWDraw:(FWDrawView *)draw byLink:(FWDrawLinkInfo*)link; //点击链接

@end


@interface FWDrawView : UIView

@property(nonatomic,weak)id<FWDrawViewDelegate>delegate;
@property(nonatomic,strong)FWDrawInfo *data;

@property(nonatomic,strong)UIColor *linkBgColor;//选中链接后，链接背景色

@property(nonatomic,strong)UIColor *tapColor; //点击View,高亮色
@property(nonatomic,assign)BOOL allowTapGesture; //是否允许单机

@property(nonatomic,assign)BOOL allowLongPressGesture;  //是否允许长按 
@property(nonatomic,strong)UIColor *longPressColor;     //长按View后，view的背景色

@end
