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


@end
