# FWDrawView
富文本解析，包括表情，链接，电话号码，自定义链接。折行处理，边距处理等
## 使用方法
三步，使用FWDrawConfig来进行配置，FWDrawParser提供解析方法，FWDrawView绘制富文本
### FWDrawConfig--配置
    FWDrawConfig *config = [[FWDrawConfig alloc]init];
    config.width = 280; //文本最大宽度
    config.text = text; //文本内容
    config.edgInsets = UIEdgeInsetsMake(10, 10, 10, 10); //文本上下左右边距
    config.textColor = [UIColor grayColor]; //文本字体颜色
    config.numberOfLines = 0; //文本最大显示行数
    config.linkColor = [UIColor blueColor]; //链接字体颜色
### FWDrawParser--解析
    FWDrawParser *parser = [[FWDrawParser alloc]initWithConfig:config];
    [parser parseEmoji];  //解析表情
    [parser parseUrl];    //解析链接
    [parser parsePhone];  //解析电话号码
    [parser addLinkWithValue:@"life" range:NSMakeRange(2, 3)];  //自定义添加，链接文字
### FWDrawView--绘制
    FWDrawInfo *data = parser.data;
    FWDrawView *draw = [[FWDrawView alloc]initWithFrame:CGRectMake(10, 60, data.width, data.height)];
    draw.data = data;
    draw.delegate = self;
    draw.allowTapGesture = YES;
    draw.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
    [self.view addSubview:draw];
#### 代理方法
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
### 请看实际解析效果图
![FWDrawView](https://github.com/FSilver/FWDrawView/blob/master/draw.png)
