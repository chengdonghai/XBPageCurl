//
//  TYXBUtil.h
//  Pods
//
//  Created by chengdonghai on 16/1/27.
//
//

#import <Foundation/Foundation.h>

@interface TYXBUtil : NSObject

+ (NSString *) getSysInfoByName:(char *)typeSpecifier;

+ (NSString *) platformString;

@end
