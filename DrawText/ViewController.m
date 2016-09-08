//
//  ViewController.m
//  DrawText
//
//  Created by silver on 16/8/31.
//  Copyright © 2016年 Fsilver. All rights reserved.
//

#import "ViewController.h"
#import "FWDrawView.h"



#define kDemoText @"时间不停地走[委屈]，生命不停地走[可伶]，而我们也要不停地走[偷笑]。人生如一杯浓茶，初虽苦涩[花心][酷]\n越到后面18320549314，越觉www.apple.baidu.health.debug.goole.com醇香，人生如一艘帆船。"


@interface ViewController ()<FWDrawViewDelegate>
{
    FWDrawView *_drawView;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    

    FWDrawInfo *data =[ViewController parseNo:kDemoText];

    FWDrawView *draw = [[FWDrawView alloc]initWithFrame:CGRectMake(10, 60, data.width, data.height)];
    draw.data = data;
    draw.delegate = self;
    draw.allowTapGesture = YES;
    draw.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
    [self.view addSubview:draw];
    
    NSArray *arr = @[@"全部解析",@"表情",@"链接",@"折行"];
    for (int i=0; i<arr.count; i++) {
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btn.frame = CGRectMake(80*i,draw.frame.origin.y + draw.frame.size.height, 80, 50);
        btn.tag = i;
        [btn setTitle:arr[i] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        
        if(i==0){
            [self btnClicked:btn];
        }
    }


}

-(void)btnClicked:(UIButton*)btn
{
    FWDrawInfo *data = nil;
    
    switch (btn.tag) {
        case 0:
        {
            data = [ViewController parseAll:kDemoText];  //全部解析
        }
            break;
        case 1:
        {
            data = [ViewController parseEmoji:kDemoText]; //仅仅解析表情
        }
            break;
        case 2:
        {
            data = [ViewController parseLink:kDemoText];//仅仅解析链接
        }
            break;
        case 3:
        {
            int a = rand()%2;
            int numberOfLines = (a==1)?3:5;
            
            data = [ViewController parseAll:kDemoText lines:numberOfLines]; //限制显示行数
        }
            break;
            
        default:
            break;
    }
    
    if(!_drawView){
        _drawView = [[FWDrawView alloc]init];
        _drawView.delegate = self;
        _drawView.allowTapGesture = YES;
    }
    _drawView.frame = CGRectMake(10, 300, data.width, data.height); //当只有一行时 data.width <= config.width
    _drawView.data = data;
    _drawView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
    [self.view addSubview:_drawView];
    
}



-(void)didClickFWDraw:(FWDrawView *)draw byLink:(FWDrawLinkInfo *)link
{
    switch (link.type) {
        case FWLinkURL:
        {
            NSLog(@"点击的是 url   value:%@  text:%@",link.value,link.text);
        }
            break;
        case FWLinkPhoneNumber:
        {
       
            NSLog(@"点击的是 phone   value:%@  text:%@",link.value,link.text);
        }
            break;
        case FWLinkCustom:
        {
        
            NSLog(@"点击的是 自定义链接   value:%@  text:%@",link.value,link.text);
        }
            break;
            
        default:
            break;
    }
}

-(void)didClickFWDraw:(FWDrawView *)draw
{
    NSLog(@"单击");
}



#pragma mark - 解析

//全部解析
+(FWDrawInfo*)parseAll:(NSString*)text
{
    FWDrawConfig *config = [[FWDrawConfig alloc]init];
    config.width = 280;
    config.text = text;
    config.edgInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    
    FWDrawParser *parser = [[FWDrawParser alloc]initWithConfig:config];
    [parser parseEmoji];  //解析表情
    [parser parseUrl];    //解析链接
    [parser parsePhone];  //解析电话号码
    [parser addLinkWithValue:@"life" range:NSMakeRange(2, 3)];  //自定义添加，链接文字

    return parser.data;
}

//解析表情
+(FWDrawInfo*)parseEmoji:(NSString*)text
{
    FWDrawConfig *config = [[FWDrawConfig alloc]init];
    config.width = 280;
    config.text = text;
    config.edgInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    
    FWDrawParser *parser = [[FWDrawParser alloc]initWithConfig:config];
    [parser parseEmoji];  //解析表情
  
    return parser.data;
}


//解析链接
+(FWDrawInfo*)parseLink:(NSString*)text
{
    FWDrawConfig *config = [[FWDrawConfig alloc]init];
    config.width = 280;
    config.text = text;
    config.edgInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    
    FWDrawParser *parser = [[FWDrawParser alloc]initWithConfig:config];
    [parser parseUrl];  //解析电话号码
    [parser parsePhone];  //解析表情
    [parser addLinkWithValue:@"life" range:NSMakeRange(0, 2)];  //自定义添加，链接文字

    
    return parser.data;
}

//折行
+(FWDrawInfo*)parseAll:(NSString*)text lines:(NSInteger)numberOfLines
{
    FWDrawConfig *config = [[FWDrawConfig alloc]init];
    config.width = 280;
    config.text = text;
    config.numberOfLines = numberOfLines;
    config.edgInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    
    FWDrawParser *parser = [[FWDrawParser alloc]initWithConfig:config];
    [parser parseUrl];    //解析链接
    [parser parsePhone];  //解析电话号码
    [parser parseEmoji];  //解析表情
    
    return parser.data;
}

//不解析
+(FWDrawInfo*)parseNo:(NSString*)text
{
    FWDrawConfig *config = [[FWDrawConfig alloc]init];
    config.width = 280;
    config.text = text;
    config.edgInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    
    FWDrawParser *parser = [[FWDrawParser alloc]initWithConfig:config];
    
    
    return parser.data;
}


@end
