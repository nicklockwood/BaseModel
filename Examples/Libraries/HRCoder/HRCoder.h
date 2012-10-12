//
//  HRCoder.h
//
//  Version 1.0
//
//  Created by Nick Lockwood on 24/04/2012.
//  Copyright (c) 2011 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/HRCoder
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

//
//  ARC Helper
//
//  Version 1.3
//
//  Created by Nick Lockwood on 05/01/2012.
//  Copyright 2012 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://gist.github.com/1563325
//

#ifndef AH_RETAIN
#if __has_feature(objc_arc)
#define AH_RETAIN(x) (x)
#define AH_RELEASE(x) (void)(x)
#define AH_AUTORELEASE(x) (x)
#define AH_SUPER_DEALLOC (void)(0)
#define __AH_BRIDGE __bridge
#else
#define __AH_WEAK
#define AH_WEAK assign
#define AH_RETAIN(x) [(x) retain]
#define AH_RELEASE(x) [(x) release]
#define AH_AUTORELEASE(x) [(x) autorelease]
#define AH_SUPER_DEALLOC [super dealloc]
#define __AH_BRIDGE
#endif
#endif

//  ARC Helper ends
#import <Foundation/Foundation.h>
static NSString *const HRCoderClassNameKey = @"$class";
static NSString *const HRCoderRootObjectKey = @"$root";
static NSString *const HRCoderObjectAliasKey = @"$alias";
@interface HRCoderAliasPlaceholder : NSObject

+ (HRCoderAliasPlaceholder *)placeholder;

@end
@interface HRCoder : NSCoder

+ (id)unarchiveObjectWithPlist:(id)plist;
+ (id)unarchiveObjectWithFile:(NSString *)path;
+ (id)archivedPlistWithRootObject:(id)object;
+ (BOOL)archiveRootObject:(id)rootObject toFile:(NSString *)path;

- (id)unarchiveObjectWithPlist:(id)plist;
- (id)unarchiveObjectWithFile:(NSString *)path;
- (id)archivedPlistWithRootObject:(id)object;
- (BOOL)archiveRootObject:(id)rootObject toFile:(NSString *)path;

@end