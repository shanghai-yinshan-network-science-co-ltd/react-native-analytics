//
//  ApAnalyticsUtil.h
//  adapundi
//
//  Created by liang zeng on 2022/3/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ApAnalyticsUtil : NSObject

//用户id
@property (nonatomic, copy) NSString *uid;

//经纬度
@property (nonatomic, copy) NSString *latitude;
@property (nonatomic, copy) NSString *longitude;


//更新经纬度
- (void)updateLatitude:(NSString *)latitude longitude:(NSString *)longitude;

//判断是否开启代理
- (BOOL)getProxyStatus ;

//vpn是否启用
- (BOOL)isVPNOn ;

//加速计数据
- (NSString *)getAccelerometerData;

//陀螺仪数据
- (NSString *)getGyroData;

//idfa
- (NSString *)getIdfa;

- (NSString *)getUid;

// 获取总磁盘容量
+ (NSString *)getTotalDiskSize;

// 获取可用磁盘容量
+ (NSString *)getAvailableDiskSize;

///手机是否越狱
+ (BOOL)isJailBreak;

//获取网络状态
+ (NSString *)getNetWorkInfo;

//获取运营商信息
+ (NSString *)getCarrierInfo;

//内网ip
+ (NSString *)IPAddress;

//获取可用内存
+(long long)getAvailableMemorySize;

//获取总内存
+(long long)getTotalMemorySize;

//获取机型
+ (NSString *)getDeviceModel;

//formatter Date
+(NSString*)getFormateLocalDate:(NSDate *)date;
//将本地日期字符串转为UTC日期字符串
+(NSString *)getUTCFormateLocalDate:(NSString *)localDate;


//配置入库（device）的数据，这部分数据不会变
- (NSDictionary *)getDeviceInfo;

//获取最新的设备数据，这部分数据会变
- (NSDictionary *)getRealTimeDeviceData:(NSString *)runId;

//获取启动日志
- (NSDictionary *)getStartLog:(NSDate *)startTime;


+ (NSString*)dictionaryToJson:(NSDictionary *)dic;

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;
@end

NS_ASSUME_NONNULL_END
