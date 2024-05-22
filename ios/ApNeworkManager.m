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
    if(responseObject && [responseObject isKindOfClass: [NSDictionary class]] && [[responseObject objectForKey:@"status"] isEqualToString:@"OK"]){
      block(true);
    }
    else{
      block(false);
    }
  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    [self task:task failureData:error callback:^(NSDictionary *response) {
      block(false);
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
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        manager.responseSerializer.acceptableContentTypes=[[NSSet alloc] initWithObjects:@"application/xml", @"text/xml",@"text/html", @"application/json",@"text/plain",nil];

      _sessionManage =  manager;
    }
    return _sessionManage;
}


@end
