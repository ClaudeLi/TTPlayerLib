//
//  TTPlayerDataBase.h
//  TTPlayerLib
//
//  Created by ClaudeLi on 2017/1/10.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TTPlayerItem;
#define TTPlayerDB      [TTPlayerDataBase defaultManager]

@interface TTPlayerDataBase : NSObject

+ (instancetype)defaultManager;

- (void)insertRecordWith:(TTPlayerItem *)object;
- (TTPlayerItem *)selectWithKey:(NSString *)key;

- (void)deleteRecordWithItem:(TTPlayerItem *)object;
- (void)deleteRecordWithType:(NSInteger)type;
- (void)deleteAllRecords;

@end
