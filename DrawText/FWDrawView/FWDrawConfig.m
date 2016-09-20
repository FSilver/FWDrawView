//
//  FWDrawConfig.m
//  DrawText
//
//  Created by silver on 16/8/31.
//  Copyright © 2016年 Fsilver. All rights reserved.
//

#import "FWDrawConfig.h"

#define RGB(r, g, b)   [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]

@implementation FWDrawConfig

-(id)init
{
    self = [super init];
    if(self){
        
        _font = [UIFont systemFontOfSize:16];
        _textColor = RGB(26, 26, 26);
        _linkColor = RGB(81, 127, 174); //@{NSForegroundColorAttributeName:RGB(81, 127, 174)};
        _underLineOfLink = 0;
        _numberOfLines = 0;
   
    }
    return self;
}


@end
