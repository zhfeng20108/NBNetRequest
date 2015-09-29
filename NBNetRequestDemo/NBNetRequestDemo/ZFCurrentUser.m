//
//  ZFCurrentUser.m
//  NBNetRequestDemo
//
//  Created by ios_feng on 15/9/28.
//  Copyright © 2015年 feng. All rights reserved.
//

#import "ZFCurrentUser.h"
#import "NBNetworkConfig.h"
@implementation ZFCurrentUser
+ (instancetype)sharedInstance
{
    static ZFCurrentUser *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        [sharedInstance addObserver:sharedInstance forKeyPath:@"isLogin" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    });
    return sharedInstance;
}

/// 观察者模式
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    NSNumber *old = [change objectForKey:NSKeyValueChangeOldKey];
    NSNumber *new = [change objectForKey:NSKeyValueChangeNewKey];
    
    if ([old isEqual:new])
    {
        // No change in value - don't bother with any processing.
        return;
    }
    [NBNetworkConfig sharedInstance].isLogin = [new boolValue];
}

@end
