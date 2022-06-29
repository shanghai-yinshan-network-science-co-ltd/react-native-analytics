//
//  ApAnalytics.h
//  adapundi
//
//  Created by liang zeng on 2022/3/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ApAnalytics : NSObject

//埋点配置初始化
+ (void)configServer:(NSString *)serverUrl apiKey:(NSString *)apiKey;

@end

NS_ASSUME_NONNULL_END
