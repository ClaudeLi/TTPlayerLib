//
//  TTLocalServer.h
//  TTPlayerLib
//
//  Created by ClaudeLi on 2017/4/22.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KSYHTTPCache/HTTPCacheDefines.h>

@interface TTLocalServer : NSObject

+ (NSString *)cacheFolderPath;

+ (void)registerLocalServer;
+ (void)startServer;
+ (void)stopServer;

+ (BOOL)isRunning;

/**
 * 获取代理后的播放地址
 */
+ (NSString *)getProxyUrl:(NSString*)url;

+ (void)setProxyUrl:(NSString*)url newCache:(BOOL)newCache;
/**
 * 获取下载地址
 */
+ (NSString *)getDownloadUrl:(NSString*)url;

/**
 * 获取缓存区大小 单位:MB
 */
+ (CGFloat)getCacheRootSize;

/**
 * 删除缓存区所以文件
 */
+ (void)deleteAllCaches;

/**
 * 查询某个url缓存是否完成
 */
-(BOOL)isCacheCompleteForUrl:(NSURL*)url;

/**
 * 查询某个url缓存进度
 */
+ (CGFloat)cachedProgressWith:(NSURL*)url;

@end
