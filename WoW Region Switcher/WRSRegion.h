//
//  WRSRegion.h
//  WoW Region Switcher
//
//  Created by Manfred Lau on 8/20/14.
//  Copyright (c) 2014 WeZZard Design. All rights reserved.
//

@import Foundation;

@interface WRSRegion : NSObject <NSCopying>
@property (readonly, copy) NSString * name;
@property (readonly, copy) NSString * portal;

+ (instancetype)ROC;
+ (instancetype)PRC;
+ (instancetype)US;
+ (instancetype)SouthKorea;
+ (instancetype)Europe;
+ (instancetype)Russia;

+ (NSArray *)availableRegions;

- (instancetype)initWithPortal:(NSString *)portal;
@end
