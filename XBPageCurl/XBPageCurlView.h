//
//  XBPageCurlView.h
//  XBPageCurl
//
//  Created by xiss burg on 8/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XBCurlView.h"
#import "XBSnappingPoint.h"

@protocol XBPageCurlViewDelegate;
/**
 * XBPageCurlView
 * Adds user interaction to XBCurlView. Allows the user to drag the page with his finger and also supports the placement of 
 * snapping points that the cylinder will stick to after the user releases his finger off the screen.
 */
@interface XBPageCurlView : XBCurlView

@property (nonatomic, strong) NSMutableArray *snappingPointArray;
@property (nonatomic, assign) BOOL snappingEnabled;
@property (nonatomic, assign) CGFloat minimumCylinderAngle;
@property (nonatomic, assign) CGFloat maximumCylinderAngle;
@property (nonatomic, readonly) NSArray *snappingPoints;
@property (nonatomic, assign) id<XBPageCurlViewDelegate> pageCurlViewDelegate;

- (void)touchBeganAtPoint:(CGPoint)p;
- (void)touchMovedToPoint:(CGPoint)p;
- (void)touchEndedAtPoint:(CGPoint)p andCurlSuccess:(BOOL)success;
- (void)addSnappingPoint:(XBSnappingPoint *)snappingPoint;
- (void)addSnappingPointsFromArray:(NSArray *)snappingPoints;
- (void)removeSnappingPoint:(XBSnappingPoint *)snappingPoint;
- (void)removeAllSnappingPoints;
- (id)initWithFrame:(CGRect)frame readInDay:(BOOL)readInDay;

@end

@protocol XBPageCurlViewDelegate <NSObject>

-(void)XBPageCurlView:(XBPageCurlView *)curlView touchBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)XBPageCurlView:(XBPageCurlView *)curlView touchMove:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)XBPageCurlView:(XBPageCurlView *)curlView touchEnd:(NSSet *)touches withEvent:(UIEvent *)event;

@end
/**
 * Every XBPageCurlView instance posts these notifications before and after the cylinder snaps to a point (if snapping is enabled for that
 * view). The object of the notification is the XBPageCurlView instance itself and the snapping point instance is under the 
 * kXBSnappingPointKey key in the userInfo dictionary.
 */
extern NSString *const XBPageCurlViewWillSnapToPointNotification;
extern NSString *const XBPageCurlViewDidSnapToPointNotification;
extern NSString *const kXBSnappingPointKey;
extern NSString *const kXBCurlSuccessKey;
extern NSString *const kXBCurlDirectionKey;


