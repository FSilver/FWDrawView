//
//  FWDrawParser.h
//  DrawText
//
//  Created by silver on 16/8/31.
//  Copyright © 2016年 Fsilver. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FWDrawConfig.h"
#import "FWDrawInfo.h"

@interface FWDrawParser : NSObject

@property(nonatomic,strong)FWDrawInfo *data;
@property(nonatomic,strong)NSMutableAttributedString *resultAttributeString;
@property(nonatomic,strong)NSDictionary *textAttributeDict;
-(id)initWithConfig:(FWDrawConfig*)config;
-(void)parseEmoji;
-(void)parseUrl;
-(void)parsePhone;
-(void)addLinkWithValue:(id)value range:(NSRange)range;

@end
