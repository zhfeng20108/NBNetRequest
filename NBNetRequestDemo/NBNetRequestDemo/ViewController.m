//
//  ViewController.m
//  NBNetRequestDemo
//
//  Created by ios_feng on 15/9/25.
//  Copyright © 2015年 feng. All rights reserved.
//

#import "ViewController.h"
#import "ZFNetRequest.h"
#import "ZFNetReuqestModel.h"
#import "ZFCurrentUser.h"
#import "NBNetworkConfig.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    ZFNetReuqestModel *requestModel = [ZFNetReuqestModel modelWithPath:@"/data/sk/101010100.html"];
    requestModel.requestMethod = NBNetRequestMethodGet;
    requestModel.useAccount = NO;
    requestModel.refreshCache = YES;
    [ZFNetRequest startWithRequestModel:requestModel completionBlockWithSuccess:^(NBBaseNetRequest *request) {
        NSLog(@"%@",[request responseJSONObject]);
        NSLog(@"%@",[request responseResultCode]);

        NSLog(@"%@",[request responseResultDictionary]);

        NSLog(@"%@",@([NBNetworkConfig sharedInstance].isLogin));
    } failure:^(NBBaseNetRequest *request) {
        NSLog(@"%@",request);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
