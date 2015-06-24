//
//  ViewController.m
//  WoW Region Switcher
//
//  Created by Manfred Lau on 8/15/14.
//  Copyright (c) 2014 WeZZard Design. All rights reserved.
//

#import <WZFoundation/WZFoundation.h>

#import "WRSConfigDocument.h"
#import "WRSLocale.h"
#import "WRSRegion.h"

#import "WRSRootViewController.h"

WZDefineKVOContext(WRSClientPathDidChangeContext)

static NSString * const WRSErrorDomain = @"com.WeZZardDesign.WoWRegionSwitcher";

static NSString * const WoW64AppPathAddition = @"World of Warcraft-64.app";
static NSString * const WoWAppPathAddition = @"World of Warcraft.app";

@interface WRSRootViewController () <NSOpenSavePanelDelegate, NSTableViewDelegate> {
    OSSpinLock _regionsSpin;
}
@property (strong) NSOpenPanel * openPanel;

@property (readonly, copy) NSArray * regions;
@property (strong) WRSRegion * selectedRegion;

@property (copy) NSArray * locales;
@property (strong) NSIndexSet * selectedLocaleIndex;

@property (copy) NSString * clientPath;
@property (strong) WRSConfigDocument * configDocument;
@end

@implementation WRSRootViewController
@synthesize regions = _regions;

- (NSArray *)regions
{
    OSSpinLockLock(&_regionsSpin);
    if (_regions == nil) {
        _regions = [WRSRegion availableRegions];
    }
    OSSpinLockUnlock(&_regionsSpin);
    return _regions;
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    [self addObserver:self forKeyPath:@"clientPath" options:(NSKeyValueObservingOptionNew)
              context:(__bridge void *)(WRSClientPathDidChangeContext)];
    
    NSURL * defaultURL = [NSURL fileURLWithPath:@"/Applications/World of Warcraft"];
    if ([self panel:self.openPanel validateURL:defaultURL error:nil]) {
        self.clientPath = defaultURL.path;
    }
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    
    [self removeObserver:self forKeyPath:@"clientPath"
                 context:(__bridge void *)(WRSClientPathDidChangeContext)];
}

- (void)dealloc
{
    _openPanel = nil;
    
    _regions = nil;
    _selectedRegion = nil;
    
    _locales = nil;
    _selectedLocaleIndex = nil;
    
    _clientPath = nil;
    _configDocument = nil;
}

#pragma mark - Actions
- (IBAction)launchDidTouchUpInside:(NSButton *)sender
{
#if 0
    self.configDocument.region = self.selectedRegion;
    self.configDocument.locale = [[self.locales objectsAtIndexes:self.selectedLocaleIndex] firstObject];
    
    [self.configDocument saveToURL:self.configDocument.fileURL ofType:self.configDocument.fileType forSaveOperation:NSSaveOperation completionHandler:^(NSError *errorOrNil) {
        if (errorOrNil) {
            NSAlert * alert = [NSAlert alertWithError:errorOrNil];
            [alert beginSheetModalForWindow:self.view.window completionHandler:NULL];
        }
        // Launch WoW
        
        NSURL * wowURL = [[NSURL fileURLWithPath:self.clientPath] URLByAppendingPathComponent:WoW64AppPathAddition];
        
        NSError * error = nil;
        [[NSWorkspace sharedWorkspace] launchApplicationAtURL:wowURL options:NSWorkspaceLaunchDefault configuration:@{} error:&error];
        if (error) {
            NSAlert * alert = [NSAlert alertWithError:error];
            [alert beginSheetModalForWindow:self.view.window completionHandler:NULL];
        }
    }];
#else
    
    NSURL * wowURL = [[NSURL fileURLWithPath:self.clientPath] URLByAppendingPathComponent:WoW64AppPathAddition];
    
    NSError * error = nil;
    [[NSWorkspace sharedWorkspace] launchApplicationAtURL:wowURL options:NSWorkspaceLaunchDefault
                                            configuration:@{NSWorkspaceLaunchConfigurationArguments:
                                                                @"-launcherlogin -noautolaunch64bit -launch -uid wow_enus -noautolaunch64bit -launch -uid wow_enus"}
                                                    error:&error];
    if (error) {
        NSAlert * alert = [NSAlert alertWithError:error];
        [alert beginSheetModalForWindow:self.view.window completionHandler:NULL];
    }
#endif
}

- (IBAction)changeClientPathDidTouchUpInside:(NSButton *)sender
{
    if (_openPanel == nil) {
        NSOpenPanel * openPanel = [NSOpenPanel openPanel];
        openPanel.delegate = self;
        openPanel.canChooseDirectories = YES;
        openPanel.canChooseFiles = NO;
        _openPanel = openPanel;
    }
    
    __weak NSOpenPanel * weakOpenPanel = self.openPanel;
    [self.openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
        if (result) {
            self.clientPath = [weakOpenPanel.URL path];
        }
    }];
}

