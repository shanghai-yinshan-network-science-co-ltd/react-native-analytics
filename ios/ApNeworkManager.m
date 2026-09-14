//
//  ApAnalyticsManager.m
//  adapundi
//
//  Created by liang zeng on 2022/3/10.
//

#import "ApNeworkManager.h"
#import <GZIP/GZIP.h>
#import <UIKit/UIKit.h>
#import <AdSupport/AdSupport.h>
#import <AFNetworking/AFNetworking.h>

@interface ApNeworkManager (){
  NSString *serverUrl;
  NSString *apiKey;
}


@property (nonatomic ,strong) AFHTTPSessionManager *sessionManage;

- (void)sendEventTrigger:(NSDictionary *)dicData retry:(NSInteger)retry completionHandler:(void (^)(BOOL success))block;

@end

@implementation ApNeworkManager

+ (instancetype)sharedInstance {
  static ApNeworkManager *_instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[self alloc] init];
  });
  return _instance;
}

- (BOOL)checkUploadEnable{
   if(serverUrl && apiKey){
      return true;
   }
   return false;
}

//配置服务器地址和Apikey
- (void)configServer:(NSString *)server apiKey:(NSString *)key{
    serverUrl = server;
    apiKey = key;
}

//上传日志
- (void)sendLog:(NSDictionary *)dicData completionHandler:(void (^)(BOOL success))block{
  NSData *data = [NSJSONSerialization dataWithJSONObject:dicData options:NSJSONWritingPrettyPrinted error:nil];
  NSData *zipData = [data gzippedData];
  NSString *parameters = [zipData base64EncodedStringWithOptions:0];


  [[self sessionManage] POST:serverUrl parameters:@{@"content":parameters} headers:nil progress:^(NSProgress * _Nonnull uploadProgress) {
    NSLog(@"uploadProgress-->%@",uploadProgress);
  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    block(true);
  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    [self task:task failureData:error callback:^(NSDictionary *response) {
      block(false);
    }];
  }];
}

- (NSString *)eventTriggerUrl{
  if (serverUrl.length == 0) {
    return nil;
  }
  if ([serverUrl containsString:@"eventTrigger"]) {
    return serverUrl;
  }
  if ([serverUrl containsString:@"basicDeviceInfo"]) {
    return [serverUrl stringByReplacingOccurrencesOfString:@"basicDeviceInfo" withString:@"eventTrigger"];
  }
  NSURL *url = [NSURL URLWithString:serverUrl];
  if (!url) {
    return nil;
  }
  NSString *path = url.path ?: @"";
  NSString *newPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"eventTrigger"];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
  components.path = newPath;
  return components.URL.absoluteString;
}

+ (NSDictionary *)sanitizeEventTriggerPayload:(NSDictionary *)raw{
  static NSSet *omitKeys;
  static NSSet *typedKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    omitKeys = [NSSet setWithObjects:@"server_time", @"storage_time", @"outer_net_ip", nil];
    typedKeys = [NSSet setWithObjects:
                 @"event_timestamp", @"collect_timestamp", @"terminal_stay_duration",
                 @"network_duration_time", @"network_vpn_state",
                 @"vs_duration_time", @"vs_is_other_audio_playing", @"vs_secondary_audio",
                 @"vs_is_speakerphone_on", @"vs_is_wired_headset_on",
                 @"vs_is_bluetooth_sco", @"vs_is_bluetooth_sco_on",
                 @"did_duration_time",
                 @"sr_duration_time", @"sr_share_screen_size", @"sr_screen_recording",
                 @"env_duration_time", @"env_is_root", @"env_is_emulator", @"env_is_hook",
                 @"env_is_clone", @"env_enable_debug", @"env_is_debug",
                 @"env_adb_enabled", @"env_development_settings",
                 @"battery_duration_time", @"battery_charging",
                 @"notifi_duration_time", @"page_duration_time",
                 @"loc_duration_time", @"loc_locating_timestamp", @"loc_is_retry",
                 @"is_bridge",
                 nil];
  });
  if (![raw isKindOfClass:[NSDictionary class]]) {
    return @{};
  }
  NSMutableDictionary *out = [NSMutableDictionary dictionaryWithCapacity:raw.count];
  [raw enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    if (![key isKindOfClass:[NSString class]] || !obj || obj == [NSNull null]) {
      return;
    }
    if ([omitKeys containsObject:key]) {
      return;
    }
    if ([obj isKindOfClass:[NSString class]] && ((NSString *)obj).length == 0 && [typedKeys containsObject:key]) {
      return;
    }
    [out setObject:obj forKey:key];
  }];
  return [out copy];
}

- (void)sendEventTrigger:(NSDictionary *)dicData completionHandler:(void (^)(BOOL success))block{
  [self sendEventTrigger:dicData retry:0 completionHandler:block];
}

- (void)sendEventTrigger:(NSDictionary *)dicData retry:(NSInteger)retry completionHandler:(void (^)(BOOL success))block{
  NSString *url = [self eventTriggerUrl];
  if (url.length == 0 || ![dicData isKindOfClass:[NSDictionary class]]) {
    if (block) {
      block(NO);
    }
    return;
  }
  NSDictionary *payload = [[self class] sanitizeEventTriggerPayload:dicData];
  __weak typeof(self) weakSelf = self;
  [[self sessionManage] POST:url parameters:payload headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    if (block) {
      block(YES);
    }
  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    [weakSelf task:task failureData:error callback:^(NSDictionary *response) {
      if (retry < 2) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((retry + 1) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          [weakSelf sendEventTrigger:dicData retry:retry + 1 completionHandler:block];
        });
        return;
      }
      if (block) {
        block(NO);
      }
    }];
  }];
}

#pragma mark http methods

- (void)task:(NSURLSessionDataTask *)task failureData:(NSError *)error callback:(void (^)(NSDictionary *response))block{
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
    NSInteger statusCode = response.statusCode;
    NSLog(@"statusCode === %li \n error====%@",statusCode, [error description]);
    block(@{@"success":@0});
}

#pragma mark getter

- (AFHTTPSessionManager *)sessionManage{
    if(!_sessionManage){
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.operationQueue.maxConcurrentOperationCount = 1;

        manager.requestSerializer = [AFJSONRequestSerializer serializer]; // 上传普通格式
        manager.requestSerializer.timeoutInterval = 30.0f;

        [manager.requestSerializer setValue:apiKey forHTTPHeaderField:@"x-api-key"];
        [manager.requestSerializer setValue:@"iOS" forHTTPHeaderField:@"OS"];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        manager.responseSerializer.acceptableContentTypes=[[NSSet alloc] initWithObjects:@"application/xml", @"text/xml",@"text/html", @"application/json",@"text/plain",nil];

      _sessionManage =  manager;
    }
    return _sessionManage;
}


@end
