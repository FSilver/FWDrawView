//
//  FWDrawView.m
//  DrawText
//
//  Created by silver on 16/8/31.
//  Copyright © 2016年 Fsilver. All rights reserved.
//

#import "FWDrawView.h"


@interface FWDrawView()
{
    FWDrawLinkInfo *_activeLinkInfo;
    CGFloat _lastLineRightX;  //UI坐标系
    CGFloat _lastLineOriginY; //UI坐标系
    
    UIColor *_originBackGoroundColor;
    BOOL  _touchEnterByTap;
    
    UILongPressGestureRecognizer *_longPressGesture;
    BOOL  _isLongPressStatus;
}

@end


@implementation FWDrawView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor clearColor];
        self.linkBgColor = [[UIColor blackColor]colorWithAlphaComponent:0.2];
        _tapColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:228/255.0 alpha:1];
        _longPressColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:228/255.0 alpha:1];
        _lastLineRightX = -1;
        _lastLineOriginY = -1;
        _allowTapGesture = NO;
        _allowLongPressGesture = NO;
    }
    return self;
}

-(void)setAllowLongPressGesture:(BOOL)allowLongPressGesture
{
    if(_allowLongPressGesture == allowLongPressGesture){
        return;
    }
    
    _allowLongPressGesture = allowLongPressGesture;
    if(allowLongPressGesture){
        
        [self addLongPressGesture];
        
    }else{
        [self removeLongPressGesture];
    }
}


