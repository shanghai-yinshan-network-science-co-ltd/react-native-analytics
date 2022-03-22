//
//  ApAnalyticsUtil.m
//  adapundi
//
//  Created by liang zeng on 2022/3/11.
//

#import "ApAnalyticsUtil.h"
#import <UIKit/UIKit.h>
#include <ifaddrs.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/ASIdentifierManager.h>
#import <CoreMotion/CoreMotion.h>

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

//计算存储空间
#include <sys/param.h>
#include <sys/mount.h>

//计算内存大小
#import <mach/mach.h>
#import <mach/mach_host.h>

#import <CoreLocation/CoreLocation.h>

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

#import "sys/utsname.h"

NSString *const kRRVPNStatusChangedNotification = @"kRRVPNStatusChangedNotification";

@interface ApAnalyticsUtil ()

@property (nonatomic, assign) BOOL vpnFlag;

//加速器
@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, copy) NSString *idfa;

/** 定位 */
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation ApAnalyticsUtil

- (instancetype)init{
  if(self = [super init]){
    [self accelerometerPull];
    [self configIdfa];
    
    //设置可以访问电池信息
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    
  }
  return self;
}

- (void)accelerometerPull{
  // 1.初始化运动管理对象
  self.motionManager = [[CMMotionManager alloc] init];
  // 2.判断加速计是否可用
  if (![self.motionManager isAccelerometerAvailable]) {
    NSLog(@"加速计不可用");
    return;
  }
  
  if (![self.motionManager isGyroAvailable]) {
    NSLog(@"陀螺仪不可用");
    return;
  }
  
  // 3.开始更新
  [self.motionManager startAccelerometerUpdates];
}

//获取idfa
- (NSString *)getIdfa{
  return _idfa ? _idfa : @"";
}

//获取idfa
- (void)configIdfa{
  //需要延时，否则可能取不到
  [NSTimer scheduledTimerWithTimeInterval:5.f repeats:false block:^(NSTimer * _Nonnull timer) {
    [ApAnalyticsUtil getIdfa:^(NSString * _Nonnull idfa) {
      self.idfa = idfa;
    }];
    [timer invalidate];
    timer = nil;
  }];
}

//加速计数据
- (NSString *)getAccelerometerData{
  CMAcceleration acceleration = self.motionManager.accelerometerData.acceleration;
  NSLog(@"加速度 == x:%f, y:%f, z:%f", acceleration.x, acceleration.y, acceleration.z);
  return [NSString stringWithFormat:@"%f,%f,%f", acceleration.x, acceleration.y, acceleration.z];
}

//陀螺仪数据
- (NSString *)getGyroData{
  CMRotationRate rotationRate = self.motionManager.gyroData.rotationRate;
  NSLog(@"加速度 == x:%f, y:%f, z:%f", rotationRate.x, rotationRate.y, rotationRate.z);
  return [NSString stringWithFormat:@"%f,%f,%f", rotationRate.x, rotationRate.y, rotationRate.z];
}

//判断是否设置了代理
- (BOOL)getProxyStatus {
  NSDictionary *proxySettings =  (__bridge NSDictionary *)(CFNetworkCopySystemProxySettings());
  NSArray *proxies = (__bridge NSArray *)(CFNetworkCopyProxiesForURL((__bridge CFURLRef _Nonnull)([NSURL URLWithString:@"http://www.baidu.com"]), (__bridge CFDictionaryRef _Nonnull)(proxySettings)));
  NSDictionary *settings = [proxies objectAtIndex:0];
  
  NSLog(@"host=%@", [settings objectForKey:(NSString *)kCFProxyHostNameKey]);
  NSLog(@"port=%@", [settings objectForKey:(NSString *)kCFProxyPortNumberKey]);
  NSLog(@"type=%@", [settings objectForKey:(NSString *)kCFProxyTypeKey]);
  
  if ([[settings objectForKey:(NSString *)kCFProxyTypeKey] isEqualToString:@"kCFProxyTypeNone"]){
    //没有设置代理
    return NO;
  }else{
    //设置代理了
    return YES;
  }
}

