//
//  FWDrawInfo.m
//  DrawText
//
//  Created by silver on 16/8/31.
//  Copyright © 2016年 Fsilver. All rights reserved.
//

#import "FWDrawInfo.h"

@implementation FWDrawEmojiInfo

@end

@implementation FWDrawLinkInfo

@end

@implementation FWDrawInfo

-(void)setCtFrame:(CTFrameRef)ctFrame
{
    if(_ctFrame != ctFrame){
        
        if(_ctFrame != nil){
            CFRelease(_ctFrame);
        }
        CFRetain(ctFrame);
        _ctFrame = ctFrame;
    }
}


#pragma mark - 计算每一个表情的位置

-(void)setEmojiArray:(NSArray *)emojiArray
{
    _emojiArray = emojiArray;
    [self fillEmojiPosition];
}


/***
 text中 遍历lines
 line中 遍历Run,
 Run中找到占位符，
 依次吧占位符的bounds 赋值 给emojiArray中的每一个emoji
 ***/
-(void)fillEmojiPosition
{
    if(self.emojiArray.count ==0){
        return;
    }
    
    NSArray *lines = (NSArray*)CTFrameGetLines(self.ctFrame);
    NSInteger lineCount = lines.count;
    CGPoint lineOrigins[lineCount];
    
    CTFrameGetLineOrigins(self.ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    int imageIndex = 0;
    FWDrawEmojiInfo *emoji = self.emojiArray[0];
    
    for (int i=0; i<lineCount; i++) {
        
        if(emoji == nil){
            break;
        }
        
        CTLineRef line = (__bridge CTLineRef)lines[i];
        NSArray *runObject = (NSArray*)CTLineGetGlyphRuns(line);
        
        for (id runObj in runObject) {
            
            CTRunRef run = (__bridge CTRunRef)runObj;
            NSDictionary *runAttributes = (NSDictionary *)CTRunGetAttributes(run);
            CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[runAttributes valueForKey:(id)kCTRunDelegateAttributeName];
            if (delegate == nil) {
                continue;
            }
            
            NSDictionary * metaDic = CTRunDelegateGetRefCon(delegate);
            if (![metaDic isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            
            CGRect runBounds;
            CGFloat ascent;
            CGFloat descent;
            runBounds.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
            runBounds.size.height = ascent + descent;
            
            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
            runBounds.origin.x = lineOrigins[i].x + xOffset;
            runBounds.origin.y = lineOrigins[i].y;
            runBounds.origin.y -= descent;
            
            
            CGPathRef pathRef = CTFrameGetPath(self.ctFrame);
            CGRect colRect = CGPathGetBoundingBox(pathRef);
            
            CGRect delegateBounds = CGRectOffset(runBounds, colRect.origin.x, colRect.origin.y);
            delegateBounds.origin.y += emoji.descender;
            
            
            CGRect rect = delegateBounds;
            //第一次转为UI坐标系
            rect.origin.y = _originHeight - rect.origin.y - rect.size.height;
            
            //第二次转为CoreText坐标系
            rect.origin.y = _height - rect.origin.y - rect.size.height;
            emoji.drawRect = rect;
            
            emoji.drawRect = rect;
            
            imageIndex++;
            if (imageIndex == self.emojiArray.count) {
                emoji = nil;
                break;
            } else {
                emoji = self.emojiArray[imageIndex];
            }
        }
    }
}

#pragma mark - 计算每个链接的位置

-(void)setLinkArray:(NSArray *)linkArray
{
    _linkArray = linkArray;
    [self fillLinkPosition];
}

-(void)fillLinkPosition
{
    if(self.linkArray.count == 0){
        return;
    }
    
    NSArray *handleArray = self.linkArray;
    
    NSArray *lines = (NSArray*)CTFrameGetLines(self.ctFrame);
    NSInteger lineCount = lines.count;
    CGPoint lineOrigins[lineCount];
    
    CTFrameGetLineOrigins(self.ctFrame, CFRangeMake(0, 0), lineOrigins);
    
    int urlIndex = 0;
    
    FWDrawLinkInfo *urlInfo = handleArray[0];
    BOOL isWrapInSameUrl = NO;//是否为同一个Url的折行Run
    BOOL isTheFirstUrlRun = YES;
    NSString *lastKey;
    
    for (int i=0; i<lineCount; i++) {
        
        if(urlInfo == nil){
            break;
        }
        
        CTLineRef line = (__bridge CTLineRef)lines[i];
        NSArray *runObject = (NSArray*)CTLineGetGlyphRuns(line);
        
        for (id runObj in runObject) {
            
            CTRunRef run = (__bridge CTRunRef)runObj;
            
            NSDictionary *runAttributes = (NSDictionary *)CTRunGetAttributes(run);
            
            NSString *urlKey = [runAttributes objectForKey:NSAttributeLinkKey];
            
            if(urlKey && [urlKey isEqualToString:lastKey]){
                isWrapInSameUrl = YES;
            }else{
                isWrapInSameUrl = NO;
            }
            lastKey = urlKey;
            
            //if(!urlKey || ![urlKey isEqualToString:NSAttributeLinkKey]){
            if(!urlKey ){
                //普通的Run 不获取,只获取urlKey
                continue;
            }
            
            if(isWrapInSameUrl){
                
                //折行的，不取下一个urlInfo;
            }else{
                
                //新的链接
                if(isTheFirstUrlRun){
                    //第一次：已经是0
                    isTheFirstUrlRun = NO;
                }else{
                    //2和2次以上：取下一个
                    urlIndex++;
                }
            }
            
            if (urlIndex == handleArray.count)
            {
                urlInfo = nil;
                break;
            }
            urlInfo = handleArray[urlIndex];
            
            CGRect runBounds;
            CGFloat ascent;
            CGFloat descent;
            runBounds.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
            runBounds.size.height = ascent + descent;
            
            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
            runBounds.origin.x = lineOrigins[i].x + xOffset;
            runBounds.origin.y = lineOrigins[i].y;
            runBounds.origin.y -= descent;
            
            
            CGPathRef pathRef = CTFrameGetPath(self.ctFrame);
            CGRect colRect = CGPathGetBoundingBox(pathRef);
            
            CGRect delegateBounds = CGRectOffset(runBounds, colRect.origin.x, colRect.origin.y);
            
            
            CGRect rect = delegateBounds;
            
            //第一次转为UI坐标系
            rect.origin.y = _originHeight - rect.origin.y - rect.size.height;
            
            //第二次转为CoreText坐标系
            rect.origin.y = _height - rect.origin.y - rect.size.height;
            delegateBounds = rect;
            
            
            NSValue *rectNumber = [NSValue valueWithCGRect:delegateBounds];
            
            NSMutableArray *temp;
            if(urlInfo.drawRectArray){
                temp = [NSMutableArray arrayWithArray:urlInfo.drawRectArray];
            }else{
                temp = [NSMutableArray array];
            }
            [temp addObject:rectNumber];
            urlInfo.drawRectArray = temp;

        }
    }

}


@end













































