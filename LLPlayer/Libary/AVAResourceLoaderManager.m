//
//  AVAResourceLoaderManager.m
//  TestPlayer
//
//  Created by Lyson on 16/4/20.
//  Copyright © 2016年 TestPlayer. All rights reserved.
//

#import "AVAResourceLoaderManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "LLPlayerRequestTask.h"
@interface AVAResourceLoaderManager()

@property (nonatomic , strong) NSString *serverUrl;
@property (nonatomic , strong) NSString *cachePath;

@property (nonatomic , strong) LLPlayerRequestTask *downloadTask;

@end

@implementation AVAResourceLoaderManager


//
- (instancetype)initWithServerUrl:(NSString*)url cachePath:(NSString*)cachePath
{
    self = [super init];
    if (self) {

        self.serverUrl = url;
        self.cachePath = cachePath;
        
        self.downloadTask = [[LLPlayerRequestTask alloc] initWithUrl:self.serverUrl filePath:self.cachePath];
        
        DLog(@"%@",self.cachePath);
    }
    return self;
}

///**
// *  必须返回Yes，如果返回NO，则resourceLoader将会加载出现故障的数据
// *  这里会出现很多个loadingRequest请求， 需要为每一次请求作出处理
// *  @param resourceLoader 资源管理器
// *  @param loadingRequest 每一小块数据的请求
// *
// */
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self dealWithLoadingRequest:loadingRequest];

    return YES;
}


- (void)dealWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.downloadTask addTask:loadingRequest];
    
}


- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.downloadTask removeRequest:loadingRequest];
    
}


- (NSURL *)getSchemeVideoURL:(NSURL *)url
{
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = @"streaming";
    return [components URL];
}


@end
