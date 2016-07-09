//
//  LLPlayerRequestTask.m
//  TestAVPlayer
//
//  Created by Lyson on 16/4/22.
//  Copyright © 2016年 TestAVPlayer. All rights reserved.
//

#import "LLPlayerRequestTask.h"
#import "LLPlayerRequestPool.h"
#import "LLPlayerHeadBurn.h"

@interface LLPlayerRequestTask()<NSURLSessionDelegate>
{
    BOOL isRunning;
    
}
@property (nonatomic , strong) NSString *requestUrl;
@property (nonatomic , strong) LLPlayerRequestPool *requestPool;
@property (nonatomic , strong) NSURLSessionDataTask *sessionTask;
@property (nonatomic , assign) NSRange currentTaskRange;

@property (nonatomic , strong) NSString *filePath;
@property (nonatomic , strong) LLPlayerHeadBurn *headBurn;
@property (nonatomic , strong) NSString *mimeType;
@property (nonatomic , assign) NSInteger currentLength;
@property (nonatomic , strong) AVAssetResourceLoadingRequest *currentRequest;

@end

@implementation LLPlayerRequestTask


-(instancetype)initWithUrl:(NSString*)url filePath:(NSString*)filePath{

    if (self = [super init]) {
        
        self.requestUrl = url;
        self.filePath = filePath;
        
        [self initData];
   
    }
    return self;
}

-(void)initData{

    if (![[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
        
        NSInteger size = kLLPlayerFileHeadBufferSize + kLLPlayerFileBufferSize;
        
        [[NSFileManager defaultManager]  createFileAtPath:self.filePath contents:nil attributes:@{NSFileSize:[NSNumber numberWithInteger:size]}];
    }

    self.requestPool = [[LLPlayerRequestPool alloc] init];
    self.headBurn = [[LLPlayerHeadBurn alloc] initWithPath:self.filePath];
    
    self.fileSizeLength = [self.headBurn getFileSize];
}

-(void)dealloc{
    
    DLog(@" @@@@@@@@@@@  释放了 %@",NSStringFromClass([self class]));
}

-(void)addTask:(AVAssetResourceLoadingRequest*)request{
    
    [self.requestPool addNewRequest:request];
    
    [self startNewTask];
}

-(void)removeRequest:(AVAssetResourceLoadingRequest*)request{

//    if (self.currentTaskRange.location == request.dataRequest.requestedOffset) {
//        
//        return;
//    }
//    
    [self.requestPool removeRequest:request];
}


#pragma mark - 网络请求

-(NSURLSession*)session{

    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession  *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue new]];
    return session;
}

- (NSMutableURLRequest *)request
{
    //创建请求
    NSURL *url = [NSURL URLWithString:self.requestUrl];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    
    return request;
}


-(NSRange)getTaskRange{
    
    AVAssetResourceLoadingRequest *request = [self.requestPool getRequest];
    
    self.currentRequest = request;

    NSUInteger responseSize = kLLPlayerReadMinBufferSize;
    
    return NSMakeRange((NSInteger)request.dataRequest.requestedOffset, responseSize);
}

-(void)startNewTask{
    
    if ([self getIsRunning]) {
        
        return;
    }
    
    [self setRunning:YES];
    
    if (![self.requestPool hasRequest]) {
        [self setRunning:NO];
        return;
    }
    
    [self startTask];
    
}

-(void)startTask{
    
    NSRange range = [self getTaskRange];
    
    if ([self.headBurn  checkRangeHasDownLoad:range]) {
        //已经下载的
        [self responseFileDataWithRequest:self.currentRequest dataLength:kLLPlayerReadMinBufferSize];
        
        return ;
    }
    
    NSUInteger responseSize = kLLPlayerReadMinBufferSize;
    
    NSRange bufferRange = [self.headBurn getDownLoadRange:NSMakeRange(range.location, responseSize) minTask:kLLPlayerReadMinBufferSize];
    
    if (bufferRange.length <= 0) {
        [self setRunning:NO];
        return ;
    }
    
    //    NSLog(@" request ==========  %@",NSStringFromRange(range));
    
    [self startTaskWithRange:bufferRange];
}

