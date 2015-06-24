//
//  WRSConfigDocument.m
//  WoW Region Switcher
//
//  Created by Manfred Lau on 8/20/14.
//  Copyright (c) 2014 WeZZard Design. All rights reserved.
//

#import <WZFoundation/WZFoundation.h>

#import "WRSLocale.h"
#import "WRSRegion.h"

#import "WRSConfigDocument.h"
#import "WRSConfigSentence.h"

// TODO: Default region detection

WZDefineKVOContext(WRSConfigDocumentRegionDidChangeContext)
WZDefineKVOContext(WRSConfigDocumentLocaleDidChangeContext)

@interface WRSConfigDocument () {
    NSMutableArray * _sentences;
    OSSpinLock _sentencesLock;
}
@property (copy) NSArray * sentences;
@end

@implementation WRSConfigDocument
- (NSArray *)sentences
{
    OSSpinLockLock(&_sentencesLock);
    NSArray * copiedSentences = [_sentences copy];
    OSSpinLockUnlock(&_sentencesLock);
    return copiedSentences;
}

- (void)setSentences:(NSArray *)sentences
{
    OSSpinLockLock(&_sentencesLock);
    NSMutableArray * orginalSentences = _sentences;
    if (![orginalSentences isEqualToArray: sentences]) {
        _sentences = [sentences mutableCopy];
    }
    OSSpinLockUnlock(&_sentencesLock);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addObserver:self forKeyPath:@"region" options:NSKeyValueObservingOptionNew
                  context:(__bridge void *)(WRSConfigDocumentRegionDidChangeContext)];
        [self addObserver:self forKeyPath:@"locale" options:NSKeyValueObservingOptionNew
                  context:(__bridge void *)(WRSConfigDocumentLocaleDidChangeContext)];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"region"
                 context:(__bridge void *)(WRSConfigDocumentRegionDidChangeContext)];
    [self removeObserver:self forKeyPath:@"locale"
                 context:(__bridge void *)(WRSConfigDocumentLocaleDidChangeContext)];
    
    [_sentences removeAllObjects];
    _sentences = nil;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSMutableString * content = [[NSMutableString alloc] init];
    
    NSArray * sentences = self.sentences;
    [sentences enumerateObjectsUsingBlock:^(WRSConfigSentence * sentence, NSUInteger idx, BOOL *stop) {
        [content appendString:[sentence expression]];
        if (idx != MAX(sentences.count - 1, 0)) {
            [content appendString:@"\n"];
        }
    }];
    
    return [content dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSString * content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSError * regXpErr = nil;
    
    NSRegularExpression * regXp = [[NSRegularExpression alloc] initWithPattern:@"SET\\s[^\"]*\\s\"[^\"]*\"" options:0 error:&regXpErr];
    
    NSMutableArray * sentences = [NSMutableArray array];
    
    [regXp enumerateMatchesInString:content options:0 range:NSRangeMake(0, content.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSString * substring = [content substringWithRange:result.range];
        
        NSArray * components = [substring componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSAssert(components.count == 3, @"Invalid number of components for string: %@", substring);
        
        WRSConfigSentence * sentence = [[WRSConfigSentence alloc] initWithTarget:components[1] value:components[2]];
        
        [sentences addObject:sentence];
    }];
    
    self.sentences = sentences;
    
    // Setup region
    __block WRSConfigSentence * regionSentence = nil;
    [sentences enumerateObjectsUsingBlock:^(WRSConfigSentence * sentence, NSUInteger idx, BOOL *stop) {
        if ([sentence.target compare:@"portal" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            regionSentence = sentence;
            * stop = YES;
        }
    }];
    
    if (!regionSentence) {
        __block WRSConfigSentence * localeSentence = nil;
        [sentences enumerateObjectsUsingBlock:^(WRSConfigSentence * sentence, NSUInteger idx, BOOL *stop) {
            if ([sentence.target compare:@"locale" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                localeSentence = sentence;
                * stop = YES;
            }
        }];
        
        NSString * countryCode = [localeSentence.value substringWithRange:NSRangeMake(2, 2)];
        regionSentence = [[WRSConfigSentence alloc] initWithTarget:@"portal" value:countryCode.lowercaseString];
        
        [_sentences addObject: regionSentence];
    }
    
    WRSRegion * region = [[WRSRegion alloc] initWithPortal:regionSentence.value];
    self.region = region;
    
    // Setup locale
    __block WRSConfigSentence * localeSentence = nil;
    [sentences enumerateObjectsUsingBlock:^(WRSConfigSentence * sentence, NSUInteger idx, BOOL *stop) {
        if ([sentence.target compare:@"locale" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            localeSentence = sentence;
            * stop = YES;
        }
    }];
    
    WRSLocale * locale = [[WRSLocale alloc] initWithLocaleString:localeSentence.value];
    self.locale = locale;
    
    return YES;
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == (__bridge void *)(WRSConfigDocumentRegionDidChangeContext)) {
        
        WRSRegion * newRegion = [change objectForKey:NSKeyValueChangeNewKey];
        
        __block WRSConfigSentence * regionSentence = nil;
        [self.sentences enumerateObjectsUsingBlock:^(WRSConfigSentence * sentence, NSUInteger idx, BOOL *stop) {
            if ([sentence.target compare:@"portal" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                regionSentence = sentence;
                * stop = YES;
            }
        }];
        
        if (!regionSentence) {
            regionSentence = [[WRSConfigSentence alloc] initWithTarget:@"portal" value:newRegion.portal];
            [_sentences addObject:regionSentence];
        } else {
            regionSentence.value = newRegion.portal;
        }
        
    } else if (context == (__bridge void *)(WRSConfigDocumentLocaleDidChangeContext)) {
        
        WRSLocale * newLocale = [change objectForKey:NSKeyValueChangeNewKey];
        
        __block WRSConfigSentence * localeSentence = nil;
        [self.sentences enumerateObjectsUsingBlock:^(WRSConfigSentence * sentence, NSUInteger idx, BOOL *stop) {
            if ([sentence.target compare:@"locale" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                localeSentence = sentence;
                * stop = YES;
            }
        }];
        
        if (!localeSentence) {
            localeSentence = [[WRSConfigSentence alloc] initWithTarget:@"locale" value:newLocale.localeName];
            [_sentences addObject:localeSentence];
        } else {
            localeSentence.value = newLocale.localeName;
        }
        
    } else {
        
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
@end
