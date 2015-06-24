//
//  WRSRegion.m
//  WoW Region Switcher
//
//  Created by Manfred Lau on 8/20/14.
//  Copyright (c) 2014 WeZZard Design. All rights reserved.
//

#import "WRSRegion.h"

@implementation WRSRegion
- (instancetype)initWithPortal:(NSString *)portal
{
    self = [super init];
    if (self) {
        _portal = [portal copy];
        if ([portal compare:@"tw" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            _name = @"The Republic of China";
        } else if ([portal compare:@"cn" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            _name = @"The People's Republic of China";
        } else if ([portal compare:@"us" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            _name = @"United States";
        } else if ([portal compare:@"kr" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            _name = @"South Korea";
        } else if ([portal compare:@"eu" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            _name = @"Europe";
        } else if ([portal compare:@"ru" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            _name = @"Russia";
        } else {
            [NSException raise:NSGenericException format:@"Invalid portal: %@", portal];
        }
    }
    return self;
}

- (instancetype)initWithRegionName:(NSString *)regionName portal:(NSString *)portal
{
    self = [super init];
    if (self) {
        _name = [regionName copy];
        _portal = [portal copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    WRSRegion * region = [[[self class] allocWithZone:zone] initWithRegionName:_name portal:_portal];
    return region;
}

- (BOOL)isEqual:(id)object
{
    if (object) {
        if ([object isMemberOfClass:[self class]]) {
            WRSRegion * comparedRegion = (id) object;
            
            return ([comparedRegion -> _name isEqualToString:_name] &&
                    [comparedRegion -> _portal isEqualToString:_portal]);
        }
    }
    return NO;
}

- (NSUInteger)hash
{
    return [_name hash] + [_portal hash];
}

- (void)dealloc
{
    _name = nil;
    _portal = nil;
}

+ (instancetype)ROC
{
    WRSRegion * region = [[self alloc] initWithRegionName:@"The Republic of China" portal:@"tw"];
    return region;
}

+ (instancetype)PRC
{
    WRSRegion * region = [[self alloc] initWithRegionName:@"The People's Republic of China" portal:@"cn"];
    return region;
}

+ (instancetype)US
{
    WRSRegion * region = [[self alloc] initWithRegionName:@"United States" portal:@"us"];
    return region;
}

+ (instancetype)SouthKorea
{
    WRSRegion * region = [[self alloc] initWithRegionName:@"South Korea" portal:@"kr"];
    return region;
}

+ (instancetype)Europe
{
    WRSRegion * region = [[self alloc] initWithRegionName:@"Europe" portal:@"eu"];
    return region;
}

+ (instancetype)Russia
{
    WRSRegion * region = [[self alloc] initWithRegionName:@"Russia" portal:@"ru"];
    return region;
}

+ (NSArray *)availableRegions
{
    return @[[self ROC], [self PRC], [self US], [self SouthKorea], [self Europe], [self Russia]];
}
@end