-(void)startTaskWithRange:(NSRange)range{

    self.currentTaskRange = range;
    
    NSMutableURLRequest *request = [self request];
    
    NSInteger location = range.location;
    NSInteger length = range.length + range.location;
    
    NSString *requestRange;
    
    if (length <= 0) {
        requestRange = [NSString stringWithFormat:@"bytes=%d-", location];
    }else
    {
        requestRange = [NSString stringWithFormat:@"bytes=%d-%d", location,length];
    }

    [request setValue:requestRange forHTTPHeaderField:@"Range"];
    
    DLog(@"@@@@@@@@@@@@@@@@@@@@ @@@@@@\n  %@  %@ \n@@@@@@@@@@@@@@@@@@@@@@@@@",requestRange,NSStringFromRange(range));
    
    self.sessionTask = [[self session] dataTaskWithRequest:request];
    [self.sessionTask resume];

}

-(void)saveDownloadBurn:(NSInteger)receiveDataLength{
    
    @synchronized(self) {
        
        if (receiveDataLength <= 0) {
            return;
        }
        
        NSRange range = NSMakeRange(self.currentTaskRange.location, receiveDataLength);
        
        [self.headBurn saveRangeToHead:range];
        
    }
}

-(void)responseFileDataWithRequest:(AVAssetResourceLoadingRequest*)request dataLength:(NSInteger)dataLength{
    
    [self fillInContentInformation:request.contentInformationRequest];
    
    NSInteger offset = (NSInteger)request.dataRequest.requestedOffset;
    
    NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)request.dataRequest.requestedLength, dataLength);
    
    offset += kLLPlayerFileHeadBufferSize + kLLPlayerFileBufferSize;
    
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:self.filePath];
    [handle seekToFileOffset:offset];
    NSData *data = [handle readDataOfLength:numberOfBytesToRespondWith];
    
    [request.dataRequest  respondWithData:data];

    [request finishLoading];
    
//    [self.requestPool removeRequest:request];
    
    self.currentRequest = nil;
    
    [self setRunning:NO];
    
    [self startNewTask];
}

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
{
    NSString *mimeType = @"video/mp4";
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = self.fileSizeLength;
}

#pragma mark - 请求回调

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error{


}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
//    NSLog(@" @@@@@@@@@@@@@@@@@@@@  下载完成");

    NSInteger currRecieveLength = (NSInteger)task.countOfBytesReceived;
    
    [self saveDownloadBurn:currRecieveLength];
    
    AVAssetResourceLoadingRequest *request = self.currentRequest;
    
//    NSLog(@" response ==================   %@",NSStringFromRange(NSMakeRange((NSInteger)request.dataRequest.requestedOffset, request.dataRequest.requestedLength)));
    
    [self responseFileDataWithRequest:request dataLength:currRecieveLength];

}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{

    NSHTTPURLResponse *response = (NSHTTPURLResponse*)dataTask.response;
    
    if (response.statusCode ==200) {
 
    }else if (response.statusCode ==206){
        
        NSString *contentRange = [response.allHeaderFields valueForKey:@"Content-Range"];
        
        if ([contentRange hasPrefix:@"bytes"]) {
            
            NSArray *bytes = [contentRange componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
            
            if ([bytes count] == 4) {
                
                self.fileSizeLength = [[bytes objectAtIndex:3] integerValue];
                
                //存储文件大小
                [self.headBurn saveFileSize:self.fileSizeLength];
            }
        }
    }else if (response.statusCode ==416){
        
        return;
        
    }else{
        //其他情况还没发现
        return;
        
    }
    //向文件追加数据
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:self.filePath];
    
    NSString *contentRange = [response.allHeaderFields valueForKey:@"Content-Range"];
    
    NSInteger offset = 0;
    
    if ([contentRange hasPrefix:@"bytes"]) {
        
        NSArray *bytes = [contentRange componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
 
        offset = [[bytes objectAtIndex:1] integerValue];
    }

    offset = offset + (NSInteger)dataTask.countOfBytesReceived - data.length + kLLPlayerFileHeadBufferSize + kLLPlayerFileBufferSize;

//    NSLog(@" !!!!!!!!!!!!    %@  ---- ",[dataTask.currentRequest valueForHTTPHeaderField:@"Range"]);
    
    [fileHandle seekToFileOffset:offset];
    
    [fileHandle writeData:data];

    [fileHandle closeFile];
}

#pragma mark - 

-(void)setRunning:(BOOL)running{

    @synchronized(self) {
        isRunning = running;
    }
}

-(BOOL)getIsRunning{

    @synchronized(self) {
        return isRunning;
    }
}


@end
