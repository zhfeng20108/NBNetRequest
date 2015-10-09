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
@implementation ZFNetReuqestModel
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.requestSerializerType = NBNetRequestSerializerTypeURL;//默认
        self.useCache = YES;
        self.cacheTimeInSeconds = 4*60*60;//4小时缓存
    }
    return self;
}
- (void)addCommonParams
{
    
}
@end
