//
//  LLPlayerPrivate.h
//  TestAVPlayer
//
//  Created by Lyson on 16/4/22.
//  Copyright © 2016年 TestAVPlayer. All rights reserved.
//

#ifdef DEBUG
#   define DLog(fmt, ...) {NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);}
#   define ELog(err) {if(err) DLog(@"%@", err)}
#else
#   define DLog(...)
#   define ELog(err)
#endif

#define kLLPlayerReadMinBufferSize (1024*1024*1)

#define kLLPlayerFileHeadBufferSize (1024*1)

#define kLLPlayerFileBufferSize (4*1)

#define kLLPlayerSingleBufferSize (4*1)

#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>