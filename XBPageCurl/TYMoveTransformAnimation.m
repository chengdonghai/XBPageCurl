//
//  TYMoveTransformAnimation.m
//  Pods
//
//  Created by chengdonghai on 15/12/14.
//
//

#import "TYMoveTransformAnimation.h"

@interface TYMoveTransformAnimation()

@property(nonatomic,strong) UIView *viewToCurl;
@property(nonatomic,assign) CGFloat targetX;
@end
@implementation TYMoveTransformAnimation


-(void)moveTargetView:(UIView *)moveView moveLength:(CGFloat)moveLength duration:(CGFloat)duration animated:(BOOL)animated completion:(void (^)(void))completion
{
    self.completion = completion;
    if (moveView == nil) {
        if (self.completion) {
            self.completion();
            self.completion = nil;
        }
        return;
    }
    self.targetX = moveLength;
    self.viewToCurl = moveView;
    if (animated) {
        
        CABasicAnimation *theAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        theAnimation.delegate = self;
        theAnimation.duration = duration;
        theAnimation.repeatCount = 0;
        theAnimation.fillMode =  kCAFillModeForwards;
        theAnimation.cumulative = NO;
        theAnimation.removedOnCompletion = NO;
        theAnimation.autoreverses = NO;
        theAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        theAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(moveView.frame.origin.x + moveView.frame.size.width / 2, moveView.center.y)]; //[NSNumber numberWithFloat:moveView.frame.origin.x];
        theAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(moveLength + moveView.frame.size.width / 2, moveView.center.y)];//[NSNumber numberWithFloat:moveLength];
        [self.viewToCurl.layer addAnimation:theAnimation forKey:@"animateLayer"];
        
//                [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:1.0f initialSpringVelocity:5.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
//                    CGRect rect = moveView.frame;
//                    rect.origin.x = moveLength;
//                    moveView.frame = rect;
//                } completion:^(BOOL finished) {
////                    if (completion) {
////                        completion();
////                    }
//                    if (self.completion) {
//                        self.completion();
//                    }
//                }];
        
    } else {
        CGRect rect = moveView.frame;
        rect.origin.x = moveLength;
        moveView.frame = rect;
        if (self.completion) {
            self.completion();
        }
    }
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    //NSUInteger idx = [_selectedIndexes firstIndex];
   // NSLog(@"removeAnimationAtidx:%i",flag);
    [self stopAnimation];
}

-(void)stopAnimation
{
    
    [self.viewToCurl.layer removeAnimationForKey:@"animateLayer"];
    
    CGRect rect = self.viewToCurl.frame;
    rect.origin.x = self.targetX;
    self.viewToCurl.frame = rect;
    
    //self.viewToCurl.layer.position = ((CALayer *)self.viewToCurl.layer.presentationLayer).position;
    if (self.completion) {
        self.completion();
        self.completion = nil;
    }
}


-(void)moveTargetViewWithMoveLength:(CGFloat)moveLength duration:(CGFloat)duration animated:(BOOL)animated
{
    [self moveTargetView:self.viewToCurl moveLength:moveLength duration:(CGFloat)duration animated:animated completion:nil];
}

-(void)moveTargetViewWithMoveLength:(CGFloat)moveLength duration:(CGFloat)duration animated:(BOOL)animated completion:(void (^)(void))completion
{
    [self moveTargetView:self.viewToCurl moveLength:moveLength duration:duration animated:animated completion:completion];
}


-(void)moveTargetView:(UIView *)moveView moveLength:(CGFloat)moveLength duration:(CGFloat)duration animated:(BOOL)animated
{
    [self moveTargetView:moveView moveLength:moveLength duration:duration animated:animated completion:nil];
}

@end
