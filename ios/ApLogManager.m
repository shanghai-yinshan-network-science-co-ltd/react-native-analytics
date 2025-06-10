//
//  ApLogManager.m
//  adapundi
//
//  Created by liang zeng on 2022/3/15.
//

#import "ApLogManager.h"
#import "FMDB.h"
#import "ApAnalyticsUtil.h"
#import <UIKit/UIKit.h>
#import "ApNeworkManager.h"

@interface ApLogManager ()

//启动时间
@property (nonatomic, strong) NSDate *startTime;

//标记上传时间
@property (nonatomic, assign) NSTimeInterval lastTime;

//日志上传控制数
@property (nonatomic, assign) NSInteger logControlNum;

//标记当前是否正在发送日志，只允许日志串联发送
@property (nonatomic, assign)BOOL isSending;

//启动后的log日志数,做自加
@property (nonatomic, assign) NSInteger logNum;

//数据库
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) FMDatabase *db;
@property (nonatomic, strong) FMDatabaseQueue *dbQue;

//App启动后生成yyyyMMddHHmmssSSS_num
@property (nonatomic, copy) NSString *runId;


//工具类
@property (nonatomic, strong) ApAnalyticsUtil *util;

@property (nonatomic, copy) NSString *appListString;

@end

@implementation ApLogManager

- (instancetype)init{
  if(self == [super init]){
    self.lastTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970];
    self.logControlNum = 15;
    self.startTime = [NSDate date];
  }
  return self;
}

+ (instancetype)sharedInstance {
  static ApLogManager *_instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[self alloc] init];
    [_instance configDataBase];
    [_instance configTimerCheck];
    [_instance checkApplist];
  });
  return _instance;
}

- (void)configDataBase{
  if ([self.db open]) {
    BOOL result = [self.db executeUpdate:@"CREATE TABLE IF NOT EXISTS DeviceLogInfo (id integer PRIMARY KEY AUTOINCREMENT,runId text, deviceInfo text NOT NULL);"];
    if (result){
      NSLog(@"设备信息表创建成功");
      BOOL res = [self.db executeUpdate:@"INSERT INTO DeviceLogInfo (runId, deviceInfo) VALUES (?, ?);",self.runId, [ApAnalyticsUtil dictionaryToJson:[self.util getDeviceInfo]]];
      if (!res) {
        NSLog(@"增加数据失败");
      }else{
        NSLog(@"增加数据成功");
      }
    }else{
      NSLog(@"设备信息表创建失败");
    }
    result = [self.db executeUpdate:@"CREATE TABLE IF NOT EXISTS ActionLogInfo (id integer PRIMARY KEY AUTOINCREMENT,runId text, logId text NOT NULL, actionInfo Text);"];
    if (result){
      NSLog(@"行为日志表创建成功");
      NSString *logId = [self getCurrentLogId];
      BOOL res = [self.db executeUpdate:@"INSERT INTO ActionLogInfo (runId, logId, actionInfo) VALUES (?, ?, ?);",self.runId, logId,[ApAnalyticsUtil dictionaryToJson: [self.util getStartLog:self.startTime]]];
      if (!res) {
        NSLog(@"增加启动数据失败");
      }else{
        NSLog(@"增加启动数据成功");
      }
    }else{
      NSLog(@"行为日志表创建失败");
    }
  }
  [self.db close];
}

//设定15秒一次的上传策略
- (void)configTimerCheck{
  [self addActionLog:nil directUpload:true];
  [NSTimer scheduledTimerWithTimeInterval:15.f repeats:true block:^(NSTimer * _Nonnull timer) {
    if([self checkLogTime]){
      [self addActionLog:nil directUpload:true];
    }
  }];
}

