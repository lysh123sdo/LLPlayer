//
//  AVAResourceLoaderManager.h
//  TestPlayer
//
//  Created by Lyson on 16/4/20.
//  Copyright © 2016年 TestPlayer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

@interface AVAResourceLoaderManager : NSObject <AVAssetResourceLoaderDelegate>

- (instancetype)initWithServerUrl:(NSString*)url cachePath:(NSString*)cachePath;


- (NSURL *)getSchemeVideoURL:(NSURL *)url;

@end
