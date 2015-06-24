//
//  WRSConfigSentence.h
//  WoW Region Switcher
//
//  Created by Manfred Lau on 8/20/14.
//  Copyright (c) 2014 WeZZard Design. All rights reserved.
//

@import Foundation;

@interface WRSConfigSentence : NSObject
@property (readonly, copy) NSString * target;
@property (copy) NSString * value;
- (instancetype)initWithTarget:(NSString *)target value:(NSString *)value;

- (NSString *)expression;
@end