- (void)checkApplist{
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    if(![bundleId isEqualToString:@"com.happy.cash"]){
        return;
    }


        NSArray *appInfos = @[
          @{
            @"appName":@"Maya",
            @"appBundleId": @"com.paymaya.ios",
            @"appScheme":@"paymaya://",
          },
          @{
            @"appName":@"gCash",
            @"appBundleId": @"com.globetel.gcash",
            @"appScheme":@"gcash://",
          },
          @{
            @"appName":@"Bpi",
            @"appBundleId": @"com.bpi.ng.app",
            @"appScheme":@"BPISchemes://",
          },
          @{
            @"appName":@"Gotyme",
            @"appBundleId": @"ph.com.gotyme",
            @"appScheme":@"gotyme://",
          },
          @{
            @"appName":@"GlobeOne",
            @"appBundleId": @"ph.com.globe.GlobeOneSuperApp",
            @"appScheme":@"globeone://",
          },
          @{
            @"appName":@"Paypal",
            @"appBundleId": @"com.yourcompany.PPClient",
            @"appScheme":@"paymaya://",
          },
          @{
            @"appName":@"Billease",
            @"appBundleId": @"com.billease",
            @"appScheme":@"billease://",
          },
          @{
            @"appName":@"JuanHand",
            @"appBundleId": @"com.finvovs.juanhand",
            @"appScheme":@"juanhand://",
          },
          @{
            @"appName":@"Coins",
            @"appBundleId": @"gctp.Coins",
            @"appScheme":@"coins://",
          },
          @{
            @"appName":@"币安",
            @"appBundleId": @"com.czzhao.binance",
            @"appScheme":@"bnc://",
          },
          @{
            @"appName":@"shopee",
            @"appBundleId": @"com.beeasy.shopee.ph",
            @"appScheme":@"shopeeph://",
          },
          @{
            @"appName":@"Tiktok",
            @"appBundleId": @"com.ss.iphone.ugc.Ame",
            @"appScheme":@"tiktok://",
          },
          @{
            @"appName":@"Lazada",
            @"appBundleId": @"com.LazadaSEA.Lazada",
            @"appScheme":@"Lazada://",
          },
          @{
            @"appName":@"TONIK",
            @"appBundleId": @"com.mobile.tonik",
            @"appScheme":@"tonikapp://",
          },
          @{
            @"appName":@"Cashalo",
            @"appBundleId": @"com.oriente.express.cashalo",
            @"appScheme":@"cashalo://",
          },
          @{
            @"appName":@"Skyro",
            @"appBundleId": @"io.breezeventures.mb",
            @"appScheme":@"skyro://",
          },
          @{
            @"appName":@"Spotify",
            @"appBundleId": @"com.spotify.client",
            @"appScheme":@"spotify://",
          },
          @{
            @"appName":@"foodpanda",
            @"appBundleId": @"com.global.foodpanda.ios",
            @"appScheme":@"foodpanda://",
          },
          @{
            @"appName":@"Facebook",
            @"appBundleId": @"com.facebook.Facebook",
            @"appScheme":@"fb://",
          },
          @{
            @"appName":@"Whatsapp",
            @"appBundleId": @"net.whatsapp.WhatsApp",
            @"appScheme":@"whatsApp://",
          },
          @{
            @"appName":@"UnionBank",
            @"appBundleId": @"com.unionbankph.online",
            @"appScheme":@"evgdysan://",
          },
          @{
            @"appName":@"Cash Mart Philippines",
            @"appBundleId": @"com.cashmart.cashmart",
            @"appScheme":@"fb174472730476253://",
          },
          @{
            @"appName":@"Tongi’s Go",
            @"appBundleId": @"com.tongitsgo.play",
            @"appScheme":@"tongitsgo://",
          },
          @{
            @"appName":@"Home Credit Online Loan App",
            @"appBundleId": @"ph.homecredit.capp",
            @"appScheme":@"line3rdp.ph.homecredit.capp://",
          },
          @{
            @"appName":@"Agoda",
            @"appBundleId": @"com.agoda.consumer",
            @"appScheme":@"agoda://",
          },
          @{
            @"appName":@"Jobstreet",
            @"appBundleId": @"com.jobstreet.jobstreet",
            @"appScheme":@"com.jobstreet.jobstreet://",
          },
          @{
            @"appName":@"Indeed",
            @"appBundleId": @"com.indeed.JobSearch",
            @"appScheme":@"indeedjobsearch://",
          },
          @{
            @"appName":@"AirAsia Move",
            @"appBundleId": @"com.airasia.mobile",
            @"appScheme":@"airasia://",
          },
          @{
            @"appName":@"Cebu Pacific",
            @"appBundleId": @"com.navitaire.nps.5j",
            @"appScheme":@"insidercebupacificuat://",
          },
          @{
            @"appName":@"Linkedin",
            @"appBundleId": @"com.linkedin.LinkedIn",
            @"appScheme":@"linkedin://",
          },

        @{
          @"appName":@"LANDBANK",
          @"appBundleId": @"com.landbank.mobilebanking",
          @"appScheme":@"landbank://",
        },
        @{
          @"appName":@"Digido",
          @"appBundleId": @"ph.digido.app",
          @"appScheme":@"digido://",
        },
        @{
          @"appName":@"EasyPeso",
          @"appBundleId": @"com.easypeso",
          @"appScheme":@"easypeso://",
        },
        @{
          @"appName":@"Hellomoney",
          @"appBundleId": @"com.aub.HelloMoney",
          @"appScheme":@"hellomoney://",
        },
        @{
          @"appName":@"Pesoloan",
          @"appBundleId": @"com.pesoloan",
          @"appScheme":@"pesoloan://",
        },



          @{
            @"appName":@"OwnBank",
            @"appBundleId": @"com.ownbank.app",
            @"appScheme":@"ownbank://",
          },
          @{
            @"appName":@"Octopus",
            @"appBundleId": @"com.octopuscards.octopus",
            @"appScheme":@"octopus://",
          },
          @{
            @"appName":@"Splitwise",
            @"appBundleId": @"com.Splitwise.SplitwiseMobile",
            @"appScheme":@"splitwise://",
          },
          @{
            @"appName":@"Chinabank",
            @"appBundleId": @"ph.chinabank.digital",
            @"appScheme":@"chinabank://",
          },
          @{
            @"appName":@"World app",
            @"appBundleId": @"org.worldcoin.insight",
            @"appScheme":@"worldapp://",
          },


          @{
            @"appName":@"IQ Option",
            @"appBundleId": @"com.trading.iqoption",
            @"appScheme":@"iqoption://",
          },
          @{
            @"appName":@"Moca",
            @"appBundleId": @"com.xlkash.mabilis.moca.loan",
            @"appScheme":@"moca://",
          },
          @{
            @"appName":@"Trust",
            @"appBundleId": @"com.sixdays.trust",
            @"appScheme":@"trust://",
          },
          @{
            @"appName":@"komo",
            @"appBundleId": @"ph.komo.app",
            @"appScheme":@"komo://",
          },
          @{
            @"appName":@"Taptapsend",
            @"appBundleId": @"com.taptapsend.TaptapSend",
            @"appScheme":@"taptapsend://",
          },

      @{
            @"appName":@"SweatWallet",
            @"appBundleId": @"com.sweateconomy.wallet",
            @"appScheme":@"sweat://",
          },
          @{
            @"appName":@"EasyLoan",
            @"appBundleId": @"mn.app.easyloan",
            @"appScheme":@"fb574404829945253://",
          },
          @{
            @"appName":@"MetaTrader 5",
            @"appBundleId": @"net.metaquotes.MetaTrader5Terminal",
            @"appScheme":@"metatrader5://",
          },
          @{
            @"appName":@"PH Sun Life",
            @"appBundleId": @"com.sunlife.ph.sunlifeph",
            @"appScheme":@"sunlifeph://",
          },
          @{
            @"appName":@"XM",
            @"appBundleId": @"com.xm.WebApp",
            @"appScheme":@"xm://",
          },



          @{
            @"appName":@"UnionDigital",
            @"appBundleId": @"ph.uniondigital.superapp",
            @"appScheme":@"ph.uniondigital.superapp://",
          },
          @{
            @"appName":@"Payoneer",
            @"appBundleId": @"com.Payoneer.PayoneerDevAdHoc",
            @"appScheme":@"payoneer.app.link://",
          },
          @{
            @"appName":@"DiskarTech",
            @"appBundleId": @"com.diskartech.mobile",
            @"appScheme":@"diskartechpx://",
          },
          @{
            @"appName":@"CBS Personal",
            @"appBundleId": @"com.cbs.mobilebanking",
            @"appScheme":@"chinabanksavings://",
          },
          @{
            @"appName":@"DirectLoan",
            @"appBundleId": @"com.megalink.directLoan",
            @"appScheme":@"dloan://",
          },



          @{
            @"appName":@"myTOYOTA",
            @"appBundleId": @"com.toyotawallet.ph",
            @"appScheme":@"toyota-wallet-ph://",
          },
          @{
            @"appName":@"U Mobile App",
            @"appBundleId": @"com.clearmindai.ussc.panalo.wallet",
            @"appScheme":@"fb678363717494134://",
          },
          @{
            @"appName":@"Cebuana Xpress",
            @"appBundleId": @"com.ncvi.cebxpress",
            @"appScheme":@"fb317513330114413://",
          },
          @{
            @"appName":@"OKX",
            @"appBundleId": @"com.okex.OKExAppstoreFull",
            @"appScheme":@"okex://",
          },
          @{
            @"appName":@"zukì",
            @"appBundleId": @"ph.com.sbfinance.zuki.customer",
            @"appScheme":@"ph.com.sbfinance.zuki.customer://",
          },


          @{
            @"appName":@"BanKo Mobile",
            @"appBundleId": @"com.banko.cm",
            @"appScheme":@"bankocm://",
          },
          @{
            @"appName":@"AUB",
            @"appBundleId": @"com.aub.mobile.AUBMobileBanking",
            @"appScheme":@"aubmobileapp://",
          },
          @{
            @"appName":@"eCebuana 2.0",
            @"appBundleId": @"com.ncvi.eCebuana2",
            @"appScheme":@"fb774871643140800://",
          },
          @{
            @"appName":@"Money Manager Expense & Budget",
            @"appBundleId": @"com.realbyteapps.MoneyManager2",
            @"appScheme":@"com.realbyteapps.MoneyManager2://",
          },
          @{
            @"appName":@"Advance",
            @"appBundleId": @"com.advanceph.mobile",
            @"appScheme":@"com.advanceph.mobile://",
          },



          @{
            @"appName":@"Lista",
            @"appBundleId": @"com.lista.ph",
            @"appScheme":@"com.lista.ph://",
          },
          @{
            @"appName":@"Wise",
            @"appBundleId": @"com.transferwise.Transferwise",
            @"appScheme":@"transferwise://",
          },
          @{
            @"appName":@"PayMe",
            @"appBundleId": @"io.attabot.paymeindia",
            @"appScheme":@"io.attabot.paymeindia://",
          },
          @{
            @"appName":@"western union",
            @"appBundleId": @"com.westernunion.track.location.finder.global",
            @"appScheme":@"wuapp://",
          },
          @{
            @"appName":@"PalawanPay",
            @"appBundleId": @"com.palawanpay.ewallet",
            @"appScheme":@"fb799208697589820://",
          },


          @{
            @"appName":@"My Sun Life PH",
            @"appBundleId": @"com.sunlifecorp.cpma.touchpoint.slocpi.ph",
            @"appScheme":@"com.sunlifecorp.cpma.touchpoint.slocpi.ph://",
          },
          @{
            @"appName":@"RCBC",
            @"appBundleId": @"com.rcbc.mobile",
            @"appScheme":@"com.rcbc.mobile.sit://",
          },
          @{
            @"appName":@"Hello Pag-IBIG",
            @"appBundleId": @"com.aub.HelloMoney.pagibig",
            @"appScheme":@"hellopagibig://",
          },
          @{
            @"appName":@"Budget",
            @"appBundleId": @"com.lightByte.Budget",
            @"appScheme":@"Budget://",
          },


        ];
        
    NSMutableArray * appsItems = [NSMutableArray arrayWithCapacity:1];
    [appInfos enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:obj[@"appScheme"]]]){
        NSLog(@"用户已安装%@",[obj description]);
        [appsItems addObject:@
         {
          @"appName":obj[@"appName"],
          @"packageName":obj[@"appBundleId"],
        }];
      }
    }];
    NSLog(@"appsItems====%@", appsItems);
    self.appListString = [ApAnalyticsUtil dataToJson:appsItems];
}


