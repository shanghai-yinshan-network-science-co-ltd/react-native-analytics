//
//  ApAnalytics.m
//  adapundi
//
//  Created by liang zeng on 2022/3/22.
//

#import "ApAnalytics.h"
#import "ApNeworkManager.h"
#import "ApLogManager.h"

@implementation ApAnalytics

+ (void)configServer:(NSString *)serverUrl apiKey:(NSString *)apiKey{
  [[ApNeworkManager sharedInstance] configServer:serverUrl apiKey:apiKey];
  [ApLogManager sharedInstance];
}

@end
