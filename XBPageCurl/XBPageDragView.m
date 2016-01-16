//
//  XBPageDragView.m
//  XBPageCurl
//
//  Created by xiss burg on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBPageDragView.h"
#import "CGPointAdditions.h"
#import "TYBookPageTransformAnimation.h"
#import <RACEXTScope.h>
#import <ReactiveCocoa/RACCommand.h>
#import <ReactiveCocoa/RACSignal.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/NSObject+RACPropertySubscribing.h>
#import "TYMoveTransformAnimation.h"
#import "TYPoints.h"

#define WIDTH_1_3                       (self.frame.size.width / 3.0)
#define HEIGHT                          (1.28 * WIDTH_1_3)
#define TURN_LEFT_PAGE_RECT_1               CGRectMake(0, 0, WIDTH_1_3, CGRectGetHeight(self.frame))
#define TURN_TOP_PAGE_RECT_1               CGRectMake(WIDTH_1_3, 0, WIDTH_1_3, HEIGHT)

//#define TURN_LEFT_PAGE_RECT_2               CGRectMake(SCREEN_WIDTH / 3.0, 0, SCREEN_WIDTH- 2 * SCREEN_WIDTH / 3.0, SCREEN_WIDTH / 3.0)
#define POP_DETAIL_RECT                     CGRectMake(WIDTH_1_3, HEIGHT, WIDTH_1_3, CGRectGetHeight(self.frame) - 2 * HEIGHT)
#define TURN_RIGHT_PAGE_RECT_1              CGRectMake(self.frame.size.width - WIDTH_1_3, 0, WIDTH_1_3, CGRectGetHeight(self.frame))
#define TURN_BOTTOM_PAGE_RECT_1             CGRectMake(WIDTH_1_3, CGRectGetHeight(self.frame) - HEIGHT, WIDTH_1_3, HEIGHT)

#define kRaduis 180
#define kDuration 0.6
#define kMoveDuration 0.5
#define kLeftX (-self.frame.size.width)

@interface XBPageDragView ()

@property (nonatomic, assign) BOOL pageIsCurled;
@property (nonatomic, assign) BOOL pageWillDrag;
@property (nonatomic, assign) BOOL pageWillCurl;
@property (nonatomic, assign) BOOL curlViewDidLoad;
@property (nonatomic, assign) BOOL curlViewDidEnd;
@property (nonatomic, assign) BOOL curlViewDidMoved;

@property (nonatomic, assign) BookPageFlipType pageFlipType;
@property (nonatomic, strong) TYMoveTransformAnimation *moveAnimation;
@property (nonatomic, strong) UIView *curlingView;
@property (nonatomic, strong) TYPoints *points;

@end

@implementation XBPageDragView

@synthesize cornerSnappingPoint = _cornerSnappingPoint;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addObserverForTouch];
        self.points = [[TYPoints alloc]init];
        self.pageCurlView = [[XBPageCurlView alloc] initWithFrame:self.bounds];
    }
    return self;
}

-(TYMoveTransformAnimation *)moveAnimation
{
    if (_moveAnimation == nil) {
        _moveAnimation = [[TYMoveTransformAnimation alloc]init];
    }
    return _moveAnimation;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.pageCurlView stopAnimating];
    
}

#pragma mark - Properties

- (void)setViewToCurl:(UIView *)viewToCurl
{
    if (viewToCurl == _viewToCurl) {
        return;
    }
    
    _viewToCurl = viewToCurl;
    
    [self.pageCurlView removeFromSuperview];
    //self.pageCurlView = nil;
    
    if (_viewToCurl == nil) {
        return;
    }
    
    [self refreshPageCurlView];
}

- (XBSnappingPoint *)cornerSnappingPoint
{
    if (_cornerSnappingPoint == nil) {
        _cornerSnappingPoint = [[XBSnappingPoint alloc] initWithPosition:CGPointMake(self.frame.size.width, self.frame.size.height/2.0) failPosition:CGPointZero angle:M_PI_2 radius:30];
    }
    return _cornerSnappingPoint;
}

#pragma mark - Methods

- (void)uncurlPageAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    NSTimeInterval duration = animated? 0.3: 0;
    __weak XBPageDragView *weakSelf = self;
    [self.pageCurlView setCylinderPosition:self.cornerSnappingPoint.position cylinderAngle:self.cornerSnappingPoint.angle cylinderRadius:self.cornerSnappingPoint.radius animatedWithDuration:duration completion:^{
        weakSelf.hidden = NO;
        weakSelf.pageIsCurled= NO;
        weakSelf.viewToCurl.hidden = NO;
        [weakSelf.pageCurlView removeFromSuperview];
        [weakSelf.pageCurlView stopAnimating];
        if (completion) {
            completion();
        }
    }];
}

