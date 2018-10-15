//
//  TTPlayerDataBase.m
//  TTPlayerLib
//
//  Created by ClaudeLi on 2017/1/10.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "TTPlayerDataBase.h"
#import <FMDB/FMDB.h>
#import "TTPlayerItem.h"

#define TTPlayerTable   @"tt_player"

@interface TTPlayerDataBase ()

@property (nonatomic, strong) FMDatabase *dataBase;

@end

static TTPlayerDataBase *playerDataBase;
@implementation TTPlayerDataBase

+ (instancetype)defaultManager{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        playerDataBase = [[TTPlayerDataBase alloc]init];
    });
    return playerDataBase;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        NSString *dbPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/com.ttplayer.db"];
        self.dataBase = [[FMDatabase alloc] initWithPath:dbPath];
        if ([self.dataBase open]) {
            NSString *sql = [NSString stringWithFormat:@"create table if not exists %@(file text, time double, idx integer, type integer, mainkey text primary key)", TTPlayerTable];
            if ([self.dataBase executeUpdate:sql]) {
                NSLog(@"com.ttplayer.db");
            }
            [self.dataBase close];
        }
    }
    return self;
}

// 增
- (void)insertRecordWith:(TTPlayerItem *)object{
    if ([self.dataBase open]) {
        NSString *sql = [NSString stringWithFormat:@"select * from %@ where mainkey='%@'", TTPlayerTable, object.mainkey];
        FMResultSet *set = [self.dataBase executeQuery:sql];
        if ([set next]) {
            NSString *sql = [NSString stringWithFormat:@"update %@ set file=?, time=?, idx=?, type=? where mainkey=?", TTPlayerTable];
            if ([self.dataBase executeUpdate:sql, object.file, @(object.insetTime), @(object.currentIndex), @(object.videoType), object.mainkey]) {
                NSLog(@"update video record success");
            }else{
                NSLog(@"update video record failure");
            }
        }else{
            NSString *sql = [NSString stringWithFormat:@"insert into %@ values(?,?,?,?,?)", TTPlayerTable];
            if ([self.dataBase executeUpdate:sql, object.file, @(object.insetTime), @(object.currentIndex), @(object.videoType), object.mainkey]) {
                NSLog(@"add video record success");
            }else{
                NSLog(@"add video record failure");
            }
        }
        [self.dataBase close];
    }
}

// 查
- (TTPlayerItem *)selectWithKey:(NSString *)key{
    TTPlayerItem *model = [[TTPlayerItem alloc] init];
    if ([self.dataBase open]) {
        NSString *sql = [NSString stringWithFormat:@"select * from %@ where mainkey='%@'", TTPlayerTable, key];
        FMResultSet *set = [self.dataBase executeQuery:sql];
        if(set){
            while ([set next]) { // 如果返回真，说明我们取到记录
                model.mainkey = [set stringForColumn:@"mainkey"];
                model.file = [set stringForColumn:@"file"];
                model.seekTime = [set doubleForColumn:@"time"];
                model.currentIndex = [set intForColumn:@"idx"];
                model.videoType = [set intForColumn:@"type"];
            }
        }
        [self.dataBase close];
    }
    return model;
}
    
    
// 删除某条记录
- (void)deleteRecordWithItem:(TTPlayerItem *)object{
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where mainkey=?", TTPlayerTable];
    if([self.dataBase open]){
        if([self.dataBase executeUpdate:sql, object.mainkey]){
        }
        [self.dataBase close];
    }
}
    
// 删所
- (void)deleteRecordWithType:(NSInteger)type{
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where type=%@", TTPlayerTable, @(type)];
    if([self.dataBase open]){
        if([self.dataBase executeUpdate:sql]){
        }
        [self.dataBase close];
    }
}

- (void)deleteAllRecords{
    NSString *sql = [NSString stringWithFormat:@"delete from %@", TTPlayerTable];
    if([self.dataBase open]){
        if([self.dataBase executeUpdate:sql]){
        }
        [self.dataBase close];
    }
}
    
@end
