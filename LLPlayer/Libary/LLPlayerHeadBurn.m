//
//  LLPlayerHeadBurn.m
//  TestAVPlayer
//
//  Created by Lyson on 16/4/22.
//  Copyright © 2016年 TestAVPlayer. All rights reserved.
//

#import "LLPlayerHeadBurn.h"


@interface LLPlayerHeadBurn()
{
    
    NSString *filePath;
    
    NSInteger fileLength;
    
    NSMutableArray *fileIndexArr;
}
@end

@implementation LLPlayerHeadBurn


-(instancetype)initWithPath:(NSString*)path{
    
    
    if (self = [super init]) {
        
        filePath = [[NSString alloc] initWithString:path];
        fileIndexArr = [[NSMutableArray alloc] init];
    }
    
    return self;
}

/**
 *  获取一个需要下载的片段
 *
 *  @param range
 *
 *  @return
 */
-(NSRange)getDownLoadRange:(NSRange)range minTask:(NSInteger)minTask{
    
    NSArray *indexsArr = [self getAllAvalibleIndex];
    
    NSInteger start = range.location;
    NSInteger end = range.length + range.location;
    
    //无节点直接返回
    if (!indexsArr.count) {
        
        return range;
    }
    
    NSRange resultRange;
    
    for (int i = 0 ; i < indexsArr.count; i = i + 2) {
        
        NSInteger iStart = [[indexsArr objectAtIndex:i] integerValue];
        NSInteger iEnd = [[indexsArr objectAtIndex:i+1] integerValue];
        
        if (iStart <= start && start <= iEnd) {
            //节点下载 ---start == end 或者 start位于 该range中间
            
            int nextIndex = i + 2;
            
            if (nextIndex < [indexsArr count]) {
                
                NSInteger nextStart = [[indexsArr objectAtIndex:nextIndex] integerValue];
                
                if ((nextStart - end) < minTask) {
                    //剩余部分比最小分段小 --将他归入最小分段
                    resultRange = NSMakeRange(iEnd, nextStart - iEnd);
                    break;
                }else if((nextStart - end) >= minTask){
                    resultRange = NSMakeRange(iEnd, end - iEnd);
//                    resultRange = NSMakeRange(iEnd, minTask);
                    break;
                }
                
            }else{
                
                NSInteger fileSize = [self getFileSize];
                
                NSInteger length = fileSize - end;
                
                length = (length >= minTask) ? minTask : (fileSize - iEnd);
                
                resultRange = NSMakeRange(iEnd, length);
                
                break;
            }
            
        }else if (start < iStart && end >= iStart && end <= iEnd){
            
            int foreIndex = i - 2;
            
            NSInteger foreEnd = [[indexsArr objectAtIndex:foreIndex + 1] integerValue];
            
            resultRange = (start - foreEnd) >= minTask ? NSMakeRange(start, iStart - start)  : NSMakeRange(foreEnd, iStart - foreEnd);
            
            break;
            
        }else if (end < iStart){
            
            resultRange = NSMakeRange(start, end - start);
            
            break;
        }else if(start > iEnd){
            
            int nextIndex = i + 2;
            
            NSInteger fileSize = [self getFileSize];
            
            NSInteger length = fileSize - end;
            
            length = (length >= minTask) ? (end - start) : (fileSize - start);
            
            if (nextIndex >= indexsArr.count) {
                
                resultRange = NSMakeRange(start, length);
                
                break;
            }
            
        }
        
    }
    
//        NSLog(@"%@  %@  %@",indexsArr,NSStringFromRange(range),NSStringFromRange(resultRange));
    return resultRange;
    
}


/**
 *  根据下表读取一个长度等于8的数据
 *
 *  @param index 开始读取文件的位置
 *  @param path  文件路径
 *
 *  @return 返回一个int值
 */
-(int)readDataAtIndex:(int)index{
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    
    int offset = index * kLLPlayerSingleBufferSize;;
    
    [fileHandle seekToFileOffset:offset];
    
    NSData *data = [fileHandle readDataOfLength:kLLPlayerSingleBufferSize];
    
    int result = 0;
    [data getBytes: &result length: sizeof(result)];
    
    [fileHandle closeFile];
    
    return result;
}

/**
 *  写入一个数据到文件
 *
 *  @param index 位置
 *  @param value 数据
 *  @param path 文件路径
 */
-(void)writeDataAtIndex:(int)index value:(int)value{
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    
    size_t size = sizeof(value);
    
    NSData *data = [NSData dataWithBytes:&value length:size];
    
    int offset = index*kLLPlayerSingleBufferSize;
    
    [fileHandle seekToFileOffset:offset];
    
    [fileHandle writeData:data];
    
    [fileHandle closeFile];
    
}

/**
 *  保存一个节点到头部坐标
 *
 *  @param range
 *  @param path
 */
-(void)saveRangeToHead:(NSRange)range{
    
    NSInteger start = range.location;
    NSInteger end = range.location + range.length;
    
    [self saveData:start end:end];
    
}

/**
 *  刻录头尾数据
 *
 *  @param start
 *  @param end
 *  @param path
 */
-(void)saveData:(NSInteger)start end:(NSInteger)end{
    
    NSMutableArray *indexArrs = [NSMutableArray arrayWithArray:[self getAllAvalibleIndex]];
    
    if (!indexArrs.count) {
        [indexArrs addObject:[NSNumber numberWithInteger:start]];
        [indexArrs addObject:[NSNumber numberWithInteger:end]];
        
        [fileIndexArr removeAllObjects];
        
        [fileIndexArr addObjectsFromArray:indexArrs];
        return;
    }
    
    for (int i = 0 ; i < [indexArrs count]; i = i +2) {
        
        NSInteger iStart = [[indexArrs objectAtIndex:i] integerValue];
        NSInteger iEnd = [[indexArrs objectAtIndex:i + 1] integerValue];
        if (iStart <= start && start <= iEnd && end > iEnd) {
            //表示该节点与当前节点有交集 --可以合并
            [indexArrs replaceObjectAtIndex:i+1 withObject:[NSNumber numberWithInteger:end]];
            
            int nextIndex = i+2;
            
            if (nextIndex < indexArrs.count) {
                
                NSInteger nextStart = [[indexArrs objectAtIndex:nextIndex] intValue];
                if (nextStart <= end) {
                    //与后一个节点的开始部分有交集---可以继续合并 移除当前节点的End 移除下一节点的Start 形成新的节点
                    [indexArrs removeObjectAtIndex:i+2];
                    [indexArrs removeObjectAtIndex:i+1];
                }
                
            }
            break ;
        }else if(start < iStart && end >= iStart && end <= iEnd){
            //节点尾部与当前节点相交 --可以合并
            [indexArrs replaceObjectAtIndex:i withObject:[NSNumber numberWithInteger:start]];
            break ;
        }else if (iStart > end && start < iStart){
            //无交集 --插入节点
            
            [indexArrs insertObject:[NSNumber numberWithInteger:start] atIndex:i];
            [indexArrs insertObject:[NSNumber numberWithInteger:end] atIndex:i+1];
            
            break ;
        }
    }
    
    //无节点交互且没有比当前节点小的
    if (![indexArrs containsObject:[NSNumber numberWithInteger:start]] && ([[indexArrs lastObject] intValue] < start) && ![indexArrs containsObject:[NSNumber numberWithInteger:end]]) {
        
        [indexArrs addObject:[NSNumber numberWithInteger:start]];
        [indexArrs addObject:[NSNumber numberWithInteger:end]];
    }
    
    
    [fileIndexArr removeAllObjects];
    
    [fileIndexArr addObjectsFromArray:indexArrs];
    
    [self writeToFileData:fileIndexArr];
//    NSLog(@"%@",fileIndexArr);

    
}

