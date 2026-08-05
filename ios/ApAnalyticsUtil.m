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
#include <sys/sysctl.h>

#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreNFC/CoreNFC.h>

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

#import "sys/utsname.h"
#include <mach-o/dyld.h>
#include <unistd.h>
#import "DeviceUID.h"

NSString *const kRRVPNStatusChangedNotification = @"kRRVPNStatusChangedNotification";

@interface ApAnalyticsUtil ()

@property (nonatomic, assign) BOOL vpnFlag;

//加速器
@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, copy) NSString *idfa;

/** 定位 */
@property (nonatomic, strong) CLLocationManager *locationManager;

/** Common-property snapshot (Sensors public properties) */
@property (nonatomic, assign) BOOL commonPropsReady;
@property (nonatomic, copy) NSString *snapLanguage;
@property (nonatomic, copy) NSString *snapTimezoneDisplayName;
@property (nonatomic, copy) NSString *snapLatitude;
@property (nonatomic, copy) NSString *snapLongitude;
@property (nonatomic, copy) NSString *snapWifiSsid;
@property (nonatomic, copy) NSString *snapWifiBssid;
@property (nonatomic, copy) NSString *snapWifiMac;
@property (nonatomic, copy) NSString *snapWifiList;
@property (nonatomic, copy) NSString *snapAccelerationInfo;
@property (nonatomic, copy) NSString *snapGyroInfo;
@property (nonatomic, assign) BOOL snapAirMode;
@property (nonatomic, assign) BOOL snapIsRoot;
@property (nonatomic, assign) BOOL snapClickPositionIsCenter;

@end

@implementation ApAnalyticsUtil

- (instancetype)init{
  if(self = [super init]){
    [self accelerometerPull];

    //检查idfa的权限，ios14后需要用户授权才能获取
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
    NSLog(@"accelerometer invalidate");
    return;
  }

  if (![self.motionManager isGyroAvailable]) {
    NSLog(@"gyro invalidate");
    return;
  }

  // 3.开始更新
  [self.motionManager startAccelerometerUpdates];
  [self.motionManager startGyroUpdates];

}

//获取idfa
- (NSString *)getIdfa{
  return _idfa ? _idfa : @"";
}

//获取idfa
- (void)configIdfa{
  //需要延时，且当前app是活跃状态时，才可以弹出授权弹窗，否则可能取不到
  [NSTimer scheduledTimerWithTimeInterval:3.f repeats:true block:^(NSTimer * _Nonnull timer) {
      if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive){
          [timer invalidate];
          timer = nil;
          [ApAnalyticsUtil getIdfa:^(NSString * _Nonnull idfa) {
            self.idfa = idfa;
          }];
      }
  }];
}

//加速计数据
- (NSString *)getAccelerometerData{
    CMAcceleration acceleration = self.motionManager.accelerometerData.acceleration;
    NSLog(@"acceleration == x:%f, y:%f, z:%f", acceleration.x, acceleration.y, acceleration.z);
    return [NSString stringWithFormat:@"%f,%f,%f", acceleration.x, acceleration.y, acceleration.z];

}

//陀螺仪数据
- (NSString *)getGyroData{
    CMRotationRate rotationRate = self.motionManager.gyroData.rotationRate;
    NSLog(@"rotationRate == x:%f, y:%f, z:%f", rotationRate.x, rotationRate.y, rotationRate.z);
    return [NSString stringWithFormat:@"%f,%f,%f", rotationRate.x, rotationRate.y, rotationRate.z];
}

//判断是否设置了代理
- (BOOL)getProxyStatus {
    @try {
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
    } @catch (NSException *exception) {
        return NO;
    } @finally {

    }

}

//判断是否开启了vpn
- (BOOL)isVPNOn
{

    @try {
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
    } @catch (NSException *exception) {
        return false;
    } @finally {

    }

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
    }
    block(idfa);
  }
}

#pragma 获取总磁盘容量
+ (NSString *)getTotalDiskSize {
    @try {
        struct statfs buf;
        unsigned long long totalDiskSize = -1;
        if (statfs("/var", &buf) >= 0) {
          totalDiskSize = (unsigned long long)(buf.f_bsize * buf.f_blocks);
        }
        return [self fileSizeToString:totalDiskSize];
    } @catch (NSException *exception) {
        return @"";
    } @finally {

    }
}

#pragma 获取可用磁盘容量  f_bavail 已经减去了系统所占用的大小比 f_bfree 更准确
+ (NSString *)getAvailableDiskSize {
    @try {
        struct statfs buf;
        unsigned long long availableDiskSize = -1;
        if (statfs("/var", &buf) >= 0) {
          availableDiskSize = (unsigned long long)(buf.f_bsize * buf.f_bavail);
        }
        return [self fileSizeToString:availableDiskSize];
    } @catch (NSException *exception) {
        return @"";
    } @finally {

    }

}

+ (NSString *)fileSizeToString:(unsigned long long)fileSize {
    @try {

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
    } @catch (NSException *exception) {
        return @"";
    } @finally {

    }
}


///手机是否越狱
+ (BOOL)isJailBreak{
    @try {
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
    } @catch (NSException *exception) {
        return false;
    } @finally {

    }

}

//获取网络状态
+ (NSString *)getNetWorkInfo{

  return  @"";
//  NSString *networktype = @"";
//  NSArray *subviews = [[[[UIApplication sharedApplication] valueForKey:@"statusBar"] valueForKey:@"foregroundView"]subviews];
//  NSNumber *dataNetworkItemView = nil;
//  for (id subview in subviews) {
//    if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
//      dataNetworkItemView = subview;
//      break;
//    }
//  }
//
//  switch ([[dataNetworkItemView valueForKey:@"dataNetworkType"]integerValue]) {
//    case 0:
//      networktype = @"无服务";
//      break;
//
//    case 1:
//      networktype = @"2G";
//      break;
//
//    case 2:
//      networktype = @"3G";
//      break;
//
//    case 3:
//      networktype = @"4G";
//      break;
//
//    case 4:
//      networktype = @"LTE";
//      break;
//
//    case 5:
//      networktype = @"Wi-Fi";
//      break;
//    default:
//      break;
//  }
//  return networktype;
};

