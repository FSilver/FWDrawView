//
//  FWDrawParser.m
//  DrawText
//
//  Created by silver on 16/8/31.
//  Copyright © 2016年 Fsilver. All rights reserved.
//

#import "FWDrawParser.h"
#import <CoreText/CoreText.h>

@interface FWDrawParser()

@property(nonatomic,strong)FWDrawConfig *config;


@property(nonatomic,strong)NSMutableArray *emojiArray;
@property(nonatomic,strong)NSMutableArray *linkArray;

@end

@implementation FWDrawParser

-(id)initWithConfig:(FWDrawConfig *)config
{
    self = [super init];
    if(self){
        
        _config = config;
        [self configTextAttributeDictionay];
        [self configResultAttributeString];
        
        _emojiArray = [NSMutableArray array];
        _linkArray = [NSMutableArray array];
    }
    return self;
}

#pragma mark - 配置

-(void)configTextAttributeDictionay
{
    //用一个普通的汉子排版的高度，设置为最低高度，保证中文，英文，表情，间距相等，视觉上舒服
    //float minLineHight = config.font.lineHeight - config.font.descender;
    float minLineHight = _config.font.lineHeight;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:0];
    [paragraphStyle setMinimumLineHeight:minLineHight];
    paragraphStyle.lineHeightMultiple = 0;
    
    NSDictionary *ats = @{
                          NSFontAttributeName : _config.font,
                          NSForegroundColorAttributeName:_config.textColor,
                          NSParagraphStyleAttributeName : paragraphStyle,
                          };
    _textAttributeDict = ats;
}

-(void)configResultAttributeString
{
    _resultAttributeString = [[NSMutableAttributedString alloc]init];
    NSAttributedString *attributeString = [[NSAttributedString alloc]initWithString:_config.text attributes:_textAttributeDict];
    [_resultAttributeString appendAttributedString:attributeString];
}

#pragma mark - 解析

-(void)parseEmoji
{
    NSMutableAttributedString *emojiAttributeString = [[NSMutableAttributedString alloc]init];
    
    NSString *emojiRegex = @"\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]";
    NSDictionary *emojiDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"face-icons" ofType:@"plist"]];
    NSString *bundleName = @"expression.bundle";
    NSRegularExpression * regular=[[NSRegularExpression alloc]initWithPattern:emojiRegex options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionCaseInsensitive error:nil];
    //得到符合[微笑]格式的文字位置
    NSArray *matchArray =[regular matchesInString:_config.text options:0 range:NSMakeRange(0, [_config.text length])];
    
    NSUInteger location = 0;
    for (NSTextCheckingResult *match in matchArray) {
        
        NSRange range = match.range;
        //非表情文字
        NSAttributedString *subAttStr = [_resultAttributeString attributedSubstringFromRange:NSMakeRange(location, range.location-location)];
        [emojiAttributeString appendAttributedString:subAttStr];
        location = NSMaxRange(range);
        
        
        NSString* substringForMatch = [_config.text substringWithRange:match.range];
        NSString *imageName = [emojiDict objectForKey:substringForMatch];
        imageName = [NSString stringWithFormat:@"%@/%@",bundleName,imageName];
        UIImage *image = [UIImage imageNamed:imageName];
        if(image && image.size.width>0 && image.size.height>0){
            
            //表情图片存在
            float heihgt = _config.font.lineHeight;
            float width = image.size.width*heihgt/image.size.height;
            NSDictionary *placeHodelDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:width],@"width",[NSNumber numberWithFloat:heihgt],@"height", nil];
            
            NSAttributedString *placeAttStr = [self getPlaceHolderAttributeStringByDelegateDict:placeHodelDict];
            [emojiAttributeString appendAttributedString:placeAttStr];
            
            //收集表情
            FWDrawEmojiInfo *emoji = [[FWDrawEmojiInfo alloc]init];
            emoji.imageName = imageName;
            emoji.range = NSMakeRange(emojiAttributeString.length, 1);
            emoji.descender = _config.font.descender;
            [_emojiArray addObject:emoji];
            
        }else{
            
            //表情图片不存在，直接加上文字，不做处理
            NSAttributedString *temp = [_resultAttributeString attributedSubstringFromRange:NSMakeRange(range.location, range.length)];
            [emojiAttributeString appendAttributedString:temp];
        }
    }
    
    if(location<_config.text.length){
        
        NSAttributedString *temp = [_resultAttributeString attributedSubstringFromRange:NSMakeRange(location, _config.text.length-location)];
        [emojiAttributeString appendAttributedString:temp];
    }
    
    _resultAttributeString = [[NSMutableAttributedString alloc]init];
    [_resultAttributeString appendAttributedString:emojiAttributeString];
}

