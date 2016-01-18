//
//  XBPageDragView.h
//  XBPageCurl
//
//  Created by xiss burg on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XBPageCurlView.h"
//翻页动画类型
typedef enum : NSUInteger {
    BookPageFlipAnimationTypeFade = 0, //渐变
    BookPageFlipAnimationTypeMove, //平移
    BookPageFlipAnimationTypeSimulation,//仿真
    BookPageFlipAnimationTypeOther //其他
} BookPageFlipAnimationType;

typedef enum : NSUInteger {
    BookPageFlipTypeToNextPage = 0, //下一页
    BookPageFlipTypeToPrePage,      //上一页
    BookPageFlipTypeToNextChapter,  //下一章
    BookPageFlipTypeToPreChapter    //上一章
    
} BookPageFlipType;


@protocol XBPageDragViewDataSource;
@protocol XBPageDragViewDelegate;

@interface XBPageDragView : UIView

@property (nonatomic, strong) UIView *viewToCurl;
@property (nonatomic, readonly) BOOL pageIsCurled;
@property (nonatomic, strong) XBPageCurlView *pageCurlView;
@property (nonatomic, readonly) XBSnappingPoint *cornerSnappingPoint;
@property (nonatomic, assign) id<XBPageDragViewDelegate> delegate;
@property (nonatomic, assign) id<XBPageDragViewDataSource> dataSource;

- (void)uncurlPageAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void)refreshPageCurlView;
-(void)initViewToCurl;

@end


@protocol XBPageDragViewDelegate <NSObject>

//- (void)XBPageDragView:(XBPageDragView *)view touchBeganAtPoint:(CGPoint)p;
//- (void)XBPageDragView:(XBPageDragView *)view touchMovedToPoint:(CGPoint)p;
//- (void)XBPageDragView:(XBPageDragView *)view touchEndedAtPoint:(CGPoint)p;

- (BOOL)XBPageDragViewTurnToPrePage:(XBPageDragView *)view;
- (BOOL)XBPageDragViewTurnToNextPage:(XBPageDragView *)view;
- (BOOL)XBPageDragViewTurnToPreChapter:(XBPageDragView *)view completion:(void (^)(void))completion;
- (BOOL)XBPageDragViewTurnToNextChapter:(XBPageDragView *)view completion:(void (^)(void))completion;
- (void)XBPageDragViewClickCenter:(XBPageDragView *)view;
- (void)XBPageDragViewCurlDidEnd:(XBPageDragView *)view curlSuccess:(BOOL)success pageFlipType:(BookPageFlipType)flipType;

@end

@protocol XBPageDragViewDataSource <NSObject>

- (BOOL)XBPageDragViewHasPrePage:(XBPageDragView *)view;
- (BOOL)XBPageDragViewHasNextPage:(XBPageDragView *)view;
- (BOOL)XBPageDragViewHasPreChapter:(XBPageDragView *)view;
- (BOOL)XBPageDragViewHasNextChapter:(XBPageDragView *)view;
- (UIView *)XBPageDragViewTargetView:(XBPageDragView *)view willTurnToNext:(BOOL)next;
- (BookPageFlipAnimationType)XBPageDragViewPageFlipAnimationType:(XBPageDragView *)view;

@end