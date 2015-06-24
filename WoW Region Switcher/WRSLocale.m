//
//  WRSLocale.m
//  WoW Region Switcher
//
//  Created by Manfred Lau on 8/20/14.
//  Copyright (c) 2014 WeZZard Design. All rights reserved.
//

#import <WZFoundation/WZFoundation.h>

#import "WRSLocale.h"

@interface WRSLocale ()
@property (assign, getter = isMixed) BOOL mixed;
@property (strong) NSLocale * locale;
@end

@implementation WRSLocale
- (instancetype)initWithLocaleString:(NSString *)localeString
{
    self = [super init];
    if (self) {
        _localeName = localeString;
        _localeDescription = [self descriptionForLocaleString:localeString];
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (object) {
        if ([object isMemberOfClass:[self class]]) {
            WRSLocale * comparedLocale = (id) object;
            
            return ([comparedLocale -> _localeName isEqualToString:_localeName] &&
                    [comparedLocale -> _localeDescription isEqualToString:_localeDescription]);
        }
    }
    return NO;
}

- (void)dealloc
{
    _localeName = nil;
    _localeDescription = nil;
}

- (NSString *)descriptionForLocaleString:(NSString *)localeString
{
    // For WoW, there is some mixed locale identifier like "enCN" which means Chinese version with english soundtrack
    
    NSString * lanugageCode = [localeString substringWithRange:NSRangeMake(0, 2)];
    NSString * countryCode = [localeString substringWithRange:NSRangeMake(2, 2)];
    
    NSString * identifierStyleLocaleString = [NSString stringWithFormat:@"%@_%@", lanugageCode, countryCode];
    
    NSLocale * currentLocale = [NSLocale currentLocale];
    
    NSLocale * specifiedLocale = [NSLocale localeWithLocaleIdentifier:identifierStyleLocaleString];
    self.locale = specifiedLocale;
    
    return [currentLocale displayNameForKey:NSLocaleIdentifier value:identifierStyleLocaleString];
    
#if 0
    NSArray * availableIdentifiers = [NSLocale availableLocaleIdentifiers];
    
    if ([availableIdentifiers containsObject:identifierStyleLocaleString]) {
        
        return [currentLocale displayNameForKey:NSLocaleIdentifier value:identifierStyleLocaleString];
        
    } else {
        
        NSString * displayNameForLocale = [currentLocale displayNameForKey:NSLocaleIdentifier value:lanugageCode];
        NSString * displayNameForSoundtrackLocale = [currentLocale displayNameForKey:NSLocaleCountryCode value:countryCode];
        
        return [NSString stringWithFormat:@"%@ with %@ soundtrack", displayNameForLocale, displayNameForSoundtrackLocale];
    }
    
    return nil;
#endif
}

- (id)copyWithZone:(NSZone *)zone
{
    WRSLocale * copiedLocale = [[[self class] allocWithZone:zone] init];
    
    copiedLocale -> _localeName = [_localeName copy];
    copiedLocale -> _localeDescription = [_localeDescription copy];
    
    return copiedLocale;
}


@end