//判断是否开启了vpn
- (BOOL)isVPNOn
{
  BOOL flag = NO;
  NSString *version = [UIDevice currentDevice].systemVersion;
  // need two ways to judge this.
  if (version.doubleValue >= 9.0)
  {
    NSDictionary *dict = CFBridgingRelease(CFNetworkCopySystemProxySettings());
    NSArray *keys = [dict[@"__SCOPED__"] allKeys];
    for (NSString *key in keys) {
      if ([key rangeOfString:@"tap"].location != NSNotFound ||
          [key rangeOfString:@"tun"].location != NSNotFound ||
          [key rangeOfString:@"ipsec"].location != NSNotFound ||
          [key rangeOfString:@"ppp"].location != NSNotFound){
        flag = YES;
        break;
      }
    }
  }
  else
  {
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
      // Loop through linked list of interfaces
      temp_addr = interfaces;
      while (temp_addr != NULL)
      {
        NSString *string = [NSString stringWithFormat:@"%s" , temp_addr->ifa_name];
        if ([string rangeOfString:@"tap"].location != NSNotFound ||
            [string rangeOfString:@"tun"].location != NSNotFound ||
            [string rangeOfString:@"ipsec"].location != NSNotFound ||
            [string rangeOfString:@"ppp"].location != NSNotFound)
        {
          flag = YES;
          break;
        }
        temp_addr = temp_addr->ifa_next;
      }
    }
    
    // Free memory
    freeifaddrs(interfaces);
  }
  
  if (_vpnFlag != flag)
  {
    // reset flag
    _vpnFlag = flag;
    
    // post notification
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong __typeof(weakSelf)strongSelf = weakSelf;
      [[NSNotificationCenter defaultCenter] postNotificationName:kRRVPNStatusChangedNotification
                                                          object:strongSelf];
    });
  }
  
  return flag;
}

//获取idfa
+ (void)getIdfa:(void (^)(NSString *idfa))block{
  __block NSString *idfa = @"";
  if (@available(iOS 14, *)) {
    // iOS14及以上版本需要先请求权限
    [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
      // 获取到权限后，依然使用老方法获取idfa
      if (status == ATTrackingManagerAuthorizationStatusAuthorized) {
        idfa = [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
        NSLog(@"%@",idfa);
      } else {
        NSLog(@"请在设置-隐私-跟踪中允许App请求跟踪");
      }
      block(idfa);
    }];
  } else {
    // iOS14以下版本依然使用老方法
    // 判断在设置-隐私里用户是否打开了广告跟踪
    if ([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]) {
      idfa = [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
      NSLog(@"%@",idfa);
    } else {
      NSLog(@"请在设置-隐私-广告中打开广告跟踪功能");
    }
    block(idfa);
  }
}

#pragma 获取总磁盘容量
+ (NSString *)getTotalDiskSize {
  struct statfs buf;
  unsigned long long totalDiskSize = -1;
  if (statfs("/var", &buf) >= 0) {
    totalDiskSize = (unsigned long long)(buf.f_bsize * buf.f_blocks);
  }
  return [self fileSizeToString:totalDiskSize];
}

#pragma 获取可用磁盘容量  f_bavail 已经减去了系统所占用的大小，比 f_bfree 更准确
+ (NSString *)getAvailableDiskSize {
  struct statfs buf;
  unsigned long long availableDiskSize = -1;
  if (statfs("/var", &buf) >= 0) {
    availableDiskSize = (unsigned long long)(buf.f_bsize * buf.f_bavail);
  }
  return [self fileSizeToString:availableDiskSize];
}

+ (NSString *)fileSizeToString:(unsigned long long)fileSize {
  NSInteger KB = 1024;
  NSInteger MB = KB*KB;
  NSInteger GB = MB*KB;
  
  if (fileSize < 10)  {
    return @"0 B";
  }else if (fileSize < KB) {
    return @"< 1 KB";
  }else if (fileSize < MB) {
    return [NSString stringWithFormat:@"%.2f KB",((CGFloat)fileSize)/KB];
  }else if (fileSize < GB) {
    return [NSString stringWithFormat:@"%.2f MB",((CGFloat)fileSize)/MB];
  }else {
    return [NSString stringWithFormat:@"%.2f GB",((CGFloat)fileSize)/GB];
  }
}


///手机是否越狱
+ (BOOL)isJailBreak{
  BOOL isJail = NO;
  /// 根据是否能打开cydia判断
  if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cydia://"]]) {
    isJail = YES;
  }
  /// 根据是否能获取所有应用的名称判断 没有越狱的设备是没有读取所有应用名称的权限的。
  if ([[NSFileManager defaultManager] fileExistsAtPath:@"User/Applications/"]) {
    isJail = YES;
  }
  
  NSArray *jailbreak_tool_paths = @[
    @"/Applications/Cydia.app",
    @"/Library/MobileSubstrate/MobileSubstrate.dylib",
    @"/bin/bash",
    @"/usr/sbin/sshd",
    @"/etc/apt"
  ];
  
  /// 判断这些文件是否存在，只要有存在的，就可以认为手机已经越狱了。
  for (int i=0; i<jailbreak_tool_paths.count; i++) {
    if ([[NSFileManager defaultManager] fileExistsAtPath:jailbreak_tool_paths[i]]) {
      isJail = YES;
    }
  }
  
  return isJail;
}

