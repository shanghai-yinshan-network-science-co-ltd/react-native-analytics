//
//  ApAnalyticsModule.m
//  adapundi
//
//  Created by liang zeng on 2022/3/10.
//

#import "ApAnalyticsModule.h"
#import "ApLogManager.h"

@implementation ApAnalyticsModule
RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(sendBuriedData:(NSString *)data)
{
  [[ApLogManager sharedInstance] addActionLog:data];
}


RCT_EXPORT_METHOD(setUserId:(NSString *)useId)
{
  [[ApLogManager sharedInstance] updateUserId:useId];
}


RCT_EXPORT_METHOD(saveBusinessEvent:(NSString *)event)
{
  
}


RCT_EXPORT_METHOD(clearUserId:(NSString *)useId)
{
  [[ApLogManager sharedInstance] updateUserId:@""];
}


RCT_EXPORT_METHOD(setLatitude:(NSString *)latitude setLongitude:(NSString *)longitude)
{
  [[ApLogManager sharedInstance] updateLatitude:latitude longitude:longitude];
}

RCT_EXPORT_METHOD(updateGpsAddress:(NSString *)country province:(NSString *)province region:(NSString *)region city:(NSString *)city)
{
  [[ApLogManager sharedInstance] updateGpsAddress:country province:province region:region city:city];
}

RCT_EXPORT_METHOD(refreshCommonDeviceProperties)
{
  [[ApLogManager sharedInstance] refreshCommonDeviceProperties];
}

RCT_EXPORT_METHOD(updateClickPositionIsCenter:(BOOL)isInCenter)
{
  [[ApLogManager sharedInstance] updateClickPositionIsCenter:isInCenter];
}

RCT_EXPORT_METHOD(getCommonDeviceProperties:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  @try {
    NSString *json = [[ApLogManager sharedInstance] getCommonDevicePropertiesJson];
    resolve(json ?: @"{}");
  } @catch (NSException *exception) {
    reject(@"get_common_props_error", exception.reason, nil);
  }
}


@end
