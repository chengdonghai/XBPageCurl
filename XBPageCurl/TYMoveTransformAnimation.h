//
//  TYMoveTransformAnimation.h
//  Pods
//
//  Created by chengdonghai on 15/12/14.
//
//

#import <Foundation/Foundation.h>

typedef void(^BlockCompletion)();

@interface TYMoveTransformAnimation : NSObject

@property(nonatomic,copy) BlockCompletion completion;

-(void)stopAnimation;

-(void)moveTargetView:(UIView *)moveView moveLength:(CGFloat)moveLength duration:(CGFloat)duration animated:(BOOL)animated completion:(void (^)(void))completion;

-(void)moveTargetViewWithMoveLength:(CGFloat)moveLength duration:(CGFloat)duration animated:(BOOL)animated;

-(void)moveTargetViewWithMoveLength:(CGFloat)moveLength duration:(CGFloat)duration animated:(BOOL)animated completion:(void (^)(void))completion;

-(void)moveTargetView:(UIView *)moveView moveLength:(CGFloat)moveLength duration:(CGFloat)duration animated:(BOOL)animated;

@end