// 组装数据，上传日志
- (void)configDataSendLogs:(NSArray *)actions{
  if(self.isSending){
    return;
  }

  if(![[ApNeworkManager sharedInstance] checkUploadEnable]){
     return;
  }

  NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[self.util getRealTimeDeviceData:self.runId]];
  NSString *deviceInfo = [self getDeviceLogInfo:self.runId];
  NSDictionary *deviceInfoDic = [ApAnalyticsUtil dictionaryWithJsonString:deviceInfo];
  [deviceInfoDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
    [dic setObject:obj forKey:key];
  }];
  [dic setObject:actions forKey:@"logs"];
  [dic setObject:[self.util getUid] forKey:@"user_uuid"];
  if(self.appListString){
    [dic setObject:self.appListString forKey:@"applist_ios"];
    self.appListString = nil;
  }

  self.isSending = true;
  self.lastTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970];
  [[ApNeworkManager sharedInstance] sendLog:dic completionHandler:^(BOOL success) {
    self.isSending = false;
    if(success){
      [self deleteActionLogs:actions];
      [self addActionLog:nil directUpload:false];
    }
    else{
      //重试
      [self configDataSendLogs:actions];
    }
  }];
}

//检查距离上次上传是否超过15s
- (BOOL)checkLogTime{
  NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
  NSTimeInterval time=[date timeIntervalSince1970];
  if(time - _lastTime > 15){
    return true;
  }
  return false;
}

