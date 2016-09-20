//
//  FWDrawConfig.h
//  DrawText
//
//  Created by silver on 16/8/31.
//  Copyright © 2016年 Fsilver. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FWDrawConfig : NSObject

@property(nonatomic,strong)NSString *text;
@property(nonatomic,assign)CGFloat width;
@property(nonatomic,assign)UIFont  *font;
@property(nonatomic,strong)UIColor *textColor;
@property(nonatomic,strong)UIColor *linkColor;
@property(nonatomic,assign)int underLineOfLink;
@property(nonatomic,assign)NSInteger numberOfLines; 
@property(nonatomic,assign)UIEdgeInsets edgInsets;

@end