-(void)parseUrl
{
    NSString *urlRegex = @"([a-zA-Z0-9\\.\\-]+\\.(cn|com|net)(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(http[s]{0,1}://[a-zA-Z0-9\\.\\-]+\\.(cn|com|net)(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.(cn|com|net)(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";
    NSRegularExpression * regular=[[NSRegularExpression alloc]initWithPattern:urlRegex options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionCaseInsensitive error:nil];
    
    NSString *string = _resultAttributeString.string;
    NSArray *matchArray =[regular matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    
    for (NSTextCheckingResult *match in matchArray) {
        
        
        NSRange range = match.range;
        //判断2个range是否有重叠部分
        if(![self isRangeOverlap:range type:FWLinkURL]){
            
            static int urlInt = 1;
            urlInt = (urlInt==1)?0:1;
            NSString *identifier = [NSString stringWithFormat:@"parseUrl_%d",urlInt]; //CTRun差异化处理，防止紧挨的2个Run被合并成一个
            NSDictionary *linkDict = @{NSForegroundColorAttributeName:_config.linkColor,NSAttributeLinkKey:identifier,NSUnderlineStyleAttributeName:[NSNumber numberWithInt:_config.underLineOfLink]};
            
            NSString *text = [string substringWithRange:range];
            [_resultAttributeString addAttributes:linkDict range:range];
            
            FWDrawLinkInfo *link = [[FWDrawLinkInfo alloc]init];
            link.text = text;
            link.range = range;
            link.type = FWLinkURL;
            link.value = text;
            [_linkArray addObject:link];
        } 
    }
}

-(void)parsePhone
{
    NSString *urlRegex = @"\\d{3}-\\d{8}|\\d{3}-\\d{7}|\\d{4}-\\d{8}|\\d{4}-\\d{7}|1+[358]+\\d{9}|\\d{8}|\\d{7}";
    NSRegularExpression * regular=[[NSRegularExpression alloc]initWithPattern:urlRegex options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionCaseInsensitive error:nil];
    
    NSString *string = _resultAttributeString.string;
    NSArray *matchArray =[regular matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    
    for (NSTextCheckingResult *match in matchArray) {
        
        NSRange range = match.range;
        if(![self isRangeOverlap:range type:FWLinkPhoneNumber]){
            
            static int phoneInt = 1;
            phoneInt = (phoneInt==1)?0:1;
            NSString *identifier = [NSString stringWithFormat:@"parsePhone_%d",phoneInt]; //CTRun差异化处理，防止紧挨的2个Run被合并成一个
            NSDictionary *linkDict = @{NSForegroundColorAttributeName:_config.linkColor,NSAttributeLinkKey:identifier,NSUnderlineStyleAttributeName:[NSNumber numberWithInt:_config.underLineOfLink]};
            
            NSString *text = [string substringWithRange:range];
            [_resultAttributeString addAttributes:linkDict range:range];
            
            FWDrawLinkInfo *link = [[FWDrawLinkInfo alloc]init];
            link.text = text;
            link.range = range;
            link.type = FWLinkPhoneNumber;
            link.value = text;
            [_linkArray addObject:link];
        }
    }
}

-(void)addLinkWithValue:(id)value range:(NSRange)range
{
    NSString *string = self.resultAttributeString.string;
    if(range.location+range.length>string.length){
        return;
    }
    
    
    if(![self isRangeOverlap:range type:FWLinkCustom]){
        
        static int linkInt = 1;
        linkInt = (linkInt==1)?0:1;
        NSString *identifier = [NSString stringWithFormat:@"addLink_%d",linkInt]; //CTRun差异化处理，防止紧挨的2个Run被合并成一个
        NSDictionary *linkDict = @{NSForegroundColorAttributeName:_config.linkColor,NSAttributeLinkKey:identifier,NSUnderlineStyleAttributeName:[NSNumber numberWithInt:_config.underLineOfLink]};
        
        [_resultAttributeString addAttributes:linkDict range:range];
        
        NSString *text = [string substringWithRange:range];
        
        FWDrawLinkInfo *link = [[FWDrawLinkInfo alloc]init];
        link.text = text;
        link.range = range;
        link.type = FWLinkCustom;
        link.value = value;
        [_linkArray addObject:link];
    }
}



#pragma mark - 返回 dataInfo

-(FWDrawInfo*)data
{
    //获取 CTFramesetterRef 和  size
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)_resultAttributeString);
    CGSize restrictSize = CGSizeMake(_config.width-_config.edgInsets.left-_config.edgInsets.right, CGFLOAT_MAX);
    CGSize coreTextSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), nil, restrictSize, nil);
    CGFloat totalHeight = coreTextSize.height +_config.edgInsets.top+_config.edgInsets.bottom;
    
    //获取 CTFrameRef
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(_config.edgInsets.left, _config.edgInsets.bottom, _config.width-_config.edgInsets.left-_config.edgInsets.right, coreTextSize.height));
    CTFrameRef ctFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    
    //获取实际宽度
    CGFloat width = [self getWidthWithCTFrame:ctFrame];
    
    //获取限制行数下的高度
    CGFloat height = [self getHeightWithCTFrame:ctFrame numberOfLines:_config.numberOfLines originHeight:totalHeight];
    
    //获取总行数
    CGFloat lineCount = [self getLinesCountWithCTFrame:ctFrame];
    
    
    FWDrawInfo *data = [[FWDrawInfo alloc]init];
    data.originHeight = totalHeight;
    data.height = height;
    data.width = width;
    data.lines = lineCount;
    data.numberOfLines = _config.numberOfLines;
    data.ctFrame = ctFrame;
    data.textAttributeDict = _textAttributeDict;
    data.attributedString = _resultAttributeString;
    data.emojiArray = _emojiArray;
    data.linkArray = [self sortedArray:_linkArray];
    data.edgInsets = _config.edgInsets;
    
    if(path){
        CFRelease(path); 
    }
    if(framesetter){
        CFRelease(framesetter); 
    }
    if(ctFrame){
        CFRelease(ctFrame);
    }
    
    return data;
}


