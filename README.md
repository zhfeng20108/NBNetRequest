# NBNetRequest
A network based on AFNetworking 3.0

# Installation
```ruby
target 'TargetName' do
pod 'NBNetRequest'
end
```

# 使用
```objective-c
	//配置
    [[NBNetworkConfig sharedInstance] setBaseUrl:@"http://www.weather.com.cn"];
    [[NBNetworkConfig sharedInstance] setResponseCodeKey:nil];
    [[NBNetworkConfig sharedInstance] setResponseDataKey:@"weatherinfo"];

    //ZFNetReuqestModel是NBBaseNetRequestModel的子类化，可自定义适合当前项目的信息
    ZFNetReuqestModel *requestModel = [ZFNetReuqestModel modelWithPath:@"/data/sk/101010100.html"];
    requestModel.requestMethod = NBNetRequestMethodGet;
    requestModel.useAccount = NO;
    requestModel.refreshCache = YES;
    //发送请求
    ZFNetRequest *request =
    [ZFNetRequest startWithRequestModel:requestModel completionBlockWithSuccess:^(NBBaseNetRequest *request) {
        NSLog(@"%@",[request responseJSONObject]);
        NSLog(@"%@",[request responseResultCode]);
        NSLog(@"%@",[request responseResultDictionary]);
    } failure:^(NBBaseNetRequest *request) {
    }];
```

# 终止网络请求
```objective-c
	[request stop];
```