/*
 1:添加日志
 2:判断是否大于
 */
- (void)addActionLog:(NSString * )log directUpload:(BOOL)directUpload{
  [self.dbQue inDatabase:^(FMDatabase *db) {
    [db open];
    if(log){
      [db executeUpdate:@"INSERT INTO ActionLogInfo (runId, logId, actionInfo) VALUES (?, ?, ?);",self.runId,[self getCurrentLogId],log];
    }
    NSUInteger count = [db intForQuery:@"select count(*) from ActionLogInfo where runId = ?", self.runId];
    NSMutableArray *logItems = [NSMutableArray arrayWithCapacity:1];
    if (count >= self.logControlNum || directUpload){
      FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM ActionLogInfo where runId = \"%@\" limit %li", self.runId,self.logControlNum]];
      while ([resultSet next]) {
        NSString *logId = [resultSet stringForColumn:@"logId"];
        NSString *runId = [resultSet stringForColumn:@"runId"];
        NSString *actionInfo = [resultSet stringForColumn:@"actionInfo"];
        NSDictionary *actionDic = [ApAnalyticsUtil dictionaryWithJsonString:actionInfo];
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:actionDic ? actionDic : @{}];
        [dic setObject:logId forKey:@"log_id"];
        [dic setObject:runId forKey:@"runId"];
        [dic setObject:[self.util getUid] forKey:@"user_uuid"];
        [logItems addObject:dic];
      }
    }
    [db close];
    if(logItems.count > 0){
      [self configDataSendLogs:logItems];
    }
    else{
      NSLog(@"暂无日志上传");
    }
  }];
}