//获取运营商信息
+ (NSString *)getCarrierInfo{
    @try {
        CTTelephonyNetworkInfo *telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = [telephonyInfo subscriberCellularProvider];
        NSString *carrierName = [carrier carrierName];
        //    NSString *mcc = [carrier mobileCountryCode]; // 国家码 如：460
        //    NSString *mnc = [carrier mobileNetworkCode]; // 网络码 如：01
        //    NSString *isoCountryCode = [carrier isoCountryCode]; // cn
        //    BOOL allowsVOIP = [carrier allowsVOIP];// YES
        return carrierName ? carrierName : @"";
    } @catch (NSException *exception) {
        return @"";
    } @finally {

    }

};

//更新经纬度
- (void)updateLatitude:(NSString *)latitude longitude:(NSString *)longitude{
  self.latitude = latitude;
  self.longitude = longitude;
}

- (void)updateGpsAddress:(NSString *)country province:(NSString *)province region:(NSString *)region city:(NSString *)city{
  self.gpsCountry = country ?: @"";
  self.gpsProvince = province ?: @"";
  self.gpsRegion = region ?: @"";
  self.gpsCity = city ?: @"";
}

- (void)refreshCommonDeviceProperties{
  // Snapshot language/air_mode/root/gyro with existing iOS capabilities for Sensors public properties
  @try {
    NSArray *languageArray = [NSLocale preferredLanguages];
    self.snapLanguage = languageArray.count > 0 ? languageArray[0] : @"";
    self.snapTimezoneDisplayName = [ApAnalyticsUtil getTimezoneDisplayName];
    self.snapLatitude = self.latitude ?: @"";
    self.snapLongitude = self.longitude ?: @"";
    self.snapWifiSsid = @"";
    self.snapWifiBssid = @"";
    self.snapWifiMac = @"";
    self.snapWifiList = @"[]";
    self.snapAccelerationInfo = [self getAccelerometerData] ?: @"";
    self.snapGyroInfo = [self getGyroData] ?: @"";
    self.snapAirMode = NO; // No public iOS API; keep consistent with historical analytics behavior
    self.snapIsRoot = [ApAnalyticsUtil isJailBreak];
    self.commonPropsReady = YES;
  } @catch (NSException *exception) {
  }
}

- (NSString *)getCommonDevicePropertiesJson{
  if (!self.commonPropsReady) {
    [self refreshCommonDeviceProperties];
  }
  return [ApAnalyticsUtil dictionaryToJson:[self getCommonDevicePropertiesDictionary]] ?: @"{}";
}

- (NSDictionary *)getCommonDevicePropertiesDictionary{
  if (!self.commonPropsReady) {
    [self refreshCommonDeviceProperties];
  }
  NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithDictionary:@{
    @"language": self.snapLanguage ?: @"",
    @"timezone_display_name": self.snapTimezoneDisplayName ?: @"",
    // lat/long/GPS use live values (updated via updateLocation / updateGpsAddress)
    @"latitude": self.latitude ?: @"",
    @"Longitude": self.longitude ?: @"",
    @"GPS_country": self.gpsCountry ?: @"",
    @"GPS_province": self.gpsProvince ?: @"",
    @"GPS_region": self.gpsRegion ?: @"",
    @"GPS_city": self.gpsCity ?: @"",
    @"WIFI_SSID": self.snapWifiSsid ?: @"",
    @"WIFI_BSSID": self.snapWifiBssid ?: @"",
    @"WIFI_mac": self.snapWifiMac ?: @"",
    @"WIFI_LIST": self.snapWifiList ?: @"[]",
    @"acceleration_info": self.snapAccelerationInfo ?: @"",
    @"gyro_info": self.snapGyroInfo ?: @"",
    @"air_mode": @(self.snapAirMode),
    @"is_root": @(self.snapIsRoot),
    @"click_position_iscenter": @(self.snapClickPositionIsCenter),
  }];
  [ApAnalyticsUtil applyLanguageAndBootPropertiesToDictionary:properties];
  return [properties copy];
}

- (void)updateClickPositionIsCenter:(BOOL)isInCenter{
  self.snapClickPositionIsCenter = isInCenter;
}

//内网ip
+ (NSString *)IPAddress{
    @try {
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
    } @catch (NSException *exception) {
        return @"";
    } @finally {

    }

}

//获取可用内存
+(long long)getAvailableMemorySize
{
    @try {
        vm_statistics_data_t vmStats;
        mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
        kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
        if (kernReturn != KERN_SUCCESS)
        {
          return NSNotFound;
        }

        return ((vm_page_size * vmStats.free_count + vm_page_size * vmStats.inactive_count));
    } @catch (NSException *exception) {
        return 0;
    } @finally {

    }

}

//获取总内存
+(long long)getTotalMemorySize
{
  return [NSProcessInfo processInfo].physicalMemory;
}

//获取机型
+ (NSString *)getDeviceModel {
    @try {

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
    } @catch (NSException *exception) {
        return @"";
    } @finally {

    }

}

