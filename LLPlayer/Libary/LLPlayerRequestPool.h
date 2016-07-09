//
//  LLPlayerRequestPool.h
//  TestAVPlayer
//
//  Created by Lyson on 16/4/22.
//  Copyright © 2016年 TestAVPlayer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LLPlayerPrivate.h"



@interface LLPlayerRequestPool : NSObject


/**
 *  获取一个请求
 *
 *  @return 
 */
-(AVAssetResourceLoadingRequest*)getRequest;

/**
 *  添加请求
 *
 *  @param request
 */
-(void)addNewRequest:(AVAssetResourceLoadingRequest*)request;

/**
 *  判断是否有请求
 *
 *  @return 
 */
-(BOOL)hasRequest;

/**
 *  移除一个请求
 *
 *  @param request 
 */
-(void)removeRequest:(AVAssetResourceLoadingRequest*)request;

@end