//获取网络状态
+ (NSString *)getNetWorkInfo{
  
  return  @"";
  NSString *networktype = @"";
  NSArray *subviews = [[[[UIApplication sharedApplication] valueForKey:@"statusBar"] valueForKey:@"foregroundView"]subviews];
  NSNumber *dataNetworkItemView = nil;
  for (id subview in subviews) {
    if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
      dataNetworkItemView = subview;
      break;
    }
  }
  
  switch ([[dataNetworkItemView valueForKey:@"dataNetworkType"]integerValue]) {
    case 0:
      networktype = @"无服务";
      break;
      
    case 1:
      networktype = @"2G";
      break;
      
    case 2:
      networktype = @"3G";
      break;
      
    case 3:
      networktype = @"4G";
      break;
      
    case 4:
      networktype = @"LTE";
      break;
      
    case 5:
      networktype = @"Wi-Fi";
      break;
    default:
      break;
  }
  return networktype;
};

//获取运营商信息
+ (NSString *)getCarrierInfo{
  CTTelephonyNetworkInfo *telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
  CTCarrier *carrier = [telephonyInfo subscriberCellularProvider];
  NSString *carrierName = [carrier carrierName];
  //    NSString *mcc = [carrier mobileCountryCode]; // 国家码 如：460
  //    NSString *mnc = [carrier mobileNetworkCode]; // 网络码 如：01
  //    NSString *isoCountryCode = [carrier isoCountryCode]; // cn
  //    BOOL allowsVOIP = [carrier allowsVOIP];// YES
  return carrierName;
};

//更新经纬度
- (void)updateLatitude:(NSString *)latitude longitude:(NSString *)longitude{
  self.latitude = latitude;
  self.longitude = longitude;
}

