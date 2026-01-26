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

    if([bundleId isEqualToString:@"com.ys.credinex"]){
        NSArray *appInfos = @[
                    @{
                        @"appName":@"Blibli",
                        @"appBundleId": @"com.blibli.mobile",
                        @"appScheme":@"blibli://",
                    },
                    @{
                        @"appName":@"Shopeepay",
                        @"appBundleId": @"com.shopeepay.id",
                        @"appScheme":@"shopeepayid://",
                    },
                    @{
                        @"appName":@"Tokopedia",
                        @"appBundleId": @"com.tokopedia.Tokopedia",
                        @"appScheme":@"tokopedia://",
                    },

                    @{
                        @"appName":@"OVO",
                        @"appBundleId": @"ovo.id",
                        @"appScheme":@"ovo://",
                    },
            @{
                @"appName":@"Easycash",
                @"appBundleId": @"com.fintopia.investaja",
                @"appScheme":@"Easycash://",
            },
            @{
                @"appName":@"Adakami",
                @"appBundleId": @"com.adakami.loan",
                @"appScheme":@"adakami://",
            },
            @{
                @"appName":@"Kreditpintar",
                @"appBundleId": @"com.kreditpintar.ios",
                @"appScheme":@"kreditpintar://",
            },

            @{
                @"appName":@"Rupiah Cepat",
                @"appBundleId": @"com.nanobank.indonesian",
                @"appScheme":@"rupiahcepat://",
            },
            @{
                @"appName":@"Gopay",
                @"appBundleId": @"com.go-jek.gopay",
                @"appScheme":@"gopay://",
            },
            @{
                @"appName":@"Dana kini",
                @"appBundleId": @"com.dki.danakini",
                @"appScheme":@"com.dki.danakini://",
            },

            @{
                @"appName":@"Indodana Finance",
                @"appBundleId": @"com.indodana.ios.app",
                @"appScheme":@"indodanafinance://",
            },
            @{
                @"appName":@"kredivo",
                @"appBundleId": @"com.kredivo.ios",
                @"appScheme":@"kredivo://",
            },
            @{
                @"appName":@"kredito",
                @"appBundleId": @"com.kredito.app",
                @"appScheme":@"lepin://",
            },

            @{
                @"appName":@"UangMe",
                @"appBundleId": @"com.uangme.UangMeLender.indonesi",
                @"appScheme":@"fb1113811039296990://",
            },
            @{
                @"appName":@"JULO",
                @"appBundleId": @"id.co.julo.juloapp",
                @"appScheme":@"julo://",
            },
            @{
                @"appName":@"shopee",
                @"appBundleId": @"com.beeasy.shopee.id",
                @"appScheme":@"shopeeid://",
            },

            @{
                @"appName":@"UKU",
                @"appBundleId": @"mintech.com.uku",
                @"appScheme":@"uku://",
            },
            @{
                @"appName":@"Kredinesia",
                @"appBundleId": @"com.onecard.kredinesia",
                @"appScheme":@"evoke2a0a72244233402b0://",
            },
            @{
                @"appName":@"FINPLUS",
                @"appBundleId": @"com.app.fin.FINPLUS",
                @"appScheme":@"finplus://",
            },

            @{
                @"appName":@"Uatas",
                @"appBundleId": @"com.uatas.app.UATAS",
                @"appScheme":@"uatas://",
            },
            @{
                @"appName":@"Samir",
                @"appBundleId": @"com.samir.loan",
                @"appScheme":@"fb516479564764554://",
            },
            @{
                @"appName":@"KrediOne",
                @"appBundleId": @"com.itn.kredi360",
                @"appScheme":@"credit360://",
            },

            @{
                @"appName":@"KTA KILAT",
                @"appBundleId": @"com.ktakilat.pinjol.pinjaman.loan.dana",
                @"appScheme":@"ktakilat://",
            },
            @{
                @"appName":@"Pinjamin - Kredit Dana",
                @"appBundleId": @"com.pinjamwinwin",
                @"appScheme":@"PinjamwinwinScheme://",
            },
            @{
                @"appName":@"pinjamduit",
                @"appBundleId": @"com.pinjamduit.loan",
                @"appScheme":@"pinjamduit://",
            },

            @{
                @"appName":@"Pinjam Yuk",
                @"appBundleId": @"com.kkii.pinjam",
                @"appScheme":@"pinjamyuk://",
            },
            @{
                @"appName":@"AmarthaFin",
                @"appBundleId": @"com.amarthaplus.amarthabeyond",
                @"appScheme":@"amarthaplus.app://",
            },
            @{
                @"appName":@"akulaku",
                @"appBundleId": @"com.app.Akulaku",
                @"appScheme":@"akulaku://",
            },

            @{
                @"appName":@"Solusiku",
                @"appBundleId": @"co.Solusiku.Xiaoxinfen",
                @"appScheme":@"SKAppStore://",
            },
            @{
                @"appName":@"Bantusaku",
                @"appBundleId": @"com.smartec.ft",
                @"appScheme":@"bantusaku://",
            },
            @{
                @"appName":@"Cairin",
                @"appBundleId": @"com.iss.client.cairin",
                @"appScheme":@"cairin://",
            },



            @{
                @"appName":@"myBCA",
                @"appBundleId": @"com.bca.mybca.omni",
                @"appScheme":@"mybcamb://",
            },
            @{
                @"appName":@"YUP",
                @"appBundleId": @"com.finture.yup",
                @"appScheme":@"yup://",
            },

            @{
                @"appName":@"Atome",
                @"appBundleId": @"id.atome.paylater",
                @"appScheme":@"atomeid://",
            },
            @{
                @"appName":@"Traveloka",
                @"appBundleId": @"com.traveloka.traveloka",
                @"appScheme":@"traveloka://",
            },
            @{
                @"appName":@"Gojek",
                @"appBundleId": @"com.go-jek.ios",
                @"appScheme":@"gojek://",
            },
            @{
                @"appName":@"Homecredit",
                @"appBundleId": @"id.co.myhomecredi",
                @"appScheme":@"applinks://",
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

    if([bundleId isEqualToString:@"com.yinshan.adapundi"]){
        NSArray *appInfos = @[
            @{
                @"appName":@"Easycash",
                @"appBundleId": @"com.fintopia.investaja",
                @"appScheme":@"Easycash://",
            },
            @{
                @"appName":@"Adakami",
                @"appBundleId": @"com.adakami.loan",
                @"appScheme":@"adakami://",
            },
            @{
                @"appName":@"Kreditpintar",
                @"appBundleId": @"com.kreditpintar.ios",
                @"appScheme":@"kreditpintar://",
            },

            @{
                @"appName":@"Rupiah Cepat",
                @"appBundleId": @"com.nanobank.indonesian",
                @"appScheme":@"rupiahcepat://",
            },
            @{
                @"appName":@"Gopay",
                @"appBundleId": @"com.go-jek.gopay",
                @"appScheme":@"gopay://",
            },
            @{
                @"appName":@"Dana kini",
                @"appBundleId": @"com.dki.danakini",
                @"appScheme":@"com.dki.danakini://",
            },

            @{
                @"appName":@"Indodana Finance",
                @"appBundleId": @"com.indodana.ios.app",
                @"appScheme":@"indodanafinance://",
            },
            @{
                @"appName":@"kredivo",
                @"appBundleId": @"com.kredivo.ios",
                @"appScheme":@"kredivo://",
            },
            @{
                @"appName":@"kredito",
                @"appBundleId": @"com.kredito.app",
                @"appScheme":@"lepin://",
            },

            @{
                @"appName":@"UangMe",
                @"appBundleId": @"com.uangme.UangMeLender.indonesi",
                @"appScheme":@"fb1113811039296990://",
            },
            @{
                @"appName":@"JULO",
                @"appBundleId": @"id.co.julo.juloapp",
                @"appScheme":@"julo://",
            },
            @{
                @"appName":@"shopee",
                @"appBundleId": @"com.beeasy.shopee.id",
                @"appScheme":@"shopeeid://",
            },

            @{
                @"appName":@"UKU",
                @"appBundleId": @"mintech.com.uku",
                @"appScheme":@"uku://",
            },
            @{
                @"appName":@"Kredinesia",
                @"appBundleId": @"com.onecard.kredinesia",
                @"appScheme":@"evoke2a0a72244233402b0://",
            },
            @{
                @"appName":@"FINPLUS",
                @"appBundleId": @"com.app.fin.FINPLUS",
                @"appScheme":@"finplus://",
            },

            @{
                @"appName":@"Uatas",
                @"appBundleId": @"com.uatas.app.UATAS",
                @"appScheme":@"uatas://",
            },
            @{
                @"appName":@"Samir",
                @"appBundleId": @"com.samir.loan",
                @"appScheme":@"fb516479564764554://",
            },
            @{
                @"appName":@"KrediOne",
                @"appBundleId": @"com.itn.kredi360",
                @"appScheme":@"credit360://",
            },

            @{
                @"appName":@"KTA KILAT",
                @"appBundleId": @"com.ktakilat.pinjol.pinjaman.loan.dana",
                @"appScheme":@"ktakilat://",
            },
            @{
                @"appName":@"Pinjamin - Kredit Dana",
                @"appBundleId": @"com.pinjamwinwin",
                @"appScheme":@"PinjamwinwinScheme://",
            },
            @{
                @"appName":@"pinjamduit",
                @"appBundleId": @"com.pinjamduit.loan",
                @"appScheme":@"pinjamduit://",
            },

            @{
                @"appName":@"Pinjam Yuk",
                @"appBundleId": @"com.kkii.pinjam",
                @"appScheme":@"pinjamyuk://",
            },
            @{
                @"appName":@"AmarthaFin",
                @"appBundleId": @"com.amarthaplus.amarthabeyond",
                @"appScheme":@"amarthaplus.app://",
            },
            @{
                @"appName":@"akulaku",
                @"appBundleId": @"com.app.Akulaku",
                @"appScheme":@"akulaku://",
            },

            @{
                @"appName":@"Solusiku",
                @"appBundleId": @"co.Solusiku.Xiaoxinfen",
                @"appScheme":@"SKAppStore://",
            },
            @{
                @"appName":@"Bantusaku",
                @"appBundleId": @"com.smartec.ft",
                @"appScheme":@"bantusaku://",
            },
            @{
                @"appName":@"Cairin",
                @"appBundleId": @"com.iss.client.cairin",
                @"appScheme":@"cairin://",
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



    if([bundleId isEqualToString:@"com.happy.cash"]){
        NSArray *appInfos = @[
            // 借贷类
            @{
                @"appName":@"Billease",
                @"appBundleId": @"com.billease",
                @"appScheme":@"billease://",
            },
            @{
                @"appName":@"Home Credit Online Loan App",
                @"appBundleId": @"ph.homecredit.capp",
                @"appScheme":@"line3rdp.ph.homecredit.capp://",
            },
            @{
                @"appName":@"Salmon",
                @"appBundleId": @"com.fhl.ios.salmon",
                @"appScheme":@"salmon://",
            },
            @{
                @"appName":@"JuanHand",
                @"appBundleId": @"com.finvovs.juanhand",
                @"appScheme":@"juanhand://",
            },
            @{
                @"appName":@"Cashalo",
                @"appBundleId": @"com.oriente.express.cashalo",
                @"appScheme":@"cashalo://",
            },
            @{
                @"appName":@"Pesoloan",
                @"appBundleId": @"com.pesoloan",
                @"appScheme":@"pesoloan://",
            },
            @{
                @"appName":@"TalaCredit",
                @"appBundleId": @"tala.TalaCredit.deaoo",
                @"appScheme":@"talacredit://",
            },
            @{
                @"appName":@"Skyro",
                @"appBundleId": @"io.breezeventures.mb",
                @"appScheme":@"skyro://",
            },
            @{
                @"appName":@"Cash Mart Philippines",
                @"appBundleId": @"com.cashmart.cashmart",
                @"appScheme":@"fb174472730476253://",
            },
            @{
                @"appName":@"Tekcash",
                @"appBundleId": @"ph.tekwanglending.tekcash",
                @"appScheme":@"tekcash://",
            },
            @{
                @"appName":@"Mega Peso",
                @"appBundleId": @"com.cfiph.megapeso.credit",
                @"appScheme":@"megapeso://",
            },
            @{
                @"appName":@"Mocasa",
                @"appBundleId": @"com.mocasa.ph",
                @"appScheme":@"mocasa://",
            },
            @{
                @"appName":@"Pesos.ph",
                @"appBundleId": @"com.peso.loan.cash",
                @"appScheme":@"pesos://",
            },
            @{
                @"appName":@"FT Lending",
                @"appBundleId": @"com.ftlending.fast.cash.loan",
                @"appScheme":@"ftlending://",
            },
            @{
                @"appName":@"Fidoph Philippines",
                @"appBundleId": @"ph.fido.fidoph",
                @"appScheme":@"fidoph://",
            },
            @{
                @"appName":@"DS Credit",
                @"appBundleId": @"ds.cardist.doem.app",
                @"appScheme":@"dscredit://",
            },
            @{
                @"appName":@"Moca",
                @"appBundleId": @"com.agidream",
                @"appScheme":@"moca://",
            },
            // 电子钱包
            @{
                @"appName":@"gCash",
                @"appBundleId": @"com.globetel.gcash",
                @"appScheme":@"gcash://",
            },
            // 电商平台
            @{
                @"appName":@"shopee",
                @"appBundleId": @"com.beeasy.shopee.ph",
                @"appScheme":@"shopeeph://",
            },
            // 国际支付
            @{
                @"appName":@"Paypal",
                @"appBundleId": @"com.yourcompany.PPClient",
                @"appScheme":@"paypal://",
            },
            // 电子钱包
            @{
                @"appName":@"Maya",
                @"appBundleId": @"com.paymaya.ios",
                @"appScheme":@"paymaya://",
            },
            // 农村银行
            @{
                @"appName":@"RCBC DiskarTech Savings",
                @"appBundleId": @"com.diskartech.mobile",
                @"appScheme":@"diskartechpx://",
            },
            // 社保服务
            @{
                @"appName":@"MySSS",
                @"appBundleId": @"com.sss.gov.mysss.mobileapp",
                @"appScheme":@"mysss://",
            },
            // 数字银行
            @{
                @"appName":@"MariBank PH",
                @"appBundleId": @"ph.seabank.seabank",
                @"appScheme":@"maribank://",
            },
            // 求职
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
            // 住房基金
            @{
                @"appName":@"Virtual Pag-IBIG",
                @"appBundleId": @"com.pagibigfund.virtualpagibigapp",
                @"appScheme":@"virtualpagibig://",
            },
            // 银行
            @{
                @"appName":@"BDO Online",
                @"appBundleId": @"com.bdo.newdigital",
                @"appScheme":@"bdo://",
            },
            // 财务管理App
            @{
                @"appName":@"Spending Tracker",
                @"appBundleId": @"com.lightByte.Budget",
                @"appScheme":@"Budget://",
            },
            @{
                @"appName":@"Money Manager",
                @"appBundleId": @"com.realbyteapps.MoneyManager",
                @"appScheme":@"moneymanager://",
            },
            // 电商平台
            @{
                @"appName":@"Lazada",
                @"appBundleId": @"com.LazadaSEA.Lazada",
                @"appScheme":@"Lazada://",
            },
            // 外卖平台
            @{
                @"appName":@"foodpanda",
                @"appBundleId": @"com.global.foodpanda.ios",
                @"appScheme":@"foodpanda://",
            },
            // Globe电信的金融服务
            @{
                @"appName":@"GlobeOne",
                @"appBundleId": @"ph.com.globe.GlobeOneSuperApp",
                @"appScheme":@"globeone://",
            },
            // 数字银行
            @{
                @"appName":@"Gotyme",
                @"appBundleId": @"ph.com.gotyme",
                @"appScheme":@"gotyme://",
            },
            // 银行
            @{
                @"appName":@"Bpi",
                @"appBundleId": @"com.bpi.ng.app",
                @"appScheme":@"BPISchemes://",
            },
            @{
                @"appName":@"UnionBank",
                @"appBundleId": @"com.unionbankph.online",
                @"appScheme":@"evgdysan://",
            },
            // 数字银行
            @{
                @"appName":@"TONIK",
                @"appBundleId": @"com.mobile.tonik",
                @"appScheme":@"tonikapp://",
            },
            // 酒店预订
            @{
                @"appName":@"Agoda",
                @"appBundleId": @"com.agoda.consumer",
                @"appScheme":@"agoda://",
            },
            // 太平洋航空
            @{
                @"appName":@"Cebu Pacific",
                @"appBundleId": @"com.navitaire.nps.5j",
                @"appScheme":@"insidercebupacificuat://",
            },
            // 银行
            @{
                @"appName":@"LANDBANK",
                @"appBundleId": @"com.landbank.mobilebanking",
                @"appScheme":@"landbank://",
            },
            // 高利贷/欺诈性贷款
            @{
                @"appName":@"PesoKing-mabilis cash loan app",
                @"appBundleId": @"com.king.peso.star",
                @"appScheme":@"pesoking://",
            },
            // 在线博彩
            @{
                @"appName":@"BingoPlus",
                @"appBundleId": @"Solidleisure.BingoPlus.iosC66.release",
                @"appScheme":@"bingoplus://",
            },
            // 高利贷
            @{
                @"appName":@"KuhaCash -loan app philippines",
                @"appBundleId": @"com.crown-infinity-lending.kuha.cash",
                @"appScheme":@"kuhacash://",
            },
            @{
                @"appName":@"Pera Cash-Quick Peso Loan App",
                @"appBundleId": @"com.ca.peracash",
                @"appScheme":@"peracash://",
            },
            @{
                @"appName":@"PlayTime",
                @"appBundleId": @"com.playmate.playtime",
                @"appScheme":@"playtime://",
            },
            // 越狱工具
            @{
                @"appName":@"Sileo",
                @"appBundleId": @"org.coolstar.sileo",
                @"appScheme":@"sileo://",
            },
            @{
                @"appName":@"Zebra",
                @"appBundleId": @"xyz.willy.Zebra",
                @"appScheme":@"zbra://",
            },
            @{
                @"appName":@"Cydia",
                @"appBundleId": @"com.saurik.Cydia",
                @"appScheme":@"cydia://",
            },
            @{
                @"appName":@"Installer 5",
                @"appBundleId": @"me.apptapp.installer",
                @"appScheme":@"installer://",
            },
            @{
                @"appName":@"Tenorshare 4uKey",
                @"appBundleId": @"com.tenorshare.4ukey",
                @"appScheme":@"4ukey://",
            },
            // 亚航
            @{
                @"appName":@"AirAsia Move",
                @"appBundleId": @"com.airasia.mobile",
                @"appScheme":@"airasia://",
            },
            // 数字钱包
            @{
                @"appName":@"Coins",
                @"appBundleId": @"gctp.Coins",
                @"appScheme":@"coins://",
            },
            // 费用分摊管理
            @{
                @"appName":@"Splitwise",
                @"appBundleId": @"com.Splitwise.SplitwiseMobile",
                @"appScheme":@"splitwise://",
            },
            // 银行
            @{
                @"appName":@"komo",
                @"appBundleId": @"ph.komo.app",
                @"appScheme":@"komo://",
            },
            @{
                @"appName":@"OwnBank",
                @"appBundleId": @"com.ownbank.app",
                @"appScheme":@"ownbank://",
            },
            // 全球跨境支付
            @{
                @"appName":@"Taptapsend",
                @"appBundleId": @"com.taptapsend.TaptapSend",
                @"appScheme":@"taptapsend://",
            },
            // 商业银行
            @{
                @"appName":@"Hellomoney",
                @"appBundleId": @"com.aub.HelloMoney",
                @"appScheme":@"hellomoney://",
            },
            @{
                @"appName":@"PayMe",
                @"appBundleId": @"com.kinetic.payme.app",
                @"appScheme":@"payme://",
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

//直接上传日志
- (void)uploadLogImmediately{
  [self addActionLog:nil directUpload:true];
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
