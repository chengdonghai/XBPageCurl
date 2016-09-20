//
//  TYBookPageTransformAnimation.h
//  SurfingReader_V4.0
//
//  Created by chengdonghai on 15/12/1.
//  Copyright © 2015年 天翼阅读. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TYBookPageTransformAnimation : NSObject

+(void)transitionWithType:(NSString *)type andBlock:(void(^)())block superLayer:(CALayer *)layer;


@end