+ (NSString *)getTimezoneDisplayName {
  @try {
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    if (timeZone == nil) {
      return @"";
    }
    if (@available(iOS 10.0, *)) {
      NSString *localizedName = [timeZone localizedName:NSTimeZoneNameStyleStandard locale:[NSLocale currentLocale]];
      if (localizedName.length > 0) {
        return localizedName;
      }
    }
    NSString *name = [timeZone name];
    return name.length > 0 ? name : @"";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (long long)getBootTimestampMillis {
  @try {
    struct timeval boottime;
    size_t len = sizeof(boottime);
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    if (sysctl(mib, 2, &boottime, &len, NULL, 0) != 0) {
      return 0;
    }
    return (long long)boottime.tv_sec * 1000;
  } @catch (NSException *exception) {
    return 0;
  }
}

+ (NSString *)getBootTimeString {
  long long bootTimestampMillis = [self getBootTimestampMillis];
  if (bootTimestampMillis <= 0) {
    return @"";
  }
  NSDate *bootDate = [NSDate dateWithTimeIntervalSince1970:bootTimestampMillis / 1000.0];
  return [self getFormateLocalDate:bootDate] ?: @"";
}

+ (NSDictionary *)languageAndBootPropertyDictionary {
  NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:7];
  @try {
    NSLocale *locale = [NSLocale currentLocale];
    NSString *languageCode = @"";
    NSString *countryCode = @"";
    if (@available(iOS 10.0, *)) {
      languageCode = locale.languageCode ?: @"";
      countryCode = locale.countryCode ?: @"";
    } else {
      languageCode = [locale objectForKey:NSLocaleLanguageCode] ?: @"";
      countryCode = [locale objectForKey:NSLocaleCountryCode] ?: @"";
    }

    // iOS 无公开 ISO639-2 / ISO3166 alpha-3 API，采集不到传空
    [properties setObject:@"" forKey:@"language_iso3"];
    [properties setObject:countryCode forKey:@"language_country"];
    [properties setObject:@"" forKey:@"language_iso3_country"];
    [properties setObject:(languageCode.length > 0 ? ([locale displayNameForKey:NSLocaleLanguageCode value:languageCode] ?: @"") : @"") forKey:@"language_display"];
    [properties setObject:(countryCode.length > 0 ? ([locale displayNameForKey:NSLocaleCountryCode value:countryCode] ?: @"") : @"") forKey:@"language_display_country"];

    long long bootTimestampMillis = [self getBootTimestampMillis];
    if (bootTimestampMillis > 0) {
      [properties setObject:@(bootTimestampMillis) forKey:@"boot_timestamp"];
      [properties setObject:[self getBootTimeString] forKey:@"boot_time"];
    } else {
      [properties setObject:@"" forKey:@"boot_timestamp"];
      [properties setObject:@"" forKey:@"boot_time"];
    }
  } @catch (NSException *exception) {
    [properties setObject:@"" forKey:@"language_iso3"];
    [properties setObject:@"" forKey:@"language_country"];
    [properties setObject:@"" forKey:@"language_iso3_country"];
    [properties setObject:@"" forKey:@"language_display"];
    [properties setObject:@"" forKey:@"language_display_country"];
    [properties setObject:@"" forKey:@"boot_timestamp"];
    [properties setObject:@"" forKey:@"boot_time"];
  }
  return [properties copy];
}

+ (void)applyLanguageAndBootPropertiesToDictionary:(NSMutableDictionary *)dictionary {
  if (dictionary == nil) {
    return;
  }
  [[self languageAndBootPropertyDictionary] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [dictionary setObject:obj forKey:key];
  }];
  [[self miscCompliancePropertyDictionary] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [dictionary setObject:obj forKey:key];
  }];
  [[self screenCapabilityPropertyDictionary] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [dictionary setObject:obj forKey:key];
  }];
  [[self cpuDiskMemoryPropertyDictionary] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [dictionary setObject:obj forKey:key];
  }];
  [[self buildSystemHardwarePropertyDictionary] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [dictionary setObject:obj forKey:key];
  }];
  [[self environmentRiskPropertyDictionary] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [dictionary setObject:obj forKey:key];
  }];
  [[self versionChannelAppPropertyDictionary] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [dictionary setObject:obj forKey:key];
  }];
  [[self deviceFingerprintCollectTimePropertyDictionary] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [dictionary setObject:obj forKey:key];
  }];
}

