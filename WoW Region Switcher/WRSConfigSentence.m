//
//  WRSConfigSentence.m
//  WoW Region Switcher
//
//  Created by Manfred Lau on 8/20/14.
//  Copyright (c) 2014 WeZZard Design. All rights reserved.
//

#import "WRSConfigSentence.h"

@implementation WRSConfigSentence
- (instancetype)initWithTarget:(NSString *)target value:(NSString *)value
{
    self = [super init];
    if (self) {
        _target = [target copy];
        value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        _value = [value copy];
    }
    return self;
}

- (void)dealloc
{
    _target = nil;
    _value = nil;
}

- (NSString *)expression
{
    return [NSString stringWithFormat:@"SET %@ \"%@\"", self.target, self.value];
}
@end
