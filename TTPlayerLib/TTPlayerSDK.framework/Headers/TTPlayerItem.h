//
//  TTPlayerItem.h
//  TTPlayerLib
//
//  Created by ClaudeLi on 2018/1/6.
//  Copyright © 2018年 ClaudeLi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TTPlayerItem : NSObject
 
/**
 若开启记录视频播放时间点, 此属性作为主键 不能为空
 */
@property (nonatomic, copy)   NSString  *mainkey;
@property (nonatomic, assign) NSInteger videoType;// 视频类型可自定义
@property (nonatomic, assign) double    insetTime;
@property (nonatomic, assign) double    seekTime;
@property (nonatomic, assign) NSInteger currentIndex; 

@property (nonatomic, copy)   NSString  *file;   // 视频地址
@property (nonatomic, strong) NSURL     *playURL;// 真正播放地址
@property (nonatomic, assign) BOOL isNetVideo;   // 是否网络视频
@property (nonatomic, assign) BOOL isLocalServer;// 是否本地服务器播放
@property (nonatomic, assign) BOOL isLive;       // 是否是直播流

/**
 本地文件路径 重写filePath
 
 @return filePath
 */
- (NSString *)filePath;

@end
