//
//  TTLocalServer.m
//  TTPlayerLib
//
//  Created by ClaudeLi on 2017/4/22.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "TTLocalServer.h"
#import <KSYHTTPCache/KSYHTTPProxyService.h>
#import <CLTools/CLTools.h>
#import "TTPlayerDefaults.h"

#define  HasServer  YES

static NSString *TTCacheFileName = @"com.caches.videos";
//static NSInteger fileCount = 5;
//static NSInteger maxSingleFileSize = 10 * 1024 * 1024;      // 单位 B
static long long maxTotalSize  = 500*1024*1024;               // 单位 B

@implementation TTLocalServer

+ (NSString *)cacheFolderPath{
    static dispatch_once_t one;
    static NSString *path;
    dispatch_once(&one, ^{
        path = [NSCachesDirPath() stringByAppendingPathComponent:TTCacheFileName];
        NSFileManager *fileManager=[NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:path])
        {
            [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
    });
    return path;
}

+ (void)registerLocalServer{
    if (HasServer) {
        NSLog(@"CacheSDKVersion = %@", [KSYHTTPProxyService getVersion]);
        [[KSYHTTPProxyService sharedInstance] setCacheRoot:[self cacheFolderPath]];
        // 设置缓存区文件总个数限制
//        [[KSYHTTPProxyService sharedInstance] setMaxFilesCountLimited:fileCount];
        // 设置缓存区文件总大小限制, 个数和大小不能共存
        [[KSYHTTPProxyService sharedInstance] setMaxCacheSizeLimited:maxTotalSize];
        // 设置单个文件大小限制，超过该大小的文件将不被缓存
//        [[KSYHTTPProxyService sharedInstance] setMaxSingleFileSize:maxSingleFileSize];
        [[KSYHTTPProxyService sharedInstance] startServer];
    }
}

+ (BOOL)isRunning{
    if (HasServer) {
        return [KSYHTTPProxyService sharedInstance].isRunning;
    }
    return NO;
}

+ (void)startServer{
    if (HasServer) {
        [[KSYHTTPProxyService sharedInstance] startServer];
    }
}

+ (void)stopServer{
    if (HasServer) {
        if (!TTPlayerStandard.downloading) {
            if ([KSYHTTPProxyService sharedInstance].isRunning){
                [[KSYHTTPProxyService sharedInstance] stopServer];
            }
        }
    }
}

/**
 * 获取代理后的播放地址
 */
+ (NSString *)getProxyUrl:(NSString*)url{
    if (HasServer) {
        if([[KSYHTTPProxyService sharedInstance] isCacheCompleteForUrl:[NSURL URLWithString:url]]){
            return [[KSYHTTPProxyService sharedInstance] getProxyUrl:url newCache:NO];
        }else{
            if (TTPlayerStandard.currentNetworkStatus == 0) {
                return [[KSYHTTPProxyService sharedInstance] getProxyUrl:url newCache:NO];
            }else{
                return [[KSYHTTPProxyService sharedInstance] getProxyUrl:url];
            }
        }
    }
    return url;
}

+ (NSString *)getDownloadUrl:(NSString*)url{
    if (HasServer) {
        return [[KSYHTTPProxyService sharedInstance] getProxyUrl:url];
    }
    return url;
}


+ (void)setProxyUrl:(NSString*)url newCache:(BOOL)newCache{
    if (!HasServer) {
        return;
    }
    if (newCache) {
        [[KSYHTTPProxyService sharedInstance] getProxyUrl:url];
    }else{
        [[KSYHTTPProxyService sharedInstance] getProxyUrl:url newCache:NO];
    }
}

/**
 * 获取缓存区大小 单位:MB
 */
+ (CGFloat)getCacheRootSize{
    if (!HasServer || TTPlayerStandard.downloading) {
        return 0;
    }
    NSError *error;
    long long folderSize = 0;
    NSArray *cachedArray = [[KSYHTTPProxyService sharedInstance] getAllCachedFileListWithError:&error];
    if (error) {
        NSLog(@"%@", error);
        error = nil;
    }else{
        for (NSDictionary* dict in cachedArray) {
            folderSize+= GetFileSizeAtPath(dict[CacheFilePathKey]);
        }
    }
    NSArray *cachingArray = [[KSYHTTPProxyService sharedInstance] getAllCachingFileListWithError:&error];
    if (error) {
        NSLog(@"%@", error);
    }else{
        for (NSDictionary* dict in cachingArray) {
            NSArray<NSValue *> *cachedFragments = dict[CacheFragmentsKey];
            if (cachedFragments == nil  || cachedFragments.count == 0) continue;
            NSInteger cacheLength = cachedFragments[0].rangeValue.length;
            folderSize+=cacheLength;
        }
    }
    return folderSize/1024.0/1024.0;
}

/**
 * 删除缓存区所以文件
 */
+ (void)deleteAllCaches{
    if (!HasServer || TTPlayerStandard.downloading) {
        return;
    }
    NSError *error;
    [[KSYHTTPProxyService sharedInstance] deleteAllCachesWithError:&error];
    if (error) {
        NSLog(@"deleteAllCachesError = %@", error);
    }
}

/**
 * 查询某个url缓存是否完成
 */
-(BOOL)isCacheCompleteForUrl:(NSURL*)url{
    return [[KSYHTTPProxyService sharedInstance] isCacheCompleteForUrl:url];
}

/**
 * 查询某个url缓存进度
 */
+ (CGFloat)cachedProgressWith:(NSURL*)url{
    @autoreleasepool {
        if([[KSYHTTPProxyService sharedInstance] isCacheCompleteForUrl:url]){
            return 1;
        }else{
            NSError *error;
            NSArray *array = [[KSYHTTPProxyService sharedInstance] getCacheFragmentForUrl:url error:&error];
            if (error) {
                NSLog(@"%@", error);
            }else{
                if (array && array.count) {
                    NSDictionary *dict = array[0];
                    NSArray<NSValue *> *cachedFragments = dict[CacheFragmentsKey];
                    long long contentLength = [dict[CacheContentLengthKey] longLongValue];
                    if (cachedFragments == nil  || cachedFragments.count == 0 || contentLength <= 0) return 0;
                    NSInteger cacheLength = cachedFragments[0].rangeValue.length;
                    return cacheLength /(contentLength *1.0);
                }
            }
            return 0;
        }
    }
}

@end