//内网ip
+ (NSString *)IPAddress{
  NSString *address = @"0.0.0.0";
  struct ifaddrs *interfaces = NULL;
  struct ifaddrs *XZHDX_addr = NULL;
  int success = 0;
  
  // retrieve the current interfaces - returns 0 on success
  success = getifaddrs(&interfaces);
  if (success == 0) {
    // Loop through linked list of interfaces
    XZHDX_addr = interfaces;
    while (XZHDX_addr != NULL) {
      if( XZHDX_addr->ifa_addr->sa_family == AF_INET) {
        // Check if interface is en0 which is the wifi connection on the iPhone
        if ([[NSString stringWithUTF8String:XZHDX_addr->ifa_name] isEqualToString:@"en0"]) {
          // Get NSString from C String
          address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)XZHDX_addr->ifa_addr)->sin_addr)];
        }
      }
      
      XZHDX_addr = XZHDX_addr->ifa_next;
    }
  }
  
  // Free memory
  freeifaddrs(interfaces);
  
  return address;
}

//获取可用内存
+(long long)getAvailableMemorySize
{
  vm_statistics_data_t vmStats;
  mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
  kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
  if (kernReturn != KERN_SUCCESS)
  {
    return NSNotFound;
  }
  
  return ((vm_page_size * vmStats.free_count + vm_page_size * vmStats.inactive_count));
}

//获取总内存
+(long long)getTotalMemorySize
{
  return [NSProcessInfo processInfo].physicalMemory;
}