+ (id)getBatteryIsChargingValue {
  @try {
    UIDeviceBatteryState state = [UIDevice currentDevice].batteryState;
    if (state == UIDeviceBatteryStateUnknown) {
      return @"";
    }
    return @(state == UIDeviceBatteryStateCharging || state == UIDeviceBatteryStateFull);
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (id)getAdidLimitTrackingEnableValue {
  @try {
    if (@available(iOS 14, *)) {
      ATTrackingManagerAuthorizationStatus status = [ATTrackingManager trackingAuthorizationStatus];
      if (status == ATTrackingManagerAuthorizationStatusNotDetermined) {
        return @"";
      }
      return @(status != ATTrackingManagerAuthorizationStatusAuthorized);
    }
    return @(![[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]);
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (NSDictionary *)miscCompliancePropertyDictionary {
  NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:14];
  @try {
    [properties setObject:[self getBatteryIsChargingValue] forKey:@"battery_is_charging"];
    [properties setObject:@"" forKey:@"user_agent"];
    [properties setObject:@"" forKey:@"oaid"];
    [properties setObject:@"" forKey:@"oaid_sdk_name"];
    [properties setObject:@"" forKey:@"oaid_support"];
    [properties setObject:@NO forKey:@"is_harmony_os"];
    [properties setObject:@"" forKey:@"harmony_os_version"];
    [properties setObject:@"" forKey:@"heap_size"];
    [properties setObject:@"" forKey:@"heap_start_size"];
    [properties setObject:@"" forKey:@"heap_growth_limit"];
    [properties setObject:[ApAnalyticsUtil getDeviceModel] ?: @"" forKey:@"market_name"];
    [properties setObject:@"model" forKey:@"market_name_type"];
    [properties setObject:[self getAdidLimitTrackingEnableValue] forKey:@"adid_limit_tracking_enable"];
  } @catch (NSException *exception) {
    [properties setObject:@"" forKey:@"battery_is_charging"];
    [properties setObject:@"" forKey:@"user_agent"];
    [properties setObject:@"" forKey:@"oaid"];
    [properties setObject:@"" forKey:@"oaid_sdk_name"];
    [properties setObject:@"" forKey:@"oaid_support"];
    [properties setObject:@NO forKey:@"is_harmony_os"];
    [properties setObject:@"" forKey:@"harmony_os_version"];
    [properties setObject:@"" forKey:@"heap_size"];
    [properties setObject:@"" forKey:@"heap_start_size"];
    [properties setObject:@"" forKey:@"heap_growth_limit"];
    [properties setObject:@"" forKey:@"market_name"];
    [properties setObject:@"" forKey:@"market_name_type"];
    [properties setObject:@"" forKey:@"adid_limit_tracking_enable"];
  }
  return [properties copy];
}

+ (NSString *)getScreenOrientationName {
  @try {
    UIInterfaceOrientation orientation = UIInterfaceOrientationUnknown;
    if (@available(iOS 13.0, *)) {
      NSSet *scenes = [UIApplication sharedApplication].connectedScenes;
      for (UIScene *scene in scenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
          orientation = ((UIWindowScene *)scene).interfaceOrientation;
          break;
        }
      }
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      orientation = [UIApplication sharedApplication].statusBarOrientation;
#pragma clang diagnostic pop
    }
    if (UIInterfaceOrientationIsPortrait(orientation)) {
      return @"portrait";
    }
    if (UIInterfaceOrientationIsLandscape(orientation)) {
      return @"landscape";
    }
    return @"";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (BOOL)hasTelephonySupport {
  NSString *model = [[UIDevice currentDevice] model];
  return model != nil && [model rangeOfString:@"iPhone"].location != NSNotFound;
}

+ (NSString *)getCameraCharacteristicsJson {
  @try {
    if (@available(iOS 10.0, *)) {
      AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession
          discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                                mediaType:AVMediaTypeVideo
                                 position:AVCaptureDevicePositionUnspecified];
      NSMutableArray *cameras = [NSMutableArray arrayWithCapacity:session.devices.count];
      for (AVCaptureDevice *device in session.devices) {
        [cameras addObject:@{
          @"position": @(device.position),
          @"modelID": device.modelID ?: @"",
          @"localizedName": device.localizedName ?: @""
        }];
      }
      return cameras.count > 0 ? ([self dataToJson:cameras] ?: @"") : @"";
    }
    return @"";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (NSDictionary *)screenCapabilityPropertyDictionary {
  NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:15];
  @try {
    UIScreen *screen = [UIScreen mainScreen];
    CGFloat scale = screen.scale;
    CGRect bounds = screen.bounds;
    CGFloat pixelWidth = bounds.size.width * scale;
    CGFloat pixelHeight = bounds.size.height * scale;

    [properties setObject:[NSString stringWithFormat:@"%.2f", scale] forKey:@"screen_density"];
    [properties setObject:[NSString stringWithFormat:@"%.0f", scale * 163.0] forKey:@"screen_density_dpi"];
    [properties setObject:[NSString stringWithFormat:@"%.0fx%.0f", pixelWidth, pixelHeight] forKey:@"resolution"];
    [properties setObject:[self getScreenOrientationName] forKey:@"screen_orientation"];
    [properties setObject:[NSString stringWithFormat:@"%.4f", screen.brightness] forKey:@"screen_brightness"];

    [properties setObject:@YES forKey:@"has_wifi"];
    [properties setObject:@([self hasTelephonySupport] || [CLLocationManager significantLocationChangeMonitoringAvailable]) forKey:@"has_gps"];
    if (@available(iOS 11.0, *)) {
      [properties setObject:@([NFCNDEFReaderSession readingAvailable]) forKey:@"has_nfc"];
    } else {
      [properties setObject:@NO forKey:@"has_nfc"];
    }
    [properties setObject:@NO forKey:@"has_nfc_host"];
    [properties setObject:@NO forKey:@"has_wifi_direct"];
    [properties setObject:@YES forKey:@"has_bluetooth"];
    [properties setObject:@([self hasTelephonySupport]) forKey:@"has_telephony"];
    [properties setObject:@NO forKey:@"has_otg"];
    [properties setObject:@NO forKey:@"has_aoa"];
    [properties setObject:[self getCameraCharacteristicsJson] forKey:@"camera_characteristics"];
  } @catch (NSException *exception) {
    [properties setObject:@"" forKey:@"screen_density"];
    [properties setObject:@"" forKey:@"screen_density_dpi"];
    [properties setObject:@"" forKey:@"resolution"];
    [properties setObject:@"" forKey:@"screen_orientation"];
    [properties setObject:@"" forKey:@"screen_brightness"];
    [properties setObject:@"" forKey:@"has_wifi"];
    [properties setObject:@"" forKey:@"has_gps"];
    [properties setObject:@"" forKey:@"has_nfc"];
    [properties setObject:@"" forKey:@"has_nfc_host"];
    [properties setObject:@"" forKey:@"has_wifi_direct"];
    [properties setObject:@"" forKey:@"has_bluetooth"];
    [properties setObject:@"" forKey:@"has_telephony"];
    [properties setObject:@"" forKey:@"has_otg"];
    [properties setObject:@"" forKey:@"has_aoa"];
    [properties setObject:@"" forKey:@"camera_characteristics"];
  }
  return [properties copy];
}

+ (long long)getTotalDiskSizeBytes {
  @try {
    struct statfs buf;
    if (statfs("/var", &buf) >= 0) {
      return (long long)(buf.f_bsize * buf.f_blocks);
    }
  } @catch (NSException *exception) {
  }
  return 0;
}

+ (long long)getAvailableDiskSizeBytes {
  @try {
    struct statfs buf;
    if (statfs("/var", &buf) >= 0) {
      return (long long)(buf.f_bsize * buf.f_bavail);
    }
  } @catch (NSException *exception) {
  }
  return 0;
}

+ (NSString *)getCpuArchitecture {
  @try {
    struct utsname systemInfo;
    if (uname(&systemInfo) != 0) {
      return @"";
    }
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding] ?: @"";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (NSString *)getCpuAbisJson {
  @try {
    NSString *architecture = [self getCpuArchitecture];
    if (architecture.length == 0) {
      return @"";
    }
    return [self dataToJson:@[architecture]] ?: @"";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (NSDictionary *)cpuDiskMemoryPropertyDictionary {
  NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:8];
  @try {
    [properties setObject:@"" forKey:@"cpu_abi"];
    [properties setObject:@"" forKey:@"cpu_abi2"];
    [properties setObject:[self getCpuAbisJson] forKey:@"cpu_abis"];
    [properties setObject:[self getCpuArchitecture] forKey:@"cpu_architecture"];
    [properties setObject:@"" forKey:@"cpu_serial"];

    long long cpuCores = [NSProcessInfo processInfo].processorCount;
    [properties setObject:cpuCores > 0 ? @(cpuCores) : @"" forKey:@"cpu_cores"];

    long long totalDisk = [self getTotalDiskSizeBytes];
    long long availableDisk = [self getAvailableDiskSizeBytes];
    if (totalDisk > 0 && availableDisk >= 0 && totalDisk >= availableDisk) {
      [properties setObject:@(totalDisk - availableDisk) forKey:@"disk_used_space"];
    } else {
      [properties setObject:@"" forKey:@"disk_used_space"];
    }

    long long totalMemory = [self getTotalMemorySize];
    long long availableMemory = [self getAvailableMemorySize];
    if (totalMemory > 0 && availableMemory > 0 && availableMemory <= totalMemory) {
      [properties setObject:@(totalMemory - availableMemory) forKey:@"memory_used"];
    } else {
      [properties setObject:@"" forKey:@"memory_used"];
    }
  } @catch (NSException *exception) {
    [properties setObject:@"" forKey:@"cpu_abi"];
    [properties setObject:@"" forKey:@"cpu_abi2"];
    [properties setObject:@"" forKey:@"cpu_abis"];
    [properties setObject:@"" forKey:@"cpu_architecture"];
    [properties setObject:@"" forKey:@"cpu_serial"];
    [properties setObject:@"" forKey:@"cpu_cores"];
    [properties setObject:@"" forKey:@"disk_used_space"];
    [properties setObject:@"" forKey:@"memory_used"];
  }
  return [properties copy];
}

+ (NSString *)getSystemUnameField:(const char *)field {
  @try {
    struct utsname systemInfo;
    if (uname(&systemInfo) != 0 || field == NULL) {
      return @"";
    }
    return [NSString stringWithUTF8String:field] ?: @"";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (NSString *)getSystemCharacteristicJson {
  @try {
    struct utsname systemInfo;
    if (uname(&systemInfo) != 0) {
      return @"";
    }
    NSDictionary *characteristic = @{
      @"sysname": [NSString stringWithUTF8String:systemInfo.sysname] ?: @"",
      @"nodename": [NSString stringWithUTF8String:systemInfo.nodename] ?: @"",
      @"release": [NSString stringWithUTF8String:systemInfo.release] ?: @"",
      @"version": [NSString stringWithUTF8String:systemInfo.version] ?: @"",
      @"machine": [NSString stringWithUTF8String:systemInfo.machine] ?: @"",
    };
    return [self dictionaryToJson:characteristic] ?: @"";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (void)applyEmptyBuildSystemHardwareProperties:(NSMutableDictionary *)properties {
  [properties setObject:@"" forKey:@"base_band_version"];
  [properties setObject:@"" forKey:@"board"];
  [properties setObject:@"" forKey:@"boot_loader"];
  [properties setObject:@"" forKey:@"finger_print"];
  [properties setObject:@"" forKey:@"display"];
  [properties setObject:@"" forKey:@"hardware"];
  [properties setObject:@"" forKey:@"host"];
  [properties setObject:@"" forKey:@"build_id"];
  [properties setObject:@"" forKey:@"device"];
  [properties setObject:@"" forKey:@"incremental"];
  [properties setObject:@"" forKey:@"radio_version"];
  [properties setObject:@"" forKey:@"characteristic"];
  [properties setObject:@"" forKey:@"signatures"];
  [properties setObject:@"" forKey:@"tags"];
  [properties setObject:@"" forKey:@"sys_build_time"];
  [properties setObject:@"" forKey:@"sys_build_type"];
  [properties setObject:@"" forKey:@"sys_build_user"];
  [properties setObject:@"" forKey:@"sys_code_name"];
}

+ (NSDictionary *)buildSystemHardwarePropertyDictionary {
  NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:18];
  @try {
    struct utsname systemInfo;
    if (uname(&systemInfo) != 0) {
      [self applyEmptyBuildSystemHardwareProperties:properties];
      return [properties copy];
    }

    NSString *machine = [NSString stringWithUTF8String:systemInfo.machine] ?: @"";
    NSString *release = [NSString stringWithUTF8String:systemInfo.release] ?: @"";
    NSString *version = [NSString stringWithUTF8String:systemInfo.version] ?: @"";
    NSString *nodename = [NSString stringWithUTF8String:systemInfo.nodename] ?: @"";

    [properties setObject:@"" forKey:@"base_band_version"];
    [properties setObject:machine forKey:@"board"];
    [properties setObject:@"" forKey:@"boot_loader"];
    [properties setObject:@"" forKey:@"finger_print"];
    [properties setObject:[[UIDevice currentDevice] systemVersion] ?: @"" forKey:@"display"];
    [properties setObject:machine forKey:@"hardware"];
    [properties setObject:nodename forKey:@"host"];
    [properties setObject:version forKey:@"build_id"];
    [properties setObject:machine forKey:@"device"];
    [properties setObject:@"" forKey:@"incremental"];
    [properties setObject:@"" forKey:@"radio_version"];
    [properties setObject:[self getSystemCharacteristicJson] forKey:@"characteristic"];
    [properties setObject:@"" forKey:@"signatures"];
    [properties setObject:@"" forKey:@"tags"];
    [properties setObject:@"" forKey:@"sys_build_time"];
    [properties setObject:@"" forKey:@"sys_build_type"];
    [properties setObject:@"" forKey:@"sys_build_user"];
    [properties setObject:release forKey:@"sys_code_name"];
  } @catch (NSException *exception) {
    [self applyEmptyBuildSystemHardwareProperties:properties];
  }
  return [properties copy];
}

+ (BOOL)isFirstLaunch {
  @try {
    NSString *key = @"ApAnalyticsHasLaunchedBefore";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:key]) {
      return NO;
    }
    [defaults setBool:YES forKey:key];
    return YES;
  } @catch (NSException *exception) {
    return NO;
  }
}

+ (BOOL)isGpsOpen {
  @try {
    return [CLLocationManager locationServicesEnabled];
  } @catch (NSException *exception) {
    return NO;
  }
}

+ (NSString *)getRootDescription {
  @try {
    return [self isJailBreak] ? @"jailbroken" : @"not_jailbroken";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (BOOL)isEmulator {
  @try {
#if TARGET_OS_SIMULATOR
    return YES;
#else
    NSString *model = [self getDeviceModel] ?: @"";
    return [model rangeOfString:@"Simulator" options:NSCaseInsensitiveSearch].location != NSNotFound;
#endif
  } @catch (NSException *exception) {
    return NO;
  }
}

+ (NSString *)getEmulatorDescription {
  @try {
    return [self isEmulator] ? @"simulator" : @"physical_device";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (BOOL)isDebuggerAttached {
  @try {
    int mib[4];
    struct kinfo_proc info;
    size_t size = sizeof(info);
    info.kp_proc.p_flag = 0;
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    if (sysctl(mib, 4, &info, &size, NULL, 0) != 0) {
      return NO;
    }
    return (info.kp_proc.p_flag & P_TRACED) != 0;
  } @catch (NSException *exception) {
    return NO;
  }
}

+ (BOOL)hasSuspiciousDylib {
  @try {
    uint32_t count = _dyld_image_count();
    NSArray *needles = @[@"Frida", @"frida", @"Substrate", @"cycript", @"SSLKillSwitch"];
    for (uint32_t i = 0; i < count; i++) {
      const char *name = _dyld_get_image_name(i);
      if (name == NULL) {
        continue;
      }
      NSString *imageName = [NSString stringWithUTF8String:name];
      for (NSString *needle in needles) {
        if ([imageName rangeOfString:needle].location != NSNotFound) {
          return YES;
        }
      }
    }
    return NO;
  } @catch (NSException *exception) {
    return NO;
  }
}

+ (BOOL)isHookDetected {
  @try {
    return [self isDebuggerAttached] || [self hasSuspiciousDylib];
  } @catch (NSException *exception) {
    return NO;
  }
}

+ (NSString *)getHookDescription {
  @try {
    NSMutableArray *reasons = [NSMutableArray arrayWithCapacity:2];
    if ([self isDebuggerAttached]) {
      [reasons addObject:@"debugger_attached"];
    }
    if ([self hasSuspiciousDylib]) {
      [reasons addObject:@"suspicious_dylib"];
    }
    if (reasons.count == 0) {
      return @"not_hooked";
    }
    return [reasons componentsJoinedByString:@","];
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (BOOL)isCloneApp {
  return NO;
}

+ (NSString *)getCloneDescription {
  @try {
    return [self isCloneApp] ? @"cloned_app" : @"normal_app";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (BOOL)isDebugBuildEnabled {
#if DEBUG
  return YES;
#else
  return NO;
#endif
}

+ (void)applyEmptyEnvironmentRiskProperties:(NSMutableDictionary *)properties {
  [properties setObject:@NO forKey:@"is_first_launch"];
  [properties setObject:@NO forKey:@"is_open_gps"];
  [properties setObject:@"" forKey:@"is_root_desc"];
  [properties setObject:@NO forKey:@"is_emulator"];
  [properties setObject:@"" forKey:@"is_emulator_desc"];
  [properties setObject:@NO forKey:@"is_hook"];
  [properties setObject:@"" forKey:@"is_hook_desc"];
  [properties setObject:@NO forKey:@"is_clone"];
  [properties setObject:@"" forKey:@"is_clone_desc"];
  [properties setObject:@NO forKey:@"enable_debug"];
  [properties setObject:@NO forKey:@"is_debug"];
  [properties setObject:@NO forKey:@"adb_enabled"];
  [properties setObject:@NO forKey:@"development_settings_enable"];
}

+ (NSDictionary *)environmentRiskPropertyDictionary {
  NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:13];
  @try {
    [properties setObject:@([self isFirstLaunch]) forKey:@"is_first_launch"];
    [properties setObject:@([self isGpsOpen]) forKey:@"is_open_gps"];
    [properties setObject:[self getRootDescription] forKey:@"is_root_desc"];
    [properties setObject:@([self isEmulator]) forKey:@"is_emulator"];
    [properties setObject:[self getEmulatorDescription] forKey:@"is_emulator_desc"];
    [properties setObject:@([self isHookDetected]) forKey:@"is_hook"];
    [properties setObject:[self getHookDescription] forKey:@"is_hook_desc"];
    [properties setObject:@([self isCloneApp]) forKey:@"is_clone"];
    [properties setObject:[self getCloneDescription] forKey:@"is_clone_desc"];
    [properties setObject:@([self isDebugBuildEnabled]) forKey:@"enable_debug"];
    [properties setObject:@([self isDebuggerAttached]) forKey:@"is_debug"];
    [properties setObject:@NO forKey:@"adb_enabled"];
    [properties setObject:@NO forKey:@"development_settings_enable"];
  } @catch (NSException *exception) {
    [self applyEmptyEnvironmentRiskProperties:properties];
  }
  return [properties copy];
}

+ (NSString *)getAppVersionCodeString {
  @try {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (NSString *)getAppName {
  @try {
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (name.length == 0) {
      name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    }
    return name ?: @"";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (NSString *)getManufacturerName {
  return @"Apple";
}

+ (NSString *)getProductName {
  @try {
    struct utsname systemInfo;
    if (uname(&systemInfo) != 0) {
      return @"";
    }
    return [NSString stringWithUTF8String:systemInfo.machine] ?: @"";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (NSString *)getDeviceNameValue {
  @try {
    return [[UIDevice currentDevice] name] ?: @"";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (id)getOsVersionIntValue {
  @try {
    if (@available(iOS 8.0, *)) {
      NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
      return @(version.majorVersion);
    }
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion] ?: @"";
    NSArray *components = [systemVersion componentsSeparatedByString:@"."];
    if (components.count > 0) {
      return @([components[0] integerValue]);
    }
    return @"";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (id)getAppVersionCodeValue {
  @try {
    NSString *versionCode = [self getAppVersionCodeString];
    if (versionCode.length == 0) {
      return @"";
    }
    return @([versionCode longLongValue]);
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (void)applyEmptyVersionChannelAppProperties:(NSMutableDictionary *)properties {
  [properties setObject:@"" forKey:@"app_version_code"];
  [properties setObject:@"" forKey:@"app_name"];
  [properties setObject:@"" forKey:@"manufacturer"];
  [properties setObject:@"" forKey:@"product"];
  [properties setObject:@"" forKey:@"device_name"];
  [properties setObject:@"" forKey:@"os_version_int"];
}

+ (NSDictionary *)versionChannelAppPropertyDictionary {
  NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:6];
  @try {
    [properties setObject:[self getAppVersionCodeValue] forKey:@"app_version_code"];
    [properties setObject:[self getAppName] forKey:@"app_name"];
    [properties setObject:[self getManufacturerName] forKey:@"manufacturer"];
    [properties setObject:[self getProductName] forKey:@"product"];
    [properties setObject:[self getDeviceNameValue] forKey:@"device_name"];
    [properties setObject:[self getOsVersionIntValue] forKey:@"os_version_int"];
  } @catch (NSException *exception) {
    [self applyEmptyVersionChannelAppProperties:properties];
  }
  return [properties copy];
}

static NSString * const kApAnalyticsClientIdGenerateTimestampKey = @"ApAnalyticsClientIdGenerateTimestamp";
static NSString * const kApAnalyticsClientIdGenerateTimeKey = @"ApAnalyticsClientIdGenerateTime";
static NSString * const kApAnalyticsClientIdLevelKey = @"ApAnalyticsClientIdLevel";
static NSString * const kApAnalyticsClientIdAlgorithmKey = @"ApAnalyticsClientIdAlgorithm";
static NSString * const kApAnalyticsFirstInitSdkTimestampKey = @"ApAnalyticsFirstInitSdkTimestamp";
static NSString * const kApAnalyticsFirstInitSdkTimeKey = @"ApAnalyticsFirstInitSdkTime";

+ (void)recordFirstSdkInitIfNeeded {
  @try {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:kApAnalyticsFirstInitSdkTimestampKey] != nil) {
      return;
    }
    NSDate *now = [NSDate date];
    long long timestamp = (long long)([now timeIntervalSince1970] * 1000.0);
    [defaults setObject:@(timestamp) forKey:kApAnalyticsFirstInitSdkTimestampKey];
    [defaults setObject:[self getFormateLocalDate:now] forKey:kApAnalyticsFirstInitSdkTimeKey];
  } @catch (NSException *exception) {
  }
}

+ (NSString *)getClientId {
  @try {
    NSString *clientId = [DeviceUID uid];
    if (clientId.length > 0) {
      return clientId;
    }
    clientId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return clientId ?: @"";
  } @catch (NSException *exception) {
    return @"";
  }
}

+ (void)ensureClientIdMetadataRecorded:(NSString *)clientId {
  @try {
    if (clientId.length == 0) {
      return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:kApAnalyticsClientIdGenerateTimestampKey] != nil) {
      return;
    }
    NSDate *now = [NSDate date];
    long long timestamp = (long long)([now timeIntervalSince1970] * 1000.0);
    NSString *algorithm = [[DeviceUID uid] length] > 0 ? @"device_uid" : @"idfv";
    [defaults setObject:@(timestamp) forKey:kApAnalyticsClientIdGenerateTimestampKey];
    [defaults setObject:[self getFormateLocalDate:now] forKey:kApAnalyticsClientIdGenerateTimeKey];
    [defaults setObject:@"app" forKey:kApAnalyticsClientIdLevelKey];
    [defaults setObject:algorithm forKey:kApAnalyticsClientIdAlgorithmKey];
  } @catch (NSException *exception) {
  }
}

+ (NSDictionary *)getClientIdMetadata {
  @try {
    NSString *clientId = [self getClientId];
    [self ensureClientIdMetadataRecorded:clientId];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *timestamp = [defaults objectForKey:kApAnalyticsClientIdGenerateTimestampKey];
    return @{
      @"cllient_id_generate_time": [defaults stringForKey:kApAnalyticsClientIdGenerateTimeKey] ?: @"",
      @"cllient_id_generate_timestan": timestamp ?: @"",
      @"cllient_id_level": [defaults stringForKey:kApAnalyticsClientIdLevelKey] ?: @"",
      @"cllient_id_generate_algorithn": [defaults stringForKey:kApAnalyticsClientIdAlgorithmKey] ?: @""
    };
  } @catch (NSException *exception) {
    return @{
      @"cllient_id_generate_time": @"",
      @"cllient_id_generate_timestan": @"",
      @"cllient_id_level": @"",
      @"cllient_id_generate_algorithn": @""
    };
  }
}

+ (NSDictionary *)getFirstInitSdkMetadata {
  @try {
    [self recordFirstSdkInitIfNeeded];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *timestamp = [defaults objectForKey:kApAnalyticsFirstInitSdkTimestampKey];
    return @{
      @"first_init_sdk_time": [defaults stringForKey:kApAnalyticsFirstInitSdkTimeKey] ?: @"",
      @"first_init_sdk_timestamp": timestamp ?: @""
    };
  } @catch (NSException *exception) {
    return @{
      @"first_init_sdk_time": @"",
      @"first_init_sdk_timestamp": @""
    };
  }
}

+ (void)applyEmptyDeviceFingerprintCollectTimeProperties:(NSMutableDictionary *)properties {
  [properties setObject:@"" forKey:@"client_id"];
  [properties setObject:@"" forKey:@"relation_client_id"];
  [properties setObject:@"" forKey:@"cllient_id_generate_time"];
  [properties setObject:@"" forKey:@"cllient_id_generate_timestan"];
  [properties setObject:@"" forKey:@"cllient_id_level"];
  [properties setObject:@"" forKey:@"cllient_id_generate_algorithn"];
  [properties setObject:@"" forKey:@"collect_time"];
  [properties setObject:@"" forKey:@"collect_timestamp"];
  [properties setObject:@"" forKey:@"server_time"];
  [properties setObject:@"" forKey:@"storage_time"];
  [properties setObject:@"" forKey:@"first_init_sdk_time"];
  [properties setObject:@"" forKey:@"first_init_sdk_timestamp"];
}

+ (NSDictionary *)deviceFingerprintCollectTimePropertyDictionary {
  NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:12];
  @try {
    NSString *clientId = [self getClientId];
    NSDictionary *clientIdMetadata = [self getClientIdMetadata];
    NSDictionary *firstInitMetadata = [self getFirstInitSdkMetadata];
    NSDate *now = [NSDate date];
    long long collectTimestamp = (long long)([now timeIntervalSince1970] * 1000.0);

    [properties setObject:clientId forKey:@"client_id"];
    [properties setObject:@"" forKey:@"relation_client_id"];
    [properties setObject:clientIdMetadata[@"cllient_id_generate_time"] forKey:@"cllient_id_generate_time"];
    [properties setObject:clientIdMetadata[@"cllient_id_generate_timestan"] forKey:@"cllient_id_generate_timestan"];
    [properties setObject:clientIdMetadata[@"cllient_id_level"] forKey:@"cllient_id_level"];
    [properties setObject:clientIdMetadata[@"cllient_id_generate_algorithn"] forKey:@"cllient_id_generate_algorithn"];
    [properties setObject:[self getFormateLocalDate:now] forKey:@"collect_time"];
    [properties setObject:@(collectTimestamp) forKey:@"collect_timestamp"];
    [properties setObject:@"" forKey:@"server_time"];
    [properties setObject:@"" forKey:@"storage_time"];
    [properties setObject:firstInitMetadata[@"first_init_sdk_time"] forKey:@"first_init_sdk_time"];
    [properties setObject:firstInitMetadata[@"first_init_sdk_timestamp"] forKey:@"first_init_sdk_timestamp"];
  } @catch (NSException *exception) {
    [self applyEmptyDeviceFingerprintCollectTimeProperties:properties];
  }
  return [properties copy];
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
  [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]]; // 确保不带 AM/PM
  [formatter setTimeZone:[NSTimeZone localTimeZone]];
  NSString *time_now = [formatter stringFromDate:date];
  return time_now;
}

//将本地日期字符串转为UTC日期字符串
+(NSString *)getUTCFormateLocalDate:(NSString *)localDate
{
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
  [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]]; // 确保不带 AM/PM
  [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
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

    @try {
        [dic setObject:[NSNumber numberWithBool:false] forKey:@"air_mode"];
        [dic setObject:[DeviceUID uid] forKey:@"android_id"];
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

        [dic setObject:[NSNumber numberWithBool:false] forKey:@"do_not_disturb"];

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
        [dic setObject:[ApAnalyticsUtil getTimezoneDisplayName] forKey:@"timezone_display_name"];
        [ApAnalyticsUtil applyLanguageAndBootPropertiesToDictionary:dic];

        [dic setObject:@"HIGH" forKey:@"location_type"];

        [dic setObject:@"" forKey:@"wifiMac"];
        [dic setObject:@"" forKey:@"mcc"];
        [dic setObject:@"" forKey:@"mcc2"];
        [dic setObject:@"" forKey:@"meid"];
        [dic setObject:@"" forKey:@"meid2"];

        [dic setObject:[NSString stringWithFormat:@"%lli",[ApAnalyticsUtil getAvailableMemorySize]] forKey:@"mem_avail"];
        [dic setObject:[NSString stringWithFormat:@"%lli",[ApAnalyticsUtil getTotalMemorySize]]forKey:@"men_total"];

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

        [dic setObject:[NSString stringWithFormat:@"%.2f",[UIScreen mainScreen].bounds.size.width] forKey:@"screen_width"];
        [dic setObject:[NSString stringWithFormat:@"%.2f",[UIScreen mainScreen].bounds.size.height] forKey:@"screen_height"];

        [dic setObject:@"" forKey:@"sdk_version"];
        [dic setObject:@"" forKey:@"serial_number"];
        [dic setObject:@"" forKey:@"user_uuid"];
        [dic setObject:@"" forKey:@"wifi_list"];
    } @catch (NSException *exception) {

    } @finally {

    }


  return [dic copy];
}

//配置当前的设备数据
- (NSDictionary *)getRealTimeDeviceData:(NSString *)runId{
  NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:1];

    @try {
        [dic setObject:[self getAccelerometerData] forKey:@"accelerate_info"];
        [dic setObject:[self getIdfa] forKey:@"advertising_id"];
        [dic setObject:@"" forKey:@"BatteryCapacity"];
        [dic setObject:[NSString stringWithFormat:@"%.f",  [[UIDevice currentDevice] batteryLevel] * 100] forKey:@"BatteryCapacityScale"];
        [dic setObject:@"" forKey:@"clipboard_with_text"];
        [dic setObject:[self getGyroData] forKey:@"gyro_info"];

        [dic setObject:self.latitude ? self.latitude : @"" forKey:@"latitude"];
        [dic setObject:self.longitude ? self.longitude : @"" forKey:@"longitude"];
        [dic setObject:self.gpsCountry ? self.gpsCountry : @"" forKey:@"GPS_country"];
        [dic setObject:self.gpsProvince ? self.gpsProvince : @"" forKey:@"GPS_province"];
        [dic setObject:self.gpsRegion ? self.gpsRegion : @"" forKey:@"GPS_region"];
        [dic setObject:self.gpsCity ? self.gpsCity : @"" forKey:@"GPS_city"];

        NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval time=[date timeIntervalSince1970]*1000;
        NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
        [dic setObject:[NSNumber numberWithLong:timeString.integerValue] forKey:@"local_time"];

        [dic setObject:@"" forKey:@"time_offset"];
        [dic setObject:[ApAnalyticsUtil getTimezoneDisplayName] forKey:@"timezone_display_name"];
        [ApAnalyticsUtil applyLanguageAndBootPropertiesToDictionary:dic];

        [dic setObject:runId forKey:@"run_id"];
    } @catch (NSException *exception) {


    } @finally {

    }


  return [dic copy];
}

//获取启动日志
- (NSDictionary *)getStartLog:(NSDate *)startTime{
  NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:1];

    @try {
        [dic setObject:@"start_event" forKey:@"action_type"];
        [dic setObject:@"" forKey:@"extra_data"];
        [dic setObject:@"native" forKey:@"log_source"];
        [dic setObject:[self getUid] forKey:@"user_uuid"];

        NSDate *date = [NSDate date];
        [dic setObject:[ApAnalyticsUtil getFormateLocalDate:date]  forKey:@"log_time"];
        [dic setObject:[ApAnalyticsUtil getUTCFormateLocalDate:[ApAnalyticsUtil getFormateLocalDate:date]] forKey:@"log_time_z"];

        [dic setObject:[ApAnalyticsUtil getFormateLocalDate:startTime] forKey:@"start_time"];
        [dic setObject:[ApAnalyticsUtil getUTCFormateLocalDate:[ApAnalyticsUtil getFormateLocalDate:startTime]] forKey:@"start_time_z"];
    } @catch (NSException *exception) {

    } @finally {

    }


  return [dic copy];
}


+ (NSString*)dictionaryToJson:(NSDictionary *)dic{

  NSError *parseError = nil;
  NSData  *jsonData = [NSJSONSerialization dataWithJSONObject:dic
                                                      options:NSJSONWritingPrettyPrinted
                                                        error:&parseError];
  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


+ (NSString*)dataToJson:(id )data{

  NSError *parseError = nil;
  NSData  *jsonData = [NSJSONSerialization dataWithJSONObject:data
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
    NSLog(@"json parse error：%@",err);
    return nil;
  }

  return dic;
}

@end