-(XBPageCurlView *)pageCurlView
{
    if (_pageCurlView == nil) {
        _pageCurlView = [[XBPageCurlView alloc] initWithFrame:self.bounds];
    }
    return _pageCurlView;
}
- (void)refreshPageCurlView
{
    XBPageCurlView *pageCurlView = self.pageCurlView;//[[XBPageCurlView alloc] initWithFrame:self.viewToCurl.frame];
    pageCurlView.pageOpaque = YES;
    pageCurlView.opaque = NO;
    pageCurlView.snappingEnabled = YES;
    [pageCurlView drawViewOnFrontOfPage:self.viewToCurl];
    
//    if (self.pageCurlView != nil) {
//        pageCurlView.maximumCylinderAngle = self.pageCurlView.maximumCylinderAngle;
//        pageCurlView.minimumCylinderAngle = self.pageCurlView.minimumCylinderAngle;
//        [pageCurlView addSnappingPointsFromArray:self.pageCurlView.snappingPoints];
//        
//        if (![self.pageCurlView.snappingPoints containsObject:self.cornerSnappingPoint]) {
//            [pageCurlView addSnappingPoint:self.cornerSnappingPoint];
//        }
//        [self.pageCurlView removeFromSuperview];
//    }

    [[NSNotificationCenter defaultCenter] removeObserver:self name:XBPageCurlViewDidSnapToPointNotification object:pageCurlView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pageCurlViewDidSnapToPointNotification:) name:XBPageCurlViewDidSnapToPointNotification object:pageCurlView];
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
 
    [self.points clearAllPoints];

    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    if (CGRectContainsPoint(self.frame, touchLocation)) {

        [self endPreCurl];//结束上一次动画
        [self.points addPoint:touchLocation];
        //NSLog(@"touchesBegan:%@,self.pageIsCurled:%i",NSStringFromCGPoint([self.points beginPoint]) ,self.pageIsCurled);
        //self.hidden = YES;
        self.pageWillCurl = NO;
        self.curlViewDidLoad = NO;
        self.curlViewDidEnd = NO;
        self.curlViewDidMoved = NO;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    if (self.pageIsCurled)
    {
        return;
    }
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    //NSLog(@"touchesMoved:%@",NSStringFromCGPoint(touchLocation));
    [self.points addPoint:touchLocation];
     CGFloat moveX = [self.points movedX];

    switch ([self.dataSource XBPageDragViewPageFlipAnimationType:self]) {
        case BookPageFlipAnimationTypeFade:
        {
            
        }
            break;
        case BookPageFlipAnimationTypeMove:
        {
            if (!_pageWillCurl) {
                _pageWillCurl = YES;
                if (moveX < 0) {
                    self.curlViewDidMoved = YES;
                     if ([self.dataSource XBPageDragViewHasNextPage:self]) {
                        [self.delegate XBPageDragViewTurnToNextPage:self];
                        self.pageFlipType = BookPageFlipTypeToNextPage;
                        UIView *targetView =  [self.dataSource XBPageDragViewTargetView:self willTurnToNext:YES];
                        [self addShadowForView:targetView];
                        [self.moveAnimation moveTargetView:targetView moveLength:moveX duration:kMoveDuration animated:NO];
                        self.curlViewDidLoad = YES;
                        
                    } else if ([self.dataSource XBPageDragViewHasNextChapter:self]) {
                        [self.delegate XBPageDragViewTurnToNextChapter:self completion:^{
                            self.pageFlipType = BookPageFlipTypeToNextChapter;
                            UIView *targetView =  [self.dataSource XBPageDragViewTargetView:self willTurnToNext:YES];
                            [self addShadowForView:targetView];
                            [self.moveAnimation moveTargetView:targetView moveLength:moveX duration:kMoveDuration animated:NO];
                            
                            self.curlViewDidLoad = YES;
                        }];
                        
                    }
                } else if(moveX > 0) {
                    self.curlViewDidMoved = YES;
                     if ([self.dataSource XBPageDragViewHasPrePage:self]) {
                        [self.delegate XBPageDragViewTurnToPrePage:self];
                        self.pageFlipType = BookPageFlipTypeToPrePage;
                        UIView *targetView =  [self.dataSource XBPageDragViewTargetView:self willTurnToNext:NO];
                        [self addShadowForView:targetView];
                        [self.moveAnimation moveTargetView:targetView moveLength: touchLocation.x - targetView.frame.size.width duration:kMoveDuration animated:NO];
                        
                        self.curlViewDidLoad = YES;
                    } else if ([self.dataSource XBPageDragViewHasPreChapter:self]) {
                        [self.delegate XBPageDragViewTurnToPreChapter:self completion:^{
                            self.pageFlipType = BookPageFlipTypeToPreChapter;
                            UIView *targetView =  [self.dataSource XBPageDragViewTargetView:self willTurnToNext:NO];
                            [self addShadowForView:targetView];
                            [self.moveAnimation moveTargetView:targetView moveLength:touchLocation.x - targetView.frame.size.width duration:kMoveDuration animated:NO];
                            
                            self.curlViewDidLoad = YES;
                            
                        }];
                        
                    }
                }
                
            } else {
                 if (_curlViewDidLoad) {
                    if ( self.pageFlipType == BookPageFlipTypeToNextPage || self.pageFlipType == BookPageFlipTypeToNextChapter) {
                        [self.moveAnimation moveTargetViewWithMoveLength:moveX<0?moveX:0 duration:kMoveDuration animated:NO];
                    } else if(self.pageFlipType == BookPageFlipTypeToPrePage || self.pageFlipType == BookPageFlipTypeToPreChapter){
                        [self.moveAnimation moveTargetViewWithMoveLength:(touchLocation.x - self.frame.size.width)>(-self.frame.size.width-10)?(touchLocation.x - self.frame.size.width):(-self.frame.size.width-10) duration:kMoveDuration animated:NO];
                    }
                }
                
                
            }
        }
            break;
        case BookPageFlipAnimationTypeSimulation:
        {
            if (!_pageWillCurl) {
                _pageWillCurl = YES;
                if (moveX < 0) {
                    self.curlViewDidMoved = YES;
                     if ([self.dataSource XBPageDragViewHasNextPage:self]) {
                        [self.delegate XBPageDragViewTurnToNextPage:self];
                        self.pageFlipType = BookPageFlipTypeToNextPage;
                        UIView *targetView =  [self.dataSource XBPageDragViewTargetView:self willTurnToNext:YES];
                        self.cornerSnappingPoint.position = CGPointMake(self.frame.size.width, self.frame.size.height / 2.0) ;
                        [self curlView:targetView maxAngle:[self maxAngele:touchLocation baseAngle:M_PI_2] minAngle:[self minAngele:touchLocation baseAngle:M_PI_2] touchLocation:touchLocation targetPosition:CGPointMake(kLeftX, self.frame.size.height*0.5) cancelPostion:CGPointMake(self.frame.size.width, self.frame.size.height*0.5)];
                        self.curlViewDidLoad = YES;
                        self.viewToCurl.hidden = YES;
                        
                    } else if ([self.dataSource XBPageDragViewHasNextChapter:self]) {
                         [self.delegate XBPageDragViewTurnToNextChapter:self completion:^{
                            self.pageFlipType = BookPageFlipTypeToNextChapter;

                            UIView *targetView =  [self.dataSource XBPageDragViewTargetView:self willTurnToNext:YES];
                            self.cornerSnappingPoint.position = CGPointMake(self.frame.size.width, self.frame.size.height / 2.0) ;
                            [self curlView:targetView maxAngle:[self maxAngele:touchLocation baseAngle:M_PI_2] minAngle:[self minAngele:touchLocation baseAngle:M_PI_2] touchLocation:touchLocation targetPosition:CGPointMake(kLeftX, self.frame.size.height*0.5) cancelPostion:CGPointMake(self.frame.size.width, self.frame.size.height*0.5)];
                            self.curlViewDidLoad = YES;
                            self.viewToCurl.hidden = YES;
                        }];
                        
                    }
                } else if(moveX > 0) {
                    self.curlViewDidMoved = YES;
                    if ([self.dataSource XBPageDragViewHasPrePage:self]) {
                        [self.delegate XBPageDragViewTurnToPrePage:self];
                        self.pageFlipType = BookPageFlipTypeToPrePage;

                        UIView *targetView =  [self.dataSource XBPageDragViewTargetView:self willTurnToNext:NO];
                        self.cornerSnappingPoint.position = touchLocation;
                        [self curlView:targetView maxAngle:M_PI_2 minAngle:M_PI_2 touchLocation:touchLocation targetPosition:CGPointMake(self.frame.size.width, self.frame.size.height*0.5) cancelPostion:CGPointMake(kLeftX, self.frame.size.height*0.5)];
                        
                        self.curlViewDidLoad = YES;
                        self.viewToCurl.hidden = YES;
                        
                    } else if ([self.dataSource XBPageDragViewHasPreChapter:self]) {
                        
                        self.cornerSnappingPoint.position = touchLocation;
                        [self.delegate XBPageDragViewTurnToPreChapter:self completion:^{
                            self.pageFlipType = BookPageFlipTypeToPreChapter;

                            UIView *targetView =  [self.dataSource XBPageDragViewTargetView:self willTurnToNext:NO];
                            [self curlView:targetView maxAngle:M_PI_2 minAngle:M_PI_2 touchLocation:touchLocation targetPosition:CGPointMake(self.frame.size.width, self.frame.size.height*0.5) cancelPostion:CGPointMake(kLeftX, self.frame.size.height*0.5)];
                            self.curlViewDidLoad = YES;
                            self.viewToCurl.hidden = YES;
                        }];
                        
                    }
                }
                
            } else {
                 if (_curlViewDidLoad) {
                   // self.pageCurlView.maximumCylinderAngle = [self maxAngele:touchLocation baseAngle:M_PI_2];
                   // self.pageCurlView.minimumCylinderAngle = [self minAngele:touchLocation baseAngle:M_PI_2];
                    [self.pageCurlView touchMovedToPoint:touchLocation];
                }
                
            }
        }
            break;
        default:
            break;
    }
    
    
    
    
    
}



- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"touchesEnded:self.pageIsCurled:%i", self.pageIsCurled);
    if (self.pageIsCurled) {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    [self.points addPoint:touchLocation];
    
    CGFloat moveX = [self.points movedX];
    CGFloat moveY = [self.points movedY];
    NSLog(@"self.points:%@,touches.count:%li",self.points.points,[touches count]);
    switch ([self.dataSource XBPageDragViewPageFlipAnimationType:self]) {
        case BookPageFlipAnimationTypeFade:
        {
            
                if (moveX < -10 && fabs(moveX) >= fabs(moveY)) {
                    
                    [self turnToNextPageAnimatedWithType:kCATransitionFade];
                    
                } else if(moveX > 10 && fabs(moveX)>= fabs(moveY)) {
                    
                    [self turnToPrePageAnimatedWithType:kCATransitionFade];
                } else if([self touchPointInLeftArea:touchLocation]){
                    
                    [self turnToPrePageAnimatedWithType:kCATransitionFade];
                    
                }else if([self touchPointInRightArea:touchLocation]){
                    
                    [self turnToNextPageAnimatedWithType:kCATransitionFade];
                    
                }else if([self touchPointInCenterArea:touchLocation]){
                    
                    [self.delegate XBPageDragViewClickCenter:self];
                    [self endFlip];
                } else {
                    [self endFlip];
                }
            
        }
            break;
        case BookPageFlipAnimationTypeMove:
        {
            if (self.curlViewDidMoved) {
                 self.curlViewDidEnd = YES;

            } else {
                [self singleTouchWithMove:touchLocation];
            }
        }
            break;
        case BookPageFlipAnimationTypeSimulation:
        {
            if (self.curlViewDidMoved) {
                 self.curlViewDidEnd = YES;
                
            } else {
                [self singleTouchWithSimulation:touchLocation];
            }
            
        }
            break;
        case BookPageFlipAnimationTypeOther:
        {
            [self endFlip];
        }
            break;
        default:
            [self endFlip];
            break;
    }
    
    
    
    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

-(void)cureViewToEndLocation:(CGPoint)touchLocation
{

    if ([self.points isMoved]) {
        if (self.pageCurlView.snappingEnabled && self.pageCurlView.snappingPointArray.count > 0) {
            self.pageIsCurled = YES;
        }
        BOOL isNext =  self.pageFlipType == BookPageFlipTypeToNextPage || self.pageFlipType == BookPageFlipTypeToNextChapter;
        BOOL suc = YES;
        if (isNext) {
            if ([self.points willMoveToRight]) {
                suc = NO;
            }
        } else {
            if ([self.points willMoveToLeft]) {
                suc = NO;
            }
            
        }
        [self.pageCurlView touchEndedAtPoint:touchLocation andCurlSuccess:suc && CGPointToPointDistance(self.points.beginPoint, touchLocation) > 15];
    } else {
        [self pageCurlViewDidSnapToPoint:NO];
        [self singleTouchWithSimulation:touchLocation];
//        if([self touchPointInLeftArea:touchLocation]){
////            CGPoint targetPosition = CGPointMake(self.frame.size.width, self.frame.size.height*0.5);
////            CGPoint cancelPostion = CGPointMake(kLeftX, self.frame.size.height*0.5);
//// 
////            XBSnappingPoint *point = [[XBSnappingPoint alloc] initWithPosition:targetPosition failPosition:cancelPostion angle:M_PI_2 radius:kRaduis weight:1];
////            
////            [self.pageCurlView removeAllSnappingPoints];
////            [self.pageCurlView addSnappingPoint:point];
////            
////            [self.pageCurlView touchEndedAtPoint:touchLocation andCurlSuccess:YES];
//            [self pageCurlViewDidSnapToPoint:NO];
//            
//        } else if([self touchPointInRightArea:touchLocation]){
////            CGPoint targetPosition = CGPointMake(kLeftX, self.frame.size.height*0.5);
////            CGPoint cancelPostion = CGPointMake(self.frame.size.width, self.frame.size.height*0.5);
////            
////            XBSnappingPoint *point = [[XBSnappingPoint alloc] initWithPosition:targetPosition failPosition:cancelPostion angle:M_PI_2 radius:kRaduis weight:1];
////            
////            [self.pageCurlView removeAllSnappingPoints];
////            [self.pageCurlView addSnappingPoint:point];
//         //   [self.pageCurlView touchEndedAtPoint:touchLocation andCurlSuccess:YES];
//            [self pageCurlViewDidSnapToPoint:NO];
//            
//        } else if([self touchPointInCenterArea:touchLocation]){
//            [self pageCurlViewDidSnapToPoint:NO];
//           // [self.pageCurlView touchEndedAtPoint:touchLocation andCurlSuccess:NO];
//            [self.delegate XBPageDragViewClickCenter:self];
//            [self endFlip];
//        } else {
//         //   [self.pageCurlView touchEndedAtPoint:touchLocation andCurlSuccess:NO];
//            [self endFlip];
//        }
    }
    
 
}

-(void)singleTouchWithMove:(CGPoint)touchLocation
{
    if([self touchPointInLeftArea:touchLocation]){
        
        [self turnToPrePageAnimatedWithMove];
        
    }else if([self touchPointInRightArea:touchLocation]){
        
        [self turnToNextPageAnimatedWithMove];
        
    }else if([self touchPointInCenterArea:touchLocation]){
        
        [self.delegate XBPageDragViewClickCenter:self];
        [self endFlip];
    } else {
        [self endFlip];
    }
}

-(void)singleTouchWithSimulation:(CGPoint)touchLocation
{
    if([self touchPointInLeftArea:touchLocation]){
        if ([self.dataSource XBPageDragViewHasPrePage:self]) {
            self.pageIsCurled = YES;
            
            
            [self.delegate XBPageDragViewTurnToPrePage:self];
            self.pageFlipType = BookPageFlipTypeToPrePage;
            
            [self curlAction:NO tapPoint:touchLocation];
        } else if ([self.dataSource XBPageDragViewHasPreChapter:self]) {
            self.pageIsCurled = YES;
            
            BOOL suc =  [self.delegate XBPageDragViewTurnToPreChapter:self completion:^{
                self.pageFlipType = BookPageFlipTypeToPreChapter;
                [self curlAction:NO tapPoint:touchLocation];
            }];
            if (!suc) {
                [self endFlip];
            }
            
        } else  {
            [self endFlip];
        }
        
    } else if([self touchPointInRightArea:touchLocation]){
        
        if ([self.dataSource XBPageDragViewHasNextPage:self]) {
            self.pageIsCurled = YES;
            // NSLog(@"pageIsCurled2:%i",self.pageIsCurled);
            [self.delegate XBPageDragViewTurnToNextPage:self];
            self.pageFlipType = BookPageFlipTypeToNextPage;
            
            [self curlAction:YES tapPoint:touchLocation];
        } else if ([self.dataSource XBPageDragViewHasNextChapter:self]) {
            self.pageIsCurled = YES;
            // NSLog(@"pageIsCurled3:%i",self.pageIsCurled);
            BOOL suc = [self.delegate XBPageDragViewTurnToNextChapter:self completion:^{
                self.pageFlipType = BookPageFlipTypeToNextChapter;
                
                [self curlAction:YES tapPoint:touchLocation];
            }];
            if (!suc) {
                [self endFlip];
            }
        } else {
            [self endFlip];
        }
        
    }else if([self touchPointInCenterArea:touchLocation]){
        
        [self.delegate XBPageDragViewClickCenter:self];
        [self endFlip];
    } else {
        [self endFlip];
    }

}

-(void)moveViewToEndX:(CGFloat)moveX
{
    if ([self.points isMoved]) {
        if ( ![self.points willMoveToRight] && moveX < -10 && (self.pageFlipType == BookPageFlipTypeToNextPage || self.pageFlipType == BookPageFlipTypeToNextChapter)) {
            self.pageIsCurled = YES;
            if (_curlViewDidLoad) {
                [self.moveAnimation moveTargetViewWithMoveLength:-self.frame.size.width-10 duration:kMoveDuration animated:YES completion:^{
                    [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:YES pageFlipType:self.pageFlipType];
                    [self endFlip];
                }];
            }
            
        } else if(![self.points willMoveToLeft] && moveX > 10 && (self.pageFlipType == BookPageFlipTypeToPrePage || self.pageFlipType == BookPageFlipTypeToPreChapter)) {
            self.pageIsCurled = YES;
            if (_curlViewDidLoad) {
                [self.moveAnimation moveTargetViewWithMoveLength:0 duration:kMoveDuration animated:YES completion:^{
                    [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:YES pageFlipType:self.pageFlipType];
                    [self endFlip];
                }];
            }
        } else {
            self.pageIsCurled = YES;
            if (_curlViewDidLoad) {
                [self.moveAnimation moveTargetViewWithMoveLength:(self.pageFlipType == BookPageFlipTypeToNextPage || self.pageFlipType == BookPageFlipTypeToNextChapter)?0:(-self.frame.size.width-10) duration:kMoveDuration animated:YES completion:^{
                    [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:NO  pageFlipType:self.pageFlipType];
                    [self endFlip];
                }];
            }
        }
    } else {
        self.pageIsCurled = YES;
        CGPoint touchLocation = self.points.endPoint;
        if([self touchPointInLeftArea:touchLocation]){
            if (_curlViewDidLoad) {
                [self.moveAnimation moveTargetViewWithMoveLength:0 duration:kMoveDuration animated:YES completion:^{
                    [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:YES pageFlipType:self.pageFlipType];
                    [self endFlip];
                }];
            }
            
        }else if([self touchPointInRightArea:touchLocation]){
            
            if (_curlViewDidLoad) {
                [self.moveAnimation moveTargetViewWithMoveLength:-self.frame.size.width-10 duration:kMoveDuration animated:YES completion:^{
                    [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:YES pageFlipType:self.pageFlipType];
                    [self endFlip];
                }];
            }
            
        }else if([self touchPointInCenterArea:touchLocation]){
            self.pageIsCurled = YES;
            if (_curlViewDidLoad) {
                [self.moveAnimation moveTargetViewWithMoveLength:(self.pageFlipType == BookPageFlipTypeToNextPage || self.pageFlipType == BookPageFlipTypeToNextChapter)?0:(-self.frame.size.width-10) duration:kMoveDuration animated:NO completion:^{
                    [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:NO  pageFlipType:self.pageFlipType];
                    [self.delegate XBPageDragViewClickCenter:self];
                    [self endFlip];
                }];
            }
        } else {
            self.pageIsCurled = YES;
            if (_curlViewDidLoad) {
                [self.moveAnimation moveTargetViewWithMoveLength:(self.pageFlipType == BookPageFlipTypeToNextPage || self.pageFlipType == BookPageFlipTypeToNextChapter)?0:(-self.frame.size.width-10) duration:kMoveDuration animated:NO completion:^{
                    [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:NO  pageFlipType:self.pageFlipType];
                    [self endFlip];
                }];
            }
        }
    }
    

}

#pragma mark - Notifications

- (void)pageCurlViewDidSnapToPointNotification:(NSNotification *)notification
{
    NSNumber *curlSuccess = notification.userInfo[kXBCurlSuccessKey];
    [self pageCurlViewDidSnapToPoint:curlSuccess.boolValue];
}

-(void)pageCurlViewDidSnapToPoint:(BOOL)success
{
    self.hidden = NO;
    [self endFlip];
    self.viewToCurl.hidden = NO;
    [self.pageCurlView stopAnimating];
    [self.pageCurlView removeFromSuperview];
    
    [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:success  pageFlipType:self.pageFlipType];
}

- (void)curlAction:(BOOL)next tapPoint:(CGPoint)tapPoint
{
    UIView *targetView =  [self.dataSource XBPageDragViewTargetView:self willTurnToNext:next];
    
    CGRect r = targetView.frame;
    
    //self.curlingView = targetView;
    
    self.pageCurlView.opaque = NO; //Transparency on the next page (so that the view behind curlView will appear)
    self.pageCurlView.pageOpaque = YES; //The page to be curled has no transparency
    
    CGPoint cylinderPositionPre = CGPointMake(r.size.width, r.size.height/2);
    CGPoint cylinderPositionNext = CGPointMake(kLeftX, r.size.height/2);
    
    
    __weak typeof(self) weakself =self;
    CGPoint cylinderPosition =  next?cylinderPositionNext:cylinderPositionPre;
    CGPoint startPosition = tapPoint;
    //NSLog(@"curlAction start");
    _viewToCurl = targetView;
    [self.pageCurlView curlView:targetView cylinderPosition:cylinderPosition startPosition:startPosition cylinderAngle:M_PI_2 cylinderRadius:kRaduis animatedWithDuration:kDuration completion:^{
        //[weakself.cellContentView removeTempViewToContentView];
        weakself.hidden = NO;
       // NSLog(@"curlAction end");
        weakself.viewToCurl.hidden = NO;
        [weakself.delegate XBPageDragViewCurlDidEnd:self curlSuccess:YES  pageFlipType:self.pageFlipType];
        [weakself endFlip];
    }];
    
}

- (void)curlView:(UIView *)targetView
        maxAngle:(CGFloat)maxAngle
        minAngle:(CGFloat)minAngle
   touchLocation:(CGPoint)location
  targetPosition:(CGPoint)targetPosition
   cancelPostion:(CGPoint)cancelPosition

{    
    self.pageCurlView.cylinderPosition = self.cornerSnappingPoint.position;
    self.pageCurlView.cylinderAngle = self.cornerSnappingPoint.angle;
    self.pageCurlView.cylinderRadius = self.cornerSnappingPoint.radius;
 
    
    self.viewToCurl = targetView;
  
    
    self.pageCurlView.maximumCylinderAngle = maxAngle;
    self.pageCurlView.minimumCylinderAngle = minAngle;
    
    self.pageCurlView.snappingEnabled = YES;
    
    XBSnappingPoint *point = [[XBSnappingPoint alloc] initWithPosition:targetPosition failPosition:cancelPosition angle:M_PI_2 radius:kRaduis weight:1];
    
    [self.pageCurlView removeAllSnappingPoints];
    [self.pageCurlView addSnappingPoint:point];
    
    [self.pageCurlView touchBeganAtPoint:location];
    [self.viewToCurl.superview addSubview:self.pageCurlView];
    [self.pageCurlView startAnimating];
    
}

-(CGFloat)maxAngele:(CGPoint)location baseAngle:(CGFloat)baseAngle
{
   // CGPoint leftBottomPoint = CGPointMake(0, self.frame.size.height);
   // CGFloat tan = (location.x - leftBottomPoint.x) / (leftBottomPoint.y - location.y);
    return M_PI_4 + baseAngle;
}
-(CGFloat)minAngele:(CGPoint)location baseAngle:(CGFloat)baseAngle
{
   // CGPoint leftTopPoint = CGPointMake(0, 0);
   // CGFloat tan = (location.x - leftTopPoint.x) / (location.y - leftTopPoint.y);
    //NSLog(@"tan:%f,atan:%f",tan,atan(tan));
    return baseAngle - M_PI_4;
}
-(void)turnToNextPageAnimatedWithType:(NSString *)type
{
    if ([self.dataSource XBPageDragViewHasNextPage:self]) {
        self.pageIsCurled = YES;
        
        [TYBookPageTransformAnimation transitionWithType:type andBlock:^BOOL{
            BOOL b = [self.delegate XBPageDragViewTurnToNextPage:self];
            self.pageFlipType = BookPageFlipTypeToNextPage;
            [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:YES  pageFlipType:self.pageFlipType];
            [self endFlip];
            return b;
        } superLayer:self.superview.layer];
    } else if ([self.dataSource XBPageDragViewHasNextChapter:self]) {
        self.pageIsCurled = YES;
        [TYBookPageTransformAnimation transitionWithType:type andBlock:^BOOL{
           BOOL b = [self.delegate XBPageDragViewTurnToNextChapter:self completion:^{
                self.pageFlipType = BookPageFlipTypeToNextChapter;
                [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:YES  pageFlipType:self.pageFlipType];
                [self endFlip];
            }];
            if (!b) {
                [self endFlip];
            }
            return b;
            
        } superLayer:self.superview.layer];
        
    } else {
        [self endFlip];
    }
}

-(void)turnToPrePageAnimatedWithType:(NSString *)type
{
    if ([self.dataSource XBPageDragViewHasPrePage:self]) {
        [TYBookPageTransformAnimation transitionWithType:type andBlock:^BOOL{
            BOOL b  = [self.delegate XBPageDragViewTurnToPrePage:self];
            self.pageFlipType = BookPageFlipTypeToPrePage;
            [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:YES  pageFlipType:self.pageFlipType];
            [self endFlip];
            return b;
        } superLayer:self.superview.layer];
    } else if ([self.dataSource XBPageDragViewHasPreChapter:self]) {
        [TYBookPageTransformAnimation transitionWithType:type andBlock:^BOOL{
           BOOL b = [self.delegate XBPageDragViewTurnToPreChapter:self completion:^{
                self.pageFlipType = BookPageFlipTypeToPreChapter;

                [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:YES  pageFlipType:self.pageFlipType];
                [self endFlip];
            }];
            if (!b) {
                [self endFlip];
            }
            return b;
            
        } superLayer:self.superview.layer];
        
    } else {
        [self endFlip];
    }
}

-(void)turnToNextPageAnimatedWithMove
{
    if ([self.dataSource XBPageDragViewHasNextPage:self]) {
        self.pageIsCurled = YES;
        [self.delegate XBPageDragViewTurnToNextPage:self];
        self.pageFlipType = BookPageFlipTypeToNextPage;

        UIView *targetView = [self.dataSource XBPageDragViewTargetView:self willTurnToNext:YES];
        [self addShadowForView:targetView];
        
        [self.moveAnimation moveTargetView:targetView moveLength:-self.frame.size.width-10 duration:kMoveDuration animated:YES completion:^{
            [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:YES pageFlipType:self.pageFlipType];
            [self endFlip];
        }];
    
        
    } else if ([self.dataSource XBPageDragViewHasNextChapter:self]) {
        self.pageIsCurled = YES;
        BOOL suc = [self.delegate XBPageDragViewTurnToNextChapter:self completion:^{
            self.pageFlipType = BookPageFlipTypeToNextChapter;

            UIView *targetView = [self.dataSource XBPageDragViewTargetView:self willTurnToNext:YES];
            [self addShadowForView:targetView];
            
            [self.moveAnimation moveTargetView:targetView moveLength:-self.frame.size.width-10 duration:kMoveDuration animated:YES completion:^{
                [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:YES pageFlipType:self.pageFlipType];
                [self endFlip];
            }];
        }];
        if (!suc) {
            [self endFlip];
        }
        
        
        
    } else {
        [self endFlip];
    }
}

-(void)turnToPrePageAnimatedWithMove
{
    if ([self.dataSource XBPageDragViewHasPrePage:self]) {
        self.pageIsCurled = YES;
        [self.delegate XBPageDragViewTurnToPrePage:self];
        self.pageFlipType = BookPageFlipTypeToPrePage;

        UIView *targetView = [self.dataSource XBPageDragViewTargetView:self willTurnToNext:NO];
        CGRect targetRect = targetView.frame;
        targetRect.origin.x = -targetView.frame.size.width - 10;
        targetView.frame = targetRect;
        [self addShadowForView:targetView];
        
        [self.moveAnimation moveTargetView:targetView moveLength:0 duration:kMoveDuration animated:YES completion:^{
            [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:YES pageFlipType:self.pageFlipType];
            [self endFlip];
        }];
        
        
    } else if ([self.dataSource XBPageDragViewHasPreChapter:self]) {
        self.pageIsCurled = YES;
        BOOL suc = [self.delegate XBPageDragViewTurnToPreChapter:self completion:^{
            self.pageFlipType = BookPageFlipTypeToPreChapter;

            UIView *targetView = [self.dataSource XBPageDragViewTargetView:self willTurnToNext:NO];
            
            CGRect targetRect = targetView.frame;
            targetRect.origin.x = -targetView.frame.size.width - 10;
            targetView.frame = targetRect;
            
            [self addShadowForView:targetView];
            
            [self.moveAnimation moveTargetView:targetView moveLength:0 duration:kMoveDuration animated:YES completion:^{
                [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:YES pageFlipType:self.pageFlipType];
                [self endFlip];
            }];
        }];
        
        if (!suc) {
            [self endFlip];
        }
    } else {
        [self endFlip];
    }
}

-(void)addShadowForView:(UIView *)contentView
{
    contentView.layer.shadowColor = [UIColor grayColor].CGColor;
    contentView.layer.shadowOffset = CGSizeMake(5, 0);
    contentView.layer.shadowOpacity = 0.7;
}
-(void)removeShadowForView:(UIView *)contentView
{
    contentView.layer.shadowColor = [UIColor clearColor].CGColor;
    contentView.layer.shadowOffset = CGSizeMake(0, -3);
    contentView.layer.shadowOpacity = 0;
}

-(void)endFlip
{
    self.pageIsCurled = NO;
}

-(void)addObserverForTouch
{
    
    RACSignal *curlViewDidEndSignal = [RACObserve(self, curlViewDidEnd) map:^id(NSNumber * value) {
        return @((value != nil && value.boolValue));
    }];
    
  
    
    RACSignal *curlViewDidLoadSignal = [RACObserve(self, curlViewDidLoad) map:^id(NSNumber * value) {
        return @(value != nil && value.boolValue);
    }];
    
    
    RACSignal *combineSignal = [RACSignal combineLatest:@[curlViewDidEndSignal,curlViewDidLoadSignal] reduce:^id(NSNumber *value1,NSNumber *value2){
        return @(value1.boolValue && value2.boolValue);
    }];
    
    @weakify(self)
    [combineSignal subscribeNext:^(NSNumber * x) {
        @strongify(self)
        if (x.boolValue) {
            BookPageFlipAnimationType animationType = [self.dataSource XBPageDragViewPageFlipAnimationType:self];
            if (animationType == BookPageFlipAnimationTypeMove) {
                CGFloat moveX = [self.points movedX];

                [self moveViewToEndX:moveX];
                
            } else {
                [self cureViewToEndLocation:self.points.endPoint];
                
            }
        }
    }];
    
    
}

-(void)endPreCurl
{
    if (self.pageIsCurled) {
        BookPageFlipAnimationType flipType = [self.dataSource XBPageDragViewPageFlipAnimationType:self];
        switch (flipType) {
            case BookPageFlipAnimationTypeFade:
            {
                [self.delegate XBPageDragViewCurlDidEnd:self curlSuccess:YES pageFlipType:self.pageFlipType];
            }
                break;
            case BookPageFlipAnimationTypeMove:
            {
                [self.moveAnimation stopAnimation];               
            }
                break;
            case BookPageFlipAnimationTypeSimulation:
            {
                [self pageCurlViewDidSnapToPoint:YES];
            }
                break;
            default:
                break;
        }
        [self endFlip];
    }
}

-(BOOL)touchPointInLeftArea:(CGPoint)touchPoint
{
    return CGRectContainsPoint(TURN_LEFT_PAGE_RECT_1, touchPoint) || CGRectContainsPoint(TURN_TOP_PAGE_RECT_1, touchPoint);
}

-(BOOL)touchPointInRightArea:(CGPoint)touchPoint
{
    return CGRectContainsPoint(TURN_RIGHT_PAGE_RECT_1, touchPoint) || CGRectContainsPoint(TURN_BOTTOM_PAGE_RECT_1, touchPoint);
}

-(BOOL)touchPointInCenterArea:(CGPoint)touchPoint
{
    return CGRectContainsPoint(POP_DETAIL_RECT, touchPoint);
}
@end
