//
//  TTPlayerItem.h
//  TTPlayerLib
//
//  Created by ClaudeLi on 2018/1/6.
//  Copyright © 2018年 ClaudeLi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TTPlayerItem : NSObject

@property (nonatomic, copy) NSString *file;

@property (nonatomic, strong) NSURL  *playURL;
@property (nonatomic, assign) BOOL isNetVideo;
@property (nonatomic, assign) BOOL isLocalServer;
@property (nonatomic, assign) BOOL isLive;

@property (nonatomic, assign) CGFloat   seekTime;

// 本地文件路径 重写filePath
- (NSString *)filePath;

@end
