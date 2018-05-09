//
//  LXUUID.m
//  UMSAgent
//
//  Created by longxin.sui on 2018/4/27.
//  Copyright © 2018年 data. All rights reserved.
//

#import "LXUUID.h"
#import <UIKit/UIPasteboard.h>

// UUID缓存
static NSString *AHUUIDCache = nil;
// key
static NSString *const AHUUID = @"com.autohome.umsagent.uuid";
static NSString *const AHAppUUID = @"com.autohome.umsagent.appuuid";
static NSString *const AHPbType = @"com.autohome.umsagent.pb";
static NSString *const AHPbSlotID = @"com.autohome.umsagent.pbid";
// 剪切板遍历上限
static int const AHUUIDRedundancySlots = 100;

@implementation LXUUID

#pragma mark - Private

// 生成UUID
+ (NSString *)generateUUID {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *ahuuid = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
    CFRelease(uuid);
    
    return ahuuid;
}

// 查询剪切板信息
+ (NSMutableDictionary *)getDicFromPboard:(id)pboard {
    id item = [pboard dataForPasteboardType:AHPbType];
    if(item) {
        @try {
            item = [NSKeyedUnarchiver unarchiveObjectWithData:item];
        }
        @catch(NSException *e) {
            item = nil;
        }
    }
    
    return [NSMutableDictionary dictionaryWithDictionary:(item == nil || [item isKindOfClass:[NSDictionary class]])? item : nil];
}

// 剪切板存储信息
+ (void)setDict:(id)dict forPasteBoard:(id)pboard {
    [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:dict] forPasteboardType:AHPbType];
}


#pragma mark - Public

+ (NSString *)value {
    // 检查缓存信息
    if(AHUUIDCache) {
        return AHUUIDCache;
    }
    
    // uuid
    NSString *ahuuid = nil;
    // appid
    NSString *appuuid = nil;
    // 剪切板id
    NSString *slotPbid = nil;
    BOOL saveToUserdefaults = NO;
    
    // 检查NSUserDefaults信息
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *localDict = [defaults objectForKey:AHUUID];
    if([localDict isKindOfClass:[NSDictionary class]]) {
        localDict = [NSMutableDictionary dictionaryWithDictionary:localDict];
        ahuuid = [localDict objectForKey:AHUUID];
        appuuid = [localDict objectForKey:AHAppUUID];
        slotPbid = [localDict objectForKey:AHPbSlotID];
    }else{
        // 新生成appid
        appuuid = [LXUUID generateUUID];
    }
    
    // 检查剪切板信息
    NSString *availableSlotPbid = nil;
    NSDictionary *frequencyDict = [NSMutableDictionary dictionaryWithCapacity:AHUUIDRedundancySlots];
    for (int i = 0; i < AHUUIDRedundancySlots; i++) {
        NSString *pbid = [NSString stringWithFormat:@"%@.%d", AHPbSlotID, i];
        UIPasteboard *pb = [UIPasteboard pasteboardWithName:pbid create:NO];
        if(pb) {
            NSMutableDictionary *pbdict = [LXUUID getDicFromPboard:pb];
            NSString *pbuuid = [pbdict objectForKey:AHUUID];
            if(pbuuid) {
                int count = [[frequencyDict objectForKey:pbuuid] intValue];
                [frequencyDict setValue:[NSNumber numberWithInt:++count] forKey:pbuuid];
            }else {
                if(!availableSlotPbid) availableSlotPbid = pbid;
            }
        }else {
            if(!availableSlotPbid) availableSlotPbid = pbid;
        }
    }
    
    // 剪切板中频次最高的uuid
    NSArray *pbuuidArray = [frequencyDict keysSortedByValueUsingSelector:@selector(compare:)];
    NSString *mostAvailableUuid = [pbuuidArray lastObject];
    
    if(!ahuuid) {
        // uuid处理
        if(mostAvailableUuid) {
            ahuuid = mostAvailableUuid;
        }else {
            // 剪切板中也不存在则重新生成
            ahuuid = [LXUUID generateUUID];
        }
        if(!localDict) {
            // 更新localDict信息
            localDict = [NSMutableDictionary dictionaryWithCapacity:2];
            [localDict setObject:ahuuid forKey:AHUUID];
            [localDict setObject:appuuid forKey:AHAppUUID];
            saveToUserdefaults = YES;
        }
    }
    
    if(availableSlotPbid && (!slotPbid || [slotPbid isEqualToString:availableSlotPbid])) {
        // 存储localDict
        UIPasteboard *npb = [UIPasteboard pasteboardWithName:availableSlotPbid create:YES];
        [npb setPersistent:YES];
        
        if (localDict) {
            // 写入剪切板id
            [localDict setObject:availableSlotPbid forKey:AHPbSlotID];
            saveToUserdefaults = YES;
        }
        
        if (localDict && ahuuid) {
            // 存入剪切板
            [LXUUID setDict:localDict forPasteBoard:npb];
        }
    }
    
    if (localDict && saveToUserdefaults) {
        // 存入NSUserDefaults
        [defaults setObject:localDict forKey:AHUUID];
    }
    
    // 更新缓存
    AHUUIDCache = ahuuid;
    return AHUUIDCache;
}

@end