- (void)deleteActionLogs:(NSArray *)logs{
  [self.dbQue inDatabase:^(FMDatabase *db) {
    [db open];
    [logs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      NSString *sql = [NSString stringWithFormat:@"DELETE FROM ActionLogInfo WHERE logId = '%@'",obj[@"log_id"]];
      BOOL res = [db executeUpdate:sql];
      if(res){
        NSLog(@"行为数据删除成功");
      }
      else{
        NSLog(@"行为数据删除失败");
      }
    }];
    [db close];
  }];
}

- (NSString *)getDeviceLogInfo:(NSString *)runId{
  NSString *deviceInfo = @"";
  if([self.db open]) {
    FMResultSet *resultSet = [self.db executeQuery:@"SELECT * FROM DeviceLogInfo where runId = ?",runId];
    while ([resultSet next]) {
      deviceInfo = [resultSet stringForColumn:@"deviceInfo"];
    }
    [self.db close];
  }
  return deviceInfo;
}

#pragma mark public
//添加js透传的行为日志
- (void)addActionLog:(NSString *)log{
  [self addActionLog:log directUpload:false];
}

//更新位置
- (void)updateLatitude:(NSString *)latitude longitude:(NSString *)longitude{
  self.util.longitude = longitude;
  self.util.latitude = latitude;
}

//更新用户id
- (void)updateUserId:(NSString *)uId{
  self.util.uid = uId;
}


#pragma mark private

//生成logId
- (NSString *)getCurrentLogId {
  return [NSString stringWithFormat:@"%@_%li", self.runId, ++self.logNum];
}

#pragma mark getter

- (NSString *)filePath{
  if(!_filePath){
    NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    _filePath = [doc stringByAppendingPathComponent:@"userData.sqlite"];
  }
  return _filePath;
}

- (FMDatabase *)db{
  if(!_db){
    _db = [FMDatabase databaseWithPath:self.filePath];
  }
  return _db;
}

- (FMDatabaseQueue *)dbQue{
  if(!_dbQue){
    _dbQue = [FMDatabaseQueue databaseQueueWithPath:self.filePath];
  }
  return _dbQue;
}

- (NSString *)runId{
  if(!_runId){
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyyMMddHHmmss"];
    [format setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]]; // 确保不带 AM/PM
    [format setTimeZone:[NSTimeZone localTimeZone]];
    NSString *formatDateString = [format stringFromDate:[NSDate date]];
    _runId = [NSString stringWithFormat:@"%@_1", formatDateString];
  }
  return _runId;
}

- (ApAnalyticsUtil *)util{
  if(!_util){
    _util = [[ApAnalyticsUtil alloc] init];
  }
  return _util;
}

@end
