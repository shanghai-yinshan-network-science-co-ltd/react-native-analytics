
#import "RNAnalytics.h"
#import "ApLogManager.h"
#import "ApNeworkManager.h"

@implementation RNAnalytics

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()


RCT_EXPORT_METHOD(sendBuriedData:(NSString *)data)
{
  if([[ApNeworkManager sharedInstance] checkUploadEnable]){
    [[ApLogManager sharedInstance] addActionLog:data];
  }
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

