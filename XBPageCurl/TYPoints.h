//
//  TYPoints.h
//  Pods
//
//  Created by chengdonghai on 15/12/22.
//
//

#import <Foundation/Foundation.h>

@interface TYPoints : NSObject

@property(nonatomic,assign,readonly) CGPoint beginPoint;
@property(nonatomic,assign) CGPoint currentPoint;
@property(nonatomic,assign,readonly) CGPoint endPoint;
@property(nonatomic,strong) NSMutableArray *points;


-(void)addPoint:(CGPoint)point;
-(CGPoint)getMaxRightPoint;
-(CGPoint)getMaxLeftPoint;
-(void)clearAllPoints;
-(CGFloat)movedX;
-(CGFloat)movedY;

// 往右滑
-(BOOL)willMoveToRight;
// 往左滑
-(BOOL)willMoveToLeft;
-(BOOL)isMoved;

@end
