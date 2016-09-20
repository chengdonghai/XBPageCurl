//
//  TYBookPageTransformAnimation.m
//  SurfingReader_V4.0
//
//  Created by chengdonghai on 15/12/1.
//  Copyright © 2015年 天翼阅读. All rights reserved.
//

#import "TYBookPageTransformAnimation.h"

@implementation TYBookPageTransformAnimation

+(void)transitionWithType:(NSString *)type andBlock:(void(^)())block superLayer:(CALayer *)layer
{
    if(block) {
        CATransition *transition = [[CATransition alloc] init];
        transition.delegate = self;
        transition.type = kCATransitionFade;
        transition.duration = 0.1;
        transition.timingFunction = UIViewAnimationCurveEaseInOut;
        block();
        [layer addAnimation:transition forKey:@"animation"];
    }
    
}

@end
