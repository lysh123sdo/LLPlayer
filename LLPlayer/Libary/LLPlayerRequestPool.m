//
//  LLPlayerRequestPool.m
//  TestAVPlayer
//
//  Created by Lyson on 16/4/22.
//  Copyright © 2016年 TestAVPlayer. All rights reserved.
//

#import "LLPlayerRequestPool.h"

@interface LLPlayerRequestPool()


@property (nonatomic , strong) NSMutableArray *requestArray;
@end

@implementation LLPlayerRequestPool


-(instancetype)init{

    
    if (self = [super init]) {
        
        _requestArray = [[NSMutableArray alloc] init];
        
    }

    return self;
}

-(void)addNewRequest:(AVAssetResourceLoadingRequest*)request{

    @synchronized(self) {
        [self.requestArray addObject:request];
    }
}


-(AVAssetResourceLoadingRequest*)getRequest{

    @synchronized(self) {
        
        AVAssetResourceLoadingRequest *request = [self.requestArray firstObject];
        
        [self.requestArray removeObject:request];
        
        return request;
        
    }
}


-(void)removeRequest:(AVAssetResourceLoadingRequest*)request{

    @synchronized(self) {
        
        [self.requestArray removeObject:request];
    }
}

-(BOOL)hasRequest{

    if (self.requestArray.count) {
        
        return YES;
    }
    return NO;
}

-(void)dealloc{
    
    DLog(@" @@@@@@@@@@@  释放了 %@",NSStringFromClass([self class]));
    
}
@end