//获取机型
+ (NSString *)getDeviceModel {
  struct utsname systemInfo;
  uname(&systemInfo);
  // 获取设备标识Identifier
  NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
  
  // iPhone
  if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone 2G";
  if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
  if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
  if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone 4";
  if ([platform isEqualToString:@"iPhone3,2"]) return @"iPhone 4";
  if ([platform isEqualToString:@"iPhone3,3"]) return @"iPhone 4";
  if ([platform isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";
  if ([platform isEqualToString:@"iPhone5,1"]) return @"iPhone 5";
  if ([platform isEqualToString:@"iPhone5,2"]) return @"iPhone 5";
  if ([platform isEqualToString:@"iPhone5,3"]) return @"iPhone 5c";
  if ([platform isEqualToString:@"iPhone5,4"]) return @"iPhone 5c";
  if ([platform isEqualToString:@"iPhone6,1"]) return @"iPhone 5s";
  if ([platform isEqualToString:@"iPhone6,2"]) return @"iPhone 5s";
  if ([platform isEqualToString:@"iPhone7,1"]) return @"iPhone 6 Plus";
  if ([platform isEqualToString:@"iPhone7,2"]) return @"iPhone 6";
  if ([platform isEqualToString:@"iPhone8,1"]) return @"iPhone 6s";
  if ([platform isEqualToString:@"iPhone8,2"]) return @"iPhone 6s Plus";
  if ([platform isEqualToString:@"iPhone8,4"]) return @"iPhone SE";
  if ([platform isEqualToString:@"iPhone9,1"]) return @"iPhone 7";
  if ([platform isEqualToString:@"iPhone9,2"]) return @"iPhone 7 Plus";
  if ([platform isEqualToString:@"iPhone10,1"]) return @"iPhone 8";
  if ([platform isEqualToString:@"iPhone10,4"]) return @"iPhone 8";
  if ([platform isEqualToString:@"iPhone10,2"]) return @"iPhone 8 Plus";
  if ([platform isEqualToString:@"iPhone10,5"]) return @"iPhone 8 Plus";
  if ([platform isEqualToString:@"iPhone10,3"]) return @"iPhone X";
  if ([platform isEqualToString:@"iPhone10,6"]) return @"iPhone X";
  if ([platform isEqualToString:@"iPhone11,2"]) return @"iPhone XS";
  if ([platform isEqualToString:@"iPhone11,6"]) return @"iPhone XS MAX";
  if ([platform isEqualToString:@"iPhone11,8"]) return @"iPhone XR";
  if ([platform isEqualToString:@"iPhone12,1"]) return @"iPhone 11";
  if ([platform isEqualToString:@"iPhone12,3"]) return @"iPhone 11 Pro";
  if ([platform isEqualToString:@"iPhone12,5"]) return @"iPhone 11 Pro Max";
  if ([platform isEqualToString:@"iPhone12,8"]) return @"iPhone SE (2nd generation)";
  if ([platform isEqualToString:@"iPhone13,1"]) return @"iPhone 12 mini";
  if ([platform isEqualToString:@"iPhone13,2"]) return @"iPhone 12";
  if ([platform isEqualToString:@"iPhone13,3"]) return @"iPhone 12 Pro";
  if ([platform isEqualToString:@"iPhone13,4"]) return @"iPhone 12 Pro Max";
  if ([platform isEqualToString:@"iPhone14,1"]) return @"iPhone 13 mini";
  if ([platform isEqualToString:@"iPhone14,2"]) return @"iPhone 13";
  if ([platform isEqualToString:@"iPhone14,3"]) return @"iPhone 13 Pro";
  if ([platform isEqualToString:@"iPhone14,4"]) return @"iPhone 13 Pro Max";
  
  // iPod
  if ([platform isEqualToString:@"iPod1,1"])  return @"iPod Touch 1";
  if ([platform isEqualToString:@"iPod2,1"])  return @"iPod Touch 2";
  if ([platform isEqualToString:@"iPod3,1"])  return @"iPod Touch 3";
  if ([platform isEqualToString:@"iPod4,1"])  return @"iPod Touch 4";
  if ([platform isEqualToString:@"iPod5,1"])  return @"iPod Touch 5";
  if ([platform isEqualToString:@"iPod7,1"])  return @"iPod Touch 6";
  if ([platform isEqualToString:@"iPod9,1"])  return @"iPod Touch 7";
  
  // iPad
  if ([platform isEqualToString:@"iPad1,1"])  return @"iPad 1";
  if ([platform isEqualToString:@"iPad2,1"])  return @"iPad 2";
  if ([platform isEqualToString:@"iPad2,2"]) return @"iPad 2";
  if ([platform isEqualToString:@"iPad2,3"])  return @"iPad 2";
  if ([platform isEqualToString:@"iPad2,4"])  return @"iPad 2";
  if ([platform isEqualToString:@"iPad2,5"])  return @"iPad Mini 1";
  if ([platform isEqualToString:@"iPad2,6"])  return @"iPad Mini 1";
  if ([platform isEqualToString:@"iPad2,7"])  return @"iPad Mini 1";
  if ([platform isEqualToString:@"iPad3,1"])  return @"iPad 3";
  if ([platform isEqualToString:@"iPad3,2"])  return @"iPad 3";
  if ([platform isEqualToString:@"iPad3,3"])  return @"iPad 3";
  if ([platform isEqualToString:@"iPad3,4"])  return @"iPad 4";
  if ([platform isEqualToString:@"iPad3,5"])  return @"iPad 4";
  if ([platform isEqualToString:@"iPad3,6"])  return @"iPad 4";
  if ([platform isEqualToString:@"iPad4,1"])  return @"iPad Air";
  if ([platform isEqualToString:@"iPad4,2"])  return @"iPad Air";
  if ([platform isEqualToString:@"iPad4,3"])  return @"iPad Air";
  if ([platform isEqualToString:@"iPad4,4"])  return @"iPad Mini 2";
  if ([platform isEqualToString:@"iPad4,5"])  return @"iPad Mini 2";
  if ([platform isEqualToString:@"iPad4,6"])  return @"iPad Mini 2";
  if ([platform isEqualToString:@"iPad4,7"])  return @"iPad mini 3";
  if ([platform isEqualToString:@"iPad4,8"])  return @"iPad mini 3";
  if ([platform isEqualToString:@"iPad4,9"])  return @"iPad mini 3";
  if ([platform isEqualToString:@"iPad5,1"])  return @"iPad mini 4";
  if ([platform isEqualToString:@"iPad5,2"])  return @"iPad mini 4";
  if ([platform isEqualToString:@"iPad5,3"])  return @"iPad Air 2";
  if ([platform isEqualToString:@"iPad5,4"])  return @"iPad Air 2";
  if ([platform isEqualToString:@"iPad6,3"])  return @"iPad Pro (9.7-inch)";
  if ([platform isEqualToString:@"iPad6,4"])  return @"iPad Pro (9.7-inch)";
  if ([platform isEqualToString:@"iPad6,7"])  return @"iPad Pro (12.9-inch)";
  if ([platform isEqualToString:@"iPad6,8"])  return @"iPad Pro (12.9-inch)";
  if ([platform isEqualToString:@"iPad6,11"])  return @"iPad 5";
  if ([platform isEqualToString:@"iPad6,12"])  return @"iPad 5";
  if ([platform isEqualToString:@"iPad7,1"])  return @"iPad Pro 2(12.9-inch)";
  if ([platform isEqualToString:@"iPad7,2"])  return @"iPad Pro 2(12.9-inch)";
  if ([platform isEqualToString:@"iPad7,3"])  return @"iPad Pro (10.5-inch)";
  if ([platform isEqualToString:@"iPad7,4"])  return @"iPad Pro (10.5-inch)";
  if ([platform isEqualToString:@"iPad7,5"])  return @"iPad 6";
  if ([platform isEqualToString:@"iPad7,6"])  return @"iPad 6";
  if ([platform isEqualToString:@"iPad7,11"])  return @"iPad 7";
  if ([platform isEqualToString:@"iPad7,12"])  return @"iPad 7";
  if ([platform isEqualToString:@"iPad8,1"])  return @"iPad Pro (11-inch) ";
  if ([platform isEqualToString:@"iPad8,2"])  return @"iPad Pro (11-inch) ";
  if ([platform isEqualToString:@"iPad8,3"])  return @"iPad Pro (11-inch) ";
  if ([platform isEqualToString:@"iPad8,4"])  return @"iPad Pro (11-inch) ";
  if ([platform isEqualToString:@"iPad8,5"])  return @"iPad Pro 3 (12.9-inch) ";
  if ([platform isEqualToString:@"iPad8,6"])  return @"iPad Pro 3 (12.9-inch) ";
  if ([platform isEqualToString:@"iPad8,7"])  return @"iPad Pro 3 (12.9-inch) ";
  if ([platform isEqualToString:@"iPad8,8"])  return @"iPad Pro 3 (12.9-inch) ";
  if ([platform isEqualToString:@"iPad11,1"])  return @"iPad mini 5";
  if ([platform isEqualToString:@"iPad11,2"])  return @"iPad mini 5";
  if ([platform isEqualToString:@"iPad11,3"])  return @"iPad Air 3";
  if ([platform isEqualToString:@"iPad11,4"])  return @"iPad Air 3";
  
  // 其他
  if ([platform isEqualToString:@"i386"])   return @"iPhone Simulator";
  if ([platform isEqualToString:@"x86_64"])  return @"iPhone Simulator";
  
  return platform;
}

- (NSString *)getUid{
#warning 用户登录设置，登出清空？？？
  if(_uid){
    return _uid;
  }
  return @"";
}

//formatter Date
+(NSString*)getFormateLocalDate:(NSDate *)date{
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
  NSString *time_now = [formatter stringFromDate:date];
  return time_now;
}

//将本地日期字符串转为UTC日期字符串
+(NSString *)getUTCFormateLocalDate:(NSString *)localDate
{
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
  NSDate *dateFormatted = [dateFormatter dateFromString:localDate];
  NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
  [dateFormatter setTimeZone:timeZone];
  [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
  NSString *dateString = [dateFormatter stringFromDate:dateFormatted];
  return dateString;
}


//配置入库（device）的数据，这部分数据不会变
- (NSDictionary *)getDeviceInfo{
  NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:1];
  [dic setObject:@"" forKey:@"air_mode"];
  [dic setObject:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forKey:@"android_id"];
  [dic setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] forKey:@"app_version"];
  [dic setObject:@"" forKey:@"applist"];
  [dic setObject:@"" forKey:@"bluetooth_list"];
  [dic setObject:@"" forKey:@"cid"];
  
  [dic setObject:@"" forKey:@"cpu_cur_freq"];
  [dic setObject:@"" forKey:@"cpu_max_freq"];
  [dic setObject:@"" forKey:@"cpu_min_freq"];
  [dic setObject:@"" forKey:@"cpu_name"];
  
  [dic setObject:@"app_log" forKey:@"data_type"];
  [dic setObject:@"15" forKey:@"data_version"];
  
  [dic setObject:@"" forKey:@"deviceId"];
  [dic setObject:@"" forKey:@"deviceId2"];
  
  [dic setObject:[ApAnalyticsUtil getTotalDiskSize] forKey:@"disk_avail"];
  [dic setObject:[ApAnalyticsUtil getAvailableDiskSize] forKey:@"disk_total"];
  
  [dic setObject:@"" forKey:@"do_not_disturb"];
  
  [dic setObject:@"" forKey:@"iccid"];
  [dic setObject:@"" forKey:@"iccid2"];
  [dic setObject:@"" forKey:@"imei"];
  [dic setObject:@"" forKey:@"imei2"];
  [dic setObject:@"" forKey:@"imsi"];
  [dic setObject:@"" forKey:@"imsi2"];
  [dic setObject:@"" forKey:@"instance_id"];
  
  [dic setObject:@"" forKey:@"lineNumber"];
  
  [dic setObject:[NSNumber numberWithBool:[ApAnalyticsUtil isJailBreak]] forKey:@"isRoot"];
  [dic setObject:[NSNumber numberWithBool:[self getProxyStatus]] forKey:@"isWifiProxy"];
  [dic setObject:[NSNumber numberWithBool:[self isVPNOn]] forKey:@"isVpnUsed"];
  
  [dic setObject:[ApAnalyticsUtil getCarrierInfo] forKey:@"isp_info"];
  [dic setObject:@"" forKey:@"lac"];
  
  [dic setObject:@"" forKey:@"lineNumber"];
  [dic setObject:[ApAnalyticsUtil IPAddress] forKey:@"ipv4"];
  
  [dic setObject:@"" forKey:@"ip"];
  
  NSArray*languageArray = [NSLocale preferredLanguages];
  NSString*language = [languageArray objectAtIndex:0];
  [dic setObject:language forKey:@"locale"];
  
  [dic setObject:@"HIGH" forKey:@"location_type"];
  
  [dic setObject:@"" forKey:@"wifiMac"];
  [dic setObject:@"" forKey:@"mcc"];
  [dic setObject:@"" forKey:@"mcc2"];
  [dic setObject:@"" forKey:@"meid"];
  [dic setObject:@"" forKey:@"meid2"];
  
  [dic setObject:[NSNumber numberWithInteger:[ApAnalyticsUtil getAvailableMemorySize]] forKey:@"mem_avail"];
  [dic setObject:[NSNumber numberWithInteger:[ApAnalyticsUtil getTotalMemorySize]]forKey:@"men_total"];
  
  [dic setObject:@"" forKey:@"mnc"];
  [dic setObject:@"" forKey:@"mnc2"];
  [dic setObject:@"" forKey:@"nativePhoneNum"];
  [dic setObject:@"" forKey:@"nativePhoneNum2"];
  
  [dic setObject:[ApAnalyticsUtil getNetWorkInfo] forKey:@"networktype"];
  [dic setObject:@"ios" forKey:@"os"];
  [dic setObject:[[UIDevice currentDevice] systemVersion] forKey:@"sysVersion"];
  
  [dic setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"] forKey:@"package_name"];
  [dic setObject:@"iphone" forKey:@"phone_brand"];
  [dic setObject:[ApAnalyticsUtil getDeviceModel] forKey:@"model"];
  
  [dic setObject:@"" forKey:@"pid"];
  [dic setObject:@"7" forKey:@"platform_id"];
  [dic setObject:@"adapundi" forKey:@"platform_name"];
  
  [dic setObject:@"" forKey:@"providersName"];
  [dic setObject:@"" forKey:@"providersName2"];
  
  [dic setObject:@"" forKey:@"routerMac"];
  [dic setObject:@"" forKey:@"routerName"];
  
  [dic setObject:[NSNumber numberWithFloat:[UIScreen mainScreen].bounds.size.width] forKey:@"screen_width"];
  [dic setObject:[NSNumber numberWithFloat:[UIScreen mainScreen].bounds.size.height] forKey:@"screen_height"];
  
  [dic setObject:@"" forKey:@"sdk_version"];
  [dic setObject:@"" forKey:@"serial_number"];
  [dic setObject:@"" forKey:@"user_uuid"];
  [dic setObject:@"" forKey:@"wifi_list"];
  
  return [dic copy];
}

//配置当前的设备数据
- (NSDictionary *)getRealTimeDeviceData:(NSString *)runId{
  NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:1];
  [dic setObject:[self getAccelerometerData] forKey:@"accelerate_info"];
  [dic setObject:[self getIdfa] forKey:@"advertising_id"];
  [dic setObject:@"" forKey:@"BatteryCapacity"];
  [dic setObject:[NSString stringWithFormat:@"%.f",  [[UIDevice currentDevice] batteryLevel] * 100] forKey:@"BatteryCapacityScale"];
  [dic setObject:[UIPasteboard generalPasteboard].string ? [UIPasteboard generalPasteboard].string : @"" forKey:@"clipboard_with_text"];
  [dic setObject:[self getGyroData] forKey:@"gyro_info"];
  
  [dic setObject:self.latitude ? self.latitude : @"" forKey:@"latitude"];
  [dic setObject:self.longitude ? self.longitude : @"" forKey:@"longitude"];
  
  NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
  NSTimeInterval time=[date timeIntervalSince1970]*1000;
  NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
  [dic setObject:timeString forKey:@"local_time"];
  
  [dic setObject:@"" forKey:@"time_offset"];
  
  [dic setObject:runId forKey:@"run_id"];
  return [dic copy];
}

//获取启动日志
- (NSDictionary *)getStartLog:(NSDate *)startTime{
  NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:1];
  [dic setObject:@"start_event" forKey:@"action_type"];
  [dic setObject:@"" forKey:@"extra_data"];
  [dic setObject:@"native" forKey:@"log_source"];
  [dic setObject:[self getUid] forKey:@"user_uuid"];
  
  NSDate *date = [NSDate date];
  [dic setObject:[ApAnalyticsUtil getFormateLocalDate:date]  forKey:@"log_time"];
  [dic setObject:[ApAnalyticsUtil getUTCFormateLocalDate:[ApAnalyticsUtil getFormateLocalDate:date]] forKey:@"log_time_z"];
  
  [dic setObject:[ApAnalyticsUtil getFormateLocalDate:startTime] forKey:@"start_time"];
  [dic setObject:[ApAnalyticsUtil getUTCFormateLocalDate:[ApAnalyticsUtil getFormateLocalDate:startTime]] forKey:@"start_time_z"];
  return [dic copy];
}


+ (NSString*)dictionaryToJson:(NSDictionary *)dic{
  
  NSError *parseError = nil;
  NSData  *jsonData = [NSJSONSerialization dataWithJSONObject:dic
                                                      options:NSJSONWritingPrettyPrinted
                                                        error:&parseError];
  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
  
  if (jsonString == nil) {
    return nil;
  }
  
  NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
  NSError *err;
  NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
  if(err) {
    NSLog(@"json解析失败：%@",err);
    return nil;
  }
  
  return dic;
}

@end


