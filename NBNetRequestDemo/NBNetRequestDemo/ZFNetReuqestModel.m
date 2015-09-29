//
//  ZFNetReuqestModel.m
//  NBNetRequestDemo
//
//  Created by ios_feng on 15/9/28.
//  Copyright © 2015年 feng. All rights reserved.
//

#import "ZFNetReuqestModel.h"
#import "NBNetworkConfig.h"
#import "ZFCurrentUser.h"
#import <CocoaSecurity/CocoaSecurity.h>
@implementation ZFNetReuqestModel
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.requestSerializerType = NBNetRequestSerializerTypeURL;//默认
        self.cacheTimeInSeconds = 4*60*60;//4小时缓存
    }
    return self;
}
- (void)addCommonParams
{
    NSMutableDictionary *muDic = [NSMutableDictionary dictionary];
    if ([self.requestArgument isKindOfClass:[NSDictionary class]]) {
        [muDic addEntriesFromDictionary:self.requestArgument];
    }
    if (self.useAccount && [ZFCurrentUser sharedInstance].isLogin &&  [ZFCurrentUser sharedInstance].userToken) {
        [muDic setValue:[ZFCurrentUser sharedInstance].userToken forKey:@"session"];
        [muDic setValue:[ZFCurrentUser sharedInstance].uid forKey:@"uid"];
    }
    //添加uid
    [muDic setValue:@"2132312312" forKey:@"uiniqueid"];
    //添加timestamp
    NSDate *nowDate = [NSDate date];
    NSDateFormatter *outFormat = [[NSDateFormatter alloc] init];
    [outFormat setLocale:[NSLocale currentLocale]];
    [outFormat setDateFormat:@"yyyyMMddHHmmss"];
    NSString *timeStr = [outFormat stringFromDate:nowDate];
    [muDic setValue:timeStr forKey:@"timestamp"];
    
    //计算签名
    NSArray *arrKeyOrdered = [[muDic allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1  compare:obj2];
    }];
    NSMutableString *muStr = [NSMutableString stringWithString:@""];
    for (NSString *key in arrKeyOrdered) {
        [muStr appendFormat:@"%@%@",key,[muDic objectForKey:key]];
    }
    //签名
    [muDic setValue:[CocoaSecurity md5:muStr].hex forKey:@"sign"];
    self.requestArgument = muDic;
}
@end