#pragma mark - Open Panel Delegate
- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError
{
    NSFileManager * defaultFileManager = [NSFileManager defaultManager];
    
    if ([defaultFileManager fileExistsAtPath:[url URLByAppendingPathComponent:WoW64AppPathAddition].path isDirectory:NULL] ||
        [defaultFileManager fileExistsAtPath:[url URLByAppendingPathComponent:WoWAppPathAddition].path isDirectory:NULL]) {
        return YES;
    }
    
    if (outError) {
        * outError = [NSError errorWithDomain:WRSErrorDomain code:0
                                     userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"INVALID WOW CLIENT PATH", nil)}];
    }
    
    return NO;
}

#pragma mark - Observation
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == (__bridge void *)(WRSClientPathDidChangeContext)) {
        NSString * newPath = [change objectForKey:NSKeyValueChangeNewKey];
        [self handleClientPathChange:newPath];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)handleClientPathChange:(NSString *)newPath
{
    // Scan locales
    NSString * dateFolderPath = [[NSURL fileURLWithPath:newPath] URLByAppendingPathComponent:@"Data"].path;
    
    NSFileManager * manager = [NSFileManager defaultManager];
    NSDirectoryEnumerator * DataDirectoryEnumerator = [manager enumeratorAtPath:dateFolderPath];
    
    NSMutableArray * locales = [NSMutableArray array];
    
    NSString * fileName;
    while ((fileName = [DataDirectoryEnumerator nextObject] )) {
        
        BOOL isFileNameLengthRefersToALocale = (fileName.length == 4);
        
        __block BOOL isFileNameFirstTwoLettersAreLowercase = YES, isFileNameLastTwoLettersAreUppercase = YES;
        
        if (isFileNameLengthRefersToALocale) {
            NSCharacterSet * uppercaseSet = [NSCharacterSet uppercaseLetterCharacterSet];
            NSCharacterSet * lowercaseSet = [NSCharacterSet lowercaseLetterCharacterSet];
            
            NSUInteger characterIndex = 0;
            unichar eachLetter;
            while ((eachLetter = fileName.UTF8String[characterIndex])) {
                
                if (characterIndex < 2) {
                    if (![lowercaseSet characterIsMember:eachLetter]) {
                        isFileNameFirstTwoLettersAreLowercase = NO;
                        break;
                    }
                } else {
                    if (![uppercaseSet characterIsMember:eachLetter]) {
                        isFileNameLastTwoLettersAreUppercase = NO;
                        break;
                    }
                }
                
                characterIndex ++;
            }
        }
        
        //change the suffix to what you are looking for
        if (isFileNameLengthRefersToALocale &&
            isFileNameFirstTwoLettersAreLowercase &&
            isFileNameLastTwoLettersAreUppercase) {
            
            [locales addObject:[[WRSLocale alloc] initWithLocaleString:fileName]];
        }
    }
    self.locales = [locales copy];
    
    // Load Config.wtf
#if 0
    NSURL * configDotWTFPath = [[NSURL fileURLWithPath:self.clientPath] URLByAppendingPathComponent:@"WTF"];
    
    NSDirectoryEnumerator * WTFDirectoryEnumerator = [manager enumeratorAtPath:configDotWTFPath.path];
    
    NSString * fileNameForConfigDotWTF;
    while ((fileNameForConfigDotWTF = [WTFDirectoryEnumerator nextObject] )) {
        if ([fileNameForConfigDotWTF compare:@"Config.wtf" options:(NSCaseInsensitiveSearch)] == NSOrderedSame) {
            break;
        }
    }
    
    if (fileNameForConfigDotWTF) {
        configDotWTFPath = [configDotWTFPath URLByAppendingPathComponent:fileNameForConfigDotWTF];
        
        NSError * documentInitializeError = nil;
        
        WRSConfigDocument * document = [[WRSConfigDocument alloc] initWithContentsOfURL:configDotWTFPath ofType:@"wtf" error:&documentInitializeError];
        self.configDocument = document;
        
        if (documentInitializeError) {
            NSAlert * alert = [NSAlert alertWithError:documentInitializeError];
            [alert beginSheetModalForWindow:self.view.window completionHandler:NULL];
        }
        
    } else {
        NSError * error = [NSError errorWithDomain:WRSErrorDomain code:1
                                          userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"CONFIG.WTF NOT FOUND", nil)}];
        NSAlert * alert = [NSAlert alertWithError:error];
        [alert beginSheetModalForWindow:self.view.window completionHandler:NULL];
    }
    
    self.selectedLocaleIndex = [NSIndexSet indexSetWithIndex:[self.locales indexOfObject:self.configDocument.locale]];
    self.selectedRegion = [self.regions objectAtIndex:[self.regions indexOfObject:self.configDocument.region]];
#endif
}
@end
