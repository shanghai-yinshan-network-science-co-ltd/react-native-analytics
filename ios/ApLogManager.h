//
//  ApLogManager.h
//  adapundi
//
//  Created by liang zeng on 2022/3/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ApLogManager : NSObject

+ (instancetype)sharedInstance;

//添加js透传的行为日志
- (void)addActionLog:(NSString *)log;

//更新位置
- (void)updateLatitude:(NSString *)latitude longitude:(NSString *)longitude;

//更新用户id
- (void)updateUserId:(NSString *)uId;

@end

NS_ASSUME_NONNULL_END