-(void)writeToFileData:(NSArray*)indexArrs{

    NSInteger totalCount = 128*2;
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    
    //将新数据写入
    for (int i = 0; i < indexArrs.count; i++) {
        
        NSInteger value = [[indexArrs objectAtIndex:i] intValue];
        
        size_t size = sizeof(value);
        
        NSData *data = [NSData dataWithBytes:&value length:size];
        
        int offset = i*kLLPlayerSingleBufferSize;
        
        [fileHandle seekToFileOffset:offset];
        
        [fileHandle writeData:data];
        
    }
    
    //重置后面节点的数据
    int count = (totalCount - indexArrs.count) > 0 ? (totalCount - indexArrs.count) : 0;
    
    for (int i = indexArrs.count; i < count; i++) {
        
        int value = 0;
        
        size_t size = sizeof(value);
        
        NSData *data = [NSData dataWithBytes:&value length:size];
        
        int offset = i*kLLPlayerSingleBufferSize;
        
        [fileHandle seekToFileOffset:offset];
        
        [fileHandle writeData:data];
    }

    [fileHandle closeFile];
    
}

/**
 *  检查该片段是否下载
 *
 *  @param range
 *
 *  @return 已经下载返回 YES ，尚未下载返回NO
 */
-(BOOL)checkRangeHasDownLoad:(NSRange)range{
    
    NSInteger start = range.location;
    NSInteger end = range.location + range.length;
    
    NSInteger fileSize = [self getFileSize];
    
    if (start >= fileSize && fileSize > 0) {
        
        return YES;
    }
    
    //通过开始点与最小必下片段判断--该段是否已经下载
    NSMutableArray *indexArrs = [self getAllAvalibleIndex];
    
    for (int i = 0 ; i < indexArrs.count; i = i + 2) {
        
        NSInteger iStart = [[indexArrs objectAtIndex:i] integerValue];
        NSInteger iEnd = [[indexArrs objectAtIndex:i + 1] integerValue];
        
        if (start >= iStart && end <= iEnd) {
            //说明已经下载
            return YES;
        }
    }
    
    return NO;
}

/**
 *  获取所有有效刻录
 *
 *  @param path
 *
 *  @return
 */
-(NSMutableArray*)getAllAvalibleIndex{
    
    if (fileIndexArr.count) {
        
        return fileIndexArr;
    }
    
    NSMutableArray *indexArrs = [[NSMutableArray alloc] init];
    
    BOOL dataFlag = YES;
    
    int index = 0;
    
    while (dataFlag) {
        
        int start = [self readDataAtIndex:index];
        
        int end = [self readDataAtIndex:index + 1];
        
        if (end > 0) {
            
            [indexArrs addObject:[NSNumber numberWithInt:start]];
            [indexArrs addObject:[NSNumber numberWithInt:end]];
            
            index += 2;
        }else{
            
            break;
        }
        
        if (index >= kLLPlayerFileHeadBufferSize) {
            
            break;
        }
    }
    
    //    NSLog(@"%@",indexArrs);
    [fileIndexArr addObjectsFromArray:indexArrs];
    
    return fileIndexArr;
    
}

/**
 *  获取总文件大小
 *
 *  @param path
 *
 *  @return
 */
-(NSInteger)getFileSize{
    
    if (fileLength > 0) {
        return fileLength;
    }

    
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForReadingAtPath:filePath];
    [fileHandler seekToFileOffset:kLLPlayerFileHeadBufferSize];
    
    NSData *data = [fileHandler readDataOfLength:kLLPlayerSingleBufferSize];
    
    NSInteger fileSize = 0;
    [data getBytes: &fileSize length: sizeof(fileSize)];
    
    [fileHandler closeFile];
    
    fileLength = fileSize;
    
    return fileLength;
}


/**
 *  存总文件大小
 *
 *  @param path
 *
 *  @return
 */
-(void)saveFileSize:(NSInteger)fileSize{
    
    fileLength = fileSize;
    
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    
    [fileHandler seekToFileOffset:kLLPlayerFileHeadBufferSize];
    
    size_t size = sizeof(fileSize);
    NSData *data = [NSData dataWithBytes:&fileSize length:size];
    
    [fileHandler writeData:data ];
    
    [fileHandler closeFile];
}

-(void)saveDownloadData:(NSData*)data offset:(NSInteger)offset{
    
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    
    [fileHandler seekToFileOffset:offset];
    
    [fileHandler writeData:data];
    
    [fileHandler closeFile];
    
}

-(void)dealloc{
    
    DLog(@" 释放了 ###########################################%@",NSStringFromClass([self class]));
}


@end
