//
//  LLPlayerHeadBurn.h
//  TestAVPlayer
//
//  Created by Lyson on 16/4/22.
//  Copyright © 2016年 TestAVPlayer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LLPlayerPrivate.h"
@interface LLPlayerHeadBurn : NSObject

-(instancetype)initWithPath:(NSString*)path;

/**
 *  保存一个节点到头部坐标
 *
 *  @param range
 *  @param path
 */
-(void)saveRangeToHead:(NSRange)range;


/**
 *  检查该片段是否下载
 *
 *  @param range
 *
 *  @return 已经下载返回 YES ，尚未下载返回NO
 */
-(BOOL)checkRangeHasDownLoad:(NSRange)range;

/**
 *  存总文件大小
 *
 *  @param path
 *
 *  @return
 */
-(void)saveFileSize:(NSInteger)fileSize;


/**
 *  获取总文件大小
 *
 *  @param path
 *
 *  @return
 */
-(NSInteger)getFileSize;

/**
 *  获取一个需要下载的片段
 *
 *  @param range
 *
 *  @return
 */
-(NSRange)getDownLoadRange:(NSRange)range minTask:(NSInteger)minTask;


-(void)saveDownloadData:(NSData*)data offset:(NSInteger)offset;

@end
