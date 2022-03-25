//
//  ApAnalyticsManager.h
//  adapundi
//
//  Created by liang zeng on 2022/3/10.
//

#import <Foundation/Foundation.h>
#import "ApAnalyticsUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface ApNeworkManager : NSObject

+ (instancetype)sharedInstance;

//未配置上传地址 则不记录日志
- (BOOL)checkUploadEnable;

//配置服务器地址和Apikey
- (void)configServer:(NSString *)server apiKey:(NSString *)key;

//上传日志
- (void)sendLog:(NSDictionary *)dicData completionHandler:(void (^)(BOOL success))block;


@end

NS_ASSUME_NONNULL_END