#pragma mark - private

//是否有重叠
-(BOOL)isRangeOverlap:(NSRange)range type:(FWLinkType)type
{
    for (FWDrawLinkInfo *linkInfo  in _linkArray) {
        
        NSRange tempRange = linkInfo.range;
        
        if( range.location + range.length > tempRange.location  &&    range.location < tempRange.location + tempRange.length){
            
            return YES; 
        }
    }
    return NO;
}

//link数组冒泡排序
-(NSArray*)sortedArray:(NSArray*)array
{
    
    if(array.count<= 0){
        return nil;
    }
    
    NSMutableArray *temp = [NSMutableArray arrayWithArray:array];
    NSInteger count = temp.count;
    
    for (int i=0; i<count-1; i++) {
        
        for (int j=i+1; j<count; j++) {
            
            NSArray *beforeArray = [NSArray arrayWithObject:temp[i]];
            NSArray *afterArray = [NSArray arrayWithObject:temp[j]];
            
            FWDrawLinkInfo *before = temp[i];
            FWDrawLinkInfo *after = temp[j];
            
            if(before.range.location > after.range.location){
                
                [temp replaceObjectAtIndex:i withObject:afterArray[0]];
                [temp replaceObjectAtIndex:j withObject:beforeArray[0]];
            }
        }
        //保证i 的位置是最小的
    }
    return temp;
}

