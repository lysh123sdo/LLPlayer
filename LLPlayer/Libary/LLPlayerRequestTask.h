//
//  LLPlayerRequestTask.h
//  TestAVPlayer
//
//  Created by Lyson on 16/4/22.
//  Copyright © 2016年 TestAVPlayer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LLPlayerPrivate.h"

@interface LLPlayerRequestTask : NSObject

@property (nonatomic , assign) NSInteger fileSizeLength;

-(instancetype)initWithUrl:(NSString*)url filePath:(NSString*)filePath;

-(void)addTask:(AVAssetResourceLoadingRequest*)request;

-(void)removeRequest:(AVAssetResourceLoadingRequest*)request;

@end
