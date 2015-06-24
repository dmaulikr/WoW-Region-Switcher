//
//  WRSConfigDocument.h
//  WoW Region Switcher
//
//  Created by Manfred Lau on 8/20/14.
//  Copyright (c) 2014 WeZZard Design. All rights reserved.
//

@import Cocoa;

@class WRSRegion, WRSLocale;

@interface WRSConfigDocument : NSDocument
@property (copy) WRSRegion * region;
@property (copy) WRSLocale * locale;
@end