//获取width
-(CGFloat)getWidthWithCTFrame:(CTFrameRef)ctFrame
{
    CFArrayRef lines = CTFrameGetLines(ctFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    
    float maxWidth = 0;
    
    for (int i=0; i<lineCount; i++) {
        
        CGFloat ascent;
        CGFloat descent;
        CGFloat leading;
        
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        double width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        width += _config.edgInsets.left + _config.edgInsets.right;
        width = ceilf(width);
        
        if(maxWidth < width){
            maxWidth = width;
        }
    }
    return MIN(maxWidth, _config.width);
}

//获取height
-(CGFloat)getHeightWithCTFrame:(CTFrameRef)ctFrame numberOfLines:(NSInteger)numberOfLines originHeight:(CGFloat)originHeight
{
    CFArrayRef lines = CTFrameGetLines(ctFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    if(numberOfLines >= lineCount || numberOfLines == 0){
        return originHeight;
    }
    
    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, numberOfLines), lineOrigins);
    
    CGFloat line_y = lineOrigins[numberOfLines -1].y;  //最后一行line的原点y坐标
    
    CGFloat ascent;
    CGFloat descent;
    CGFloat leading;
    
    CTLineRef line = CFArrayGetValueAtIndex(lines, numberOfLines-1);
    CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    
    CGFloat linesOfHeight = originHeight - line_y - _config.font.descender;
    
    return ceilf(linesOfHeight);
}

//获取总行数
-(NSInteger)getLinesCountWithCTFrame:(CTFrameRef)ctFrame
{
    CFArrayRef lines = CTFrameGetLines(ctFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    return lineCount;
}

#pragma mark - 表情占位符

static CGFloat ascentCallback(void *ref){
    
    NSNumber *number = (NSNumber*)[(__bridge NSDictionary*)ref objectForKey:@"height"];
    float height = number.floatValue;
    return height;
}

static CGFloat descentCallback(void *ref){
    return 0;
}

static CGFloat widthCallback(void* ref){
    
    NSNumber *number = (NSNumber*)[(__bridge NSDictionary*)ref objectForKey:@"width"];
    float width = number.floatValue;
    return width;
}

-(NSAttributedString*)getPlaceHolderAttributeStringByDelegateDict:(NSDictionary*)dict
{
    static int  a = 1;
    NSMutableDictionary *differentAttributeDict = [NSMutableDictionary dictionaryWithDictionary:_textAttributeDict];
    a = (a==1)?0:1;
    [differentAttributeDict setObject:[NSNumber numberWithInt:a] forKey:@"identifier"];
    
    
    CTRunDelegateCallbacks callbacks;
    memset(&callbacks, 0, sizeof(CTRunDelegateCallbacks));
    callbacks.version = kCTRunDelegateVersion1;
    callbacks.getAscent = ascentCallback;
    callbacks.getDescent = descentCallback;
    callbacks.getWidth = widthCallback;
    
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (__bridge void *)(dict));
    
    // 使用 0xFFFC 作为空白的占位符
    unichar objectReplacementChar = 0xFFFC;
    NSString * content = [NSString stringWithCharacters:&objectReplacementChar length:1];
    
    NSMutableAttributedString * space =
    [[NSMutableAttributedString alloc] initWithString:content
                                           attributes:differentAttributeDict];
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)space,
                                   CFRangeMake(0, 1), kCTRunDelegateAttributeName, delegate);
    CFRelease(delegate);
    return space;
}

-(NSAttributedString*)parseEmojiSizeDict:(NSDictionary*)dict attributeDict:(NSDictionary*)attributeDict
{
    //表情占位符，差异化处理，防止2个紧挨着的表情，被合并为一个CTRUn
    static int  a = 1;
    NSMutableDictionary *differentAttributeDict = [NSMutableDictionary dictionaryWithDictionary:attributeDict];
    a = (a==1)?0:1;
    [differentAttributeDict setObject:[NSNumber numberWithInt:a] forKey:@"identifier"];
    
    
    CTRunDelegateCallbacks callbacks;
    memset(&callbacks, 0, sizeof(CTRunDelegateCallbacks));
    callbacks.version = kCTRunDelegateVersion1;
    callbacks.getAscent = ascentCallback;
    callbacks.getDescent = descentCallback;
    callbacks.getWidth = widthCallback;
    
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (__bridge void *)(dict));
    
    // 使用 0xFFFC 作为空白的占位符
    unichar objectReplacementChar = 0xFFFC;
    NSString * content = [NSString stringWithCharacters:&objectReplacementChar length:1];
    
    NSMutableAttributedString * space =
    [[NSMutableAttributedString alloc] initWithString:content
                                           attributes:differentAttributeDict];
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)space,
                                   CFRangeMake(0, 1), kCTRunDelegateAttributeName, delegate);
    CFRelease(delegate);
    return space;
}


@end
















































