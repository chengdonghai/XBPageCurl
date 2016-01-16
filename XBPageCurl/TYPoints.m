//
//  TYPoints.m
//  Pods
//
//  Created by chengdonghai on 15/12/22.
//
//

#import "TYPoints.h"
#import "CGPointAdditions.h"

@implementation TYPoints

-(NSMutableArray *)points
{
    if (_points == nil) {
        _points = [NSMutableArray array];
    }
    return _points;
}

-(CGPoint)getMaxLeftPoint
{
    CGPoint tmp;
    for (int i = 0; i < self.points.count; i++) {
        NSString *pointForStr = [self.points objectAtIndex:i];
        CGPoint point = CGPointFromString(pointForStr);
        if (i == 0) {
            tmp = point;
            continue;
        }
        
        if (point.x < tmp.x) {
            tmp = point;
        }
    }
    return tmp;
}

-(CGPoint)getMaxRightPoint
{
    CGPoint tmp;
    for (int i = 0; i < self.points.count; i++) {
        NSString *pointForStr = [self.points objectAtIndex:i];
        CGPoint point = CGPointFromString(pointForStr);
        if (i == 0) {
            tmp = point;
            continue;
        }
        
        if (point.x > tmp.x) {
            tmp = point;
        }
    }
    return tmp;
}

-(BOOL)willMoveToRight
{
    CGPoint maxleftPoint = [self getMaxLeftPoint];
    return CGPointToPointDistance(self.currentPoint, maxleftPoint) > 10 && self.currentPoint.x > maxleftPoint.x;
}

-(BOOL)willMoveToLeft
{
    CGPoint maxrightPoint = [self getMaxRightPoint];
    return CGPointToPointDistance(self.currentPoint, maxrightPoint) > 10 && self.currentPoint.x < maxrightPoint.x;
}

-(void)addPoint:(CGPoint)point
{
    [self.points addObject:NSStringFromCGPoint(point)];
    self.currentPoint = point;
}

-(CGPoint)beginPoint
{
    if (self.points.count > 0) {
        return CGPointFromString([self.points firstObject]);
    }
    return CGPointZero;
}

-(CGPoint)endPoint
{
    if (self.points.count > 0) {
        return CGPointFromString([self.points lastObject]);
    }
    return CGPointZero;
}


-(void)clearAllPoints
{
    [self.points removeAllObjects];
}

-(CGFloat)movedX
{
   return self.currentPoint.x - self.beginPoint.x;
}

-(CGFloat)movedY
{
    return self.currentPoint.y - self.beginPoint.y;
}

-(BOOL)isMoved
{
    if (self.points == nil || self.points.count <= 2) {
        return NO;
    }
    __block BOOL move = NO;
    [self.points enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (CGPointToPointDistance(self.beginPoint, CGPointFromString(obj)) > 10) {
            move = YES;
            *stop = YES;
        }
    }];
    return move;
}
@end
