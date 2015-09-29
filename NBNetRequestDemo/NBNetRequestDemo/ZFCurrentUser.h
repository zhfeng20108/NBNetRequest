//
//  ZFCurrentUser.h
//  NBNetRequestDemo
//
//  Created by ios_feng on 15/9/28.
//  Copyright © 2015年 feng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZFCurrentUser : NSObject
+ (instancetype)sharedInstance;
@property (nonatomic, assign) BOOL isLogin;
@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) NSString *userToken;
@end