-(void)setData:(FWDrawInfo *)data
{
    if(_data == data){
        return;
    }
    _data = data;
    [self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if(self.data == nil){
        return;
    }
    
    CGContextRef  context = UIGraphicsGetCurrentContext();
    //坐标系coreText --》 UIkit坐标系
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    _lastLineOriginY = -1;
    _lastLineRightX = -1;
    if(_data.numberOfLines == 0 || _data.numberOfLines >= _data.lines){
        
        CTFrameDraw(self.data.ctFrame, context);
        
    }else{
        
        [self drawLineByContext:context];
    }
    

    //作用是，画表情
    for (FWDrawEmojiInfo * emoji in self.data.emojiArray) {
        
        
        //转为UI坐标系,表情位置大于有效区域，就break
        float y = _data.height - emoji.drawRect.origin.y - emoji.drawRect.size.height;
        if(y + emoji.drawRect.size.height > _data.height - _data.edgInsets.bottom){
            break;
        }
    
        BOOL drawImage = NO;
        if(_lastLineOriginY == -1 && _lastLineRightX == -1){
            //全部显示
            drawImage = YES;
            
        }else{
            //限制行数
            if(y < _lastLineOriginY){
                //不是最后一行
                drawImage = YES;
            }else if(emoji.drawRect.origin.x + emoji.drawRect.size.width < _lastLineRightX){
                //是最后一行
                 drawImage = YES;
            }
        }
        
        if(drawImage){
            UIImage *image = [UIImage imageNamed:emoji.imageName];
            if(image){
                CGContextDrawImage(context, emoji.drawRect, image.CGImage);
            }
        }
      }
    
    
    //作用是，选中链接后，链接高亮显示
    for (FWDrawLinkInfo *url in self.data.linkArray) {
        
        for (NSValue  *value in url.drawRectArray) {
            
            
            //转为UI坐标系
            CGRect urlRect = [value CGRectValue];
            CGFloat y = _data.height - urlRect.origin.y - urlRect.size.height;
            if( y + urlRect.size.height > _data.height - _data.edgInsets.bottom){
                break;
            }
            
            if(url.isSelected){
            
                CGRect urlRect = [value CGRectValue];
                CGContextSetFillColorWithColor(context,self.linkBgColor.CGColor);
                CGContextFillRect(context , urlRect);
            }
        }
    }
}



-(void)drawLineByContext:(CGContextRef)context
{
    CGPathRef path = CTFrameGetPath(_data.ctFrame);
    CGRect rect = CGPathGetBoundingBox(path);
    CFArrayRef lines = CTFrameGetLines(_data.ctFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    NSInteger numberOfLines = MIN(_data.numberOfLines, lineCount);

    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(_data.ctFrame, CFRangeMake(0, numberOfLines), lineOrigins);

    for (CFIndex lineIndex = 0; lineIndex < numberOfLines - 1; lineIndex++) {
        
        CGPoint lineOrigin = lineOrigins[lineIndex];
        lineOrigin.y = lineOrigin.y - (rect.size.height - self.frame.size.height); //整体往上移动，相对于CoreText坐标系
        lineOrigin.y -= _data.edgInsets.top;
     
        CGContextSetTextPosition(context, lineOrigin.x+_data.edgInsets.left, lineOrigin.y);//设定每行开始位置
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        CTLineDraw(line, context);
    }
    
    //最后一行
    CGPoint lineOrigin = lineOrigins[numberOfLines-1];
    lineOrigin.y = lineOrigin.y - (rect.size.height - self.frame.size.height); 
    lineOrigin.y -= _data.edgInsets.top;
    CGContextSetTextPosition(context, lineOrigin.x+_data.edgInsets.left, lineOrigin.y);//设定每行开始位置
    CTLineRef line = CFArrayGetValueAtIndex(lines, numberOfLines-1);
    
    CFRange lastLineRange = CTLineGetStringRange(line);
     NSAttributedString  * attributedString = _data.attributedString;
    
    static NSString* const kEllipsesCharacter = @"\u2026";
    NSAttributedString *tokenString = [[NSAttributedString alloc] initWithString:kEllipsesCharacter
                                                                      attributes:_data.textAttributeDict];
    CTLineRef ellipsisLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)tokenString);
   
    if(self.data.emojiArray.count > 0){
        
        double lineWidth =  CTLineGetTypographicBounds(line, nil, nil, nil);
        double  spaceWidth = CTLineGetTrailingWhitespaceWidth(line);
        double ellipsisWidth =  CTLineGetTypographicBounds(ellipsisLine, nil, nil, nil);
        
        float endTruncateLocation = lineWidth -spaceWidth - 1;
        
       
        
        CTLineRef newline = CTLineCreateTruncatedLine(line, endTruncateLocation, kCTLineTruncationEnd, ellipsisLine);
        if(newline){
            CTLineDraw(newline, context);
            CFRelease(newline);
        }else{
            CTLineDraw(ellipsisLine, context);
            CFRelease(ellipsisLine);
        }
        
        CGFloat ascent;
        CGFloat dscent;
        CGFloat leading;
        CTLineGetTypographicBounds(line, &ascent, &dscent, &leading);
        float height = ascent  + leading;
        _lastLineRightX = endTruncateLocation - ellipsisWidth + _data.edgInsets.left; //装维UI坐标系
        _lastLineOriginY = _data.height-lineOrigin.y-height;  //转为UI坐标系
        
        
    }else{
        
        NSMutableAttributedString *truncationString = [[attributedString attributedSubstringFromRange:NSMakeRange(lastLineRange.location, lastLineRange.length)] mutableCopy];
        
        if (lastLineRange.length > 0) {
            // Remove any whitespace at the end of the line.
            unichar lastCharacter = [[truncationString string] characterAtIndex:lastLineRange.length - 1];
            if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:lastCharacter]) {
                [truncationString deleteCharactersInRange:NSMakeRange(lastLineRange.length - 1, 1)];
            }
        }
        [truncationString appendAttributedString:tokenString];
        
        CTLineRef truncationLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncationString);
        CTLineRef truncatedLine = CTLineCreateTruncatedLine(truncationLine, self.frame.size.width, kCTLineTruncationEnd, ellipsisLine);
        if (!truncatedLine) {
            // If the line is not as wide as the truncationToken, truncatedLine is NULL
            truncatedLine = CFRetain(ellipsisLine);
        }
        CFRelease(truncationLine);
        CFRelease(ellipsisLine);
        CTLineDraw(truncatedLine, context);
        CFRelease(truncatedLine);
    }
    
}

