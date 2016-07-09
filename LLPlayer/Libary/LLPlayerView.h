//
//  LLPlayerView.h
//  TestMedia
//
//  Created by Lyson on 16/4/6.
//  Copyright © 2016年 TestMedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVAResourceLoaderManager.h"

@interface LLPlayerView : UIView


-(instancetype)initWithFrame:(CGRect)frame Url:(NSString*)url;

-(void)stopAll;

@end
