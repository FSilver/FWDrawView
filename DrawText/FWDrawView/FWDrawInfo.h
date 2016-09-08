//
//  FWDrawInfo.h
//  DrawText
//
//  Created by silver on 16/8/31.
//  Copyright © 2016年 Fsilver. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

/****************** 表情 ************************/

@interface FWDrawEmojiInfo : NSObject

@property(nonatomic,assign)NSRange range;
@property(nonatomic,strong)NSString *imageName;
@property(nonatomic,assign)CGFloat descender; //微调高度，由UIFont决定

@property(nonatomic,assign)CGRect drawRect; // 此坐标是 CoreText 的坐标系


@end

/******************* 链接 ***********************/
enum {
    FWLinkURL = 1,
    FWLinkCustom = 2,
    FWLinkPhoneNumber = 3,
}typedef FWLinkType;

static NSString *const NSAttributeLinkKey = @"NSAttributeLinkKey";

@interface FWDrawLinkInfo : NSObject

@property(nonatomic,strong)id value;
@property(nonatomic,assign)NSRange range;
@property(nonatomic,strong)NSString *text;
@property(nonatomic,assign)FWLinkType type;

@property(nonatomic,strong)NSArray *drawRectArray;  //折行时有多条数据，不折行一条数据
@property(nonatomic,assign)BOOL isSelected; //链接是否被选中，选中就高亮显示。

@end

/****************** 绘制信息 ************************/

@interface FWDrawInfo : NSObject


@property(nonatomic,assign)CTFrameRef ctFrame;
@property(nonatomic,assign)CGFloat originHeight; //全部显示完全的高度
@property(nonatomic,assign)CGFloat width;        //实际宽度
@property(nonatomic,assign)CGFloat height;       //实际高度
@property(nonatomic,assign)NSInteger lines;         //文本总行数
@property(nonatomic,assign)NSInteger numberOfLines; //限制行数
@property(nonatomic,assign)UIEdgeInsets edgInsets;
@property(nonatomic,strong)NSDictionary *textAttributeDict;
@property(nonatomic,strong)NSAttributedString *attributedString;

@property(nonatomic,strong)NSArray *emojiArray;  //赋值的时候，计算区域
@property(nonatomic,strong)NSArray *linkArray;   //赋值的时候，计算区域


@end











