#pragma mark - touch events

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self removeBgColorForLink];
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    for (FWDrawLinkInfo *url in self.data.linkArray) {
        
        for (NSValue *value in url.drawRectArray) {
            
            CGRect urlRect = value.CGRectValue;
            urlRect.origin.y = self.bounds.size.height - urlRect.origin.y - urlRect.size.height;
            if(CGRectContainsPoint(urlRect, point)){
                
                [self addBgColorForLink:url];
                return;
            }
        }
    }
    
    if(self.allowTapGesture){
        _originBackGoroundColor = self.backgroundColor;
        _touchEnterByTap = YES;
        self.backgroundColor = _tapColor;
    }
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    if(_activeLinkInfo.isSelected){
        
        BOOL found = NO;
        for (NSValue *value in _activeLinkInfo.drawRectArray) {
            
            CGRect urlRect = value.CGRectValue;
            urlRect.origin.y = self.bounds.size.height - urlRect.origin.y - urlRect.size.height;
            if(CGRectContainsPoint(urlRect, point)){
                found = YES;
                break;
            }
        }

        if(!found){
            [self removeBgColorForLink];
        }
        return;
    }
    
    if(self.allowTapGesture && _touchEnterByTap){
        
        if(!CGRectContainsPoint(self.bounds, point) ){
            [self removeTapColor];
        }
    }
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
    if(_activeLinkInfo.isSelected){
        
    
        //点击链接事件
        if(self.delegate && [self.delegate respondsToSelector:@selector(didClickFWDraw:byLink:)])
        {
            [self.delegate didClickFWDraw:self byLink:_activeLinkInfo];
        }
        [self performSelector:@selector(removeBgColorForLink) withObject:nil afterDelay:0.3f];
        return;
    }
    
    if(self.allowTapGesture && _touchEnterByTap){
        
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        
 
        
        if(CGRectContainsPoint(self.bounds, point)){
          
            if(self.delegate && [self.delegate respondsToSelector:@selector(didClickFWDraw:)])
            {
                [self.delegate didClickFWDraw:self];
            }
            [self performSelector:@selector(removeTapColor) withObject:nil afterDelay:0.25f];
        }else{
            [self removeTapColor];
        }
    }
}

-(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if(_activeLinkInfo){
        [self removeBgColorForLink];
    }
}

-(void)removeBgColorForLink
{
    _activeLinkInfo.isSelected = NO;
    [self setNeedsDisplay];
  
}

-(void)addBgColorForLink:(FWDrawLinkInfo*)url
{
    _activeLinkInfo = url;
    _activeLinkInfo.isSelected = YES;
    [self setNeedsDisplay];
}

-(void)removeTapColor
{
    _touchEnterByTap = NO;
    self.backgroundColor = _originBackGoroundColor;
}


#pragma mark - longPress

-(void)addLongPressGesture
{
    if(!_longPressGesture){
        _longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressMethod:)];
    }
    [self addGestureRecognizer:_longPressGesture];
}

-(void)removeLongPressGesture
{
    if(_longPressGesture){
        [self removeGestureRecognizer:_longPressGesture];
    }
}

-(void)longPressMethod:(UILongPressGestureRecognizer*)longPress
{
    if(longPress.state ==UIGestureRecognizerStateBegan){
        //长按事件
        self.backgroundColor = _longPressColor;
        if(self.delegate && [self.delegate respondsToSelector:@selector(didLongPressFWDraw:)]){
            [self.delegate didLongPressFWDraw:self];
        }
        _isLongPressStatus = YES;
    }
    
    if(longPress.state ==UIGestureRecognizerStateEnded){
        
        _isLongPressStatus = NO;
    }
    
    if(longPress.state == UIGestureRecognizerStateCancelled){
        
        _isLongPressStatus = NO;
    }
}



@end









































