//
//  WRSLocale.h
//  WoW Region Switcher
//
//  Created by Manfred Lau on 8/20/14.
//  Copyright (c) 2014 WeZZard Design. All rights reserved.
//

@import Foundation;

@interface WRSLocale : NSObject <NSCopying>
@property (nonatomic, readonly, copy) NSString * localeName;
@property (nonatomic, readonly, copy) NSString * localeDescription;
- (instancetype)initWithLocaleString:(NSString *)localeString;
@end
