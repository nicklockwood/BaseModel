//
//  BaseModel.m
//
//  Version 2.3.3
//
//  Created by Nick Lockwood on 25/06/2011.
//  Copyright 2011 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/BaseModel
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
//  Version 2.1
//
//  Created by Nick Lockwood on 05/01/2012.
//  Copyright 2012 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://gist.github.com/1563325
//

#ifndef ah_retain
#if __has_feature(objc_arc)
#define ah_retain self
#define ah_dealloc self
#define release self
#define autorelease self
#else
#define ah_retain retain
#define ah_dealloc dealloc
#define __bridge
#endif
#endif

//  ARC Helper ends
#import "BaseModel.h"
#import <objc/message.h>
NSString *const BaseModelSharedInstanceUpdatedNotification = @"BaseModelSharedInstanceUpdatedNotification";
@implementation BaseModel

#pragma mark -
#pragma mark Private utility methods

+ (NSString *)resourceFilePath:(NSString *)path
{
    //check if the path is a full path or not
    if (![path isAbsolutePath])
    {
        return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:path];
    }
    return path;
}

+ (NSString *)resourceFilePath
{
    return [self resourceFilePath:[self resourceFile]];
}

+ (NSString *)saveFilePath:(NSString *)path
{
    //check if the path is a full path or not
    if (![path isAbsolutePath])
    {
        //get the path to the application support folder
        NSString *folder = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
        
#ifndef __IPHONE_OS_VERSION_MAX_ALLOWED
        
        //append application name on Mac OS
        NSString *identifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
        folder = [folder stringByAppendingPathComponent:identifier];
        
#endif
        
        //create the folder if it doesn't exist
        if (![[NSFileManager defaultManager] fileExistsAtPath:folder])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:folder
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:NULL];
        }
        
        return [folder stringByAppendingPathComponent:path];
    }
    return path;
}

+ (NSString *)saveFilePath
{
    return [self saveFilePath:[self saveFile]];
}

#pragma mark -
#pragma mark Singleton behaviour

static NSMutableDictionary *sharedInstances = nil;

+ (void)setSharedInstance:(BaseModel *)instance
{
    if (instance && ![instance isKindOfClass:self])
    {
        [NSException raise:NSGenericException format:@"setSharedInstance: instance class does not match"];
    }
    NSString *classKey = NSStringFromClass(self);
    sharedInstances = sharedInstances ?: [[NSMutableDictionary alloc] init];
    id oldInstance = sharedInstances[classKey];
    if (instance)
    {
        sharedInstances[classKey] = instance;
    }
    else
    {
        [sharedInstances removeObjectForKey:classKey];
    }
    if (oldInstance)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:BaseModelSharedInstanceUpdatedNotification object:oldInstance];
    }
}

+ (BOOL)hasSharedInstance
{
    return sharedInstances[NSStringFromClass(self)] != nil;
}

+ (instancetype)sharedInstance
{
    NSString *classKey = NSStringFromClass(self);
    sharedInstances = sharedInstances ?: [[NSMutableDictionary alloc] init];
    id instance = sharedInstances[classKey];
    if (instance == nil)
    {
        //load or create instance
        [self reloadSharedInstance];
        
        //get loaded instance
        instance = sharedInstances[classKey];
    }
    return instance;
}

+ (void)reloadSharedInstance
{
    id instance = nil;
    
    //try loading previously saved version
    instance = [self instanceWithContentsOfFile:[self saveFilePath]];   
    if (instance == nil)
    {
        //construct a new instance
        instance = [self instance];
    }
    
    //set singleton
    [self setSharedInstance:instance];
}

+ (NSString *)resourceFile
{
    //used for every instance
    return [NSStringFromClass(self) stringByAppendingPathExtension:@"plist"];
}

+ (NSString *)saveFile
{
    //used to save shared (singleton) instance
    return [NSStringFromClass(self) stringByAppendingPathExtension:@"plist"];
}

- (BOOL)useHRCoderIfAvailable
{
    return YES;
}

- (void)save
{
    if (sharedInstances[NSStringFromClass([self class])] == self)
    {
        //shared (singleton) instance
        [self writeToFile:[[self class] saveFilePath] atomically:YES];
    }
    else
    {
        //no save implementation
        [NSException raise:NSGenericException format:@"Unable to save object, save method not implemented"];
    }
}

#pragma mark -
#pragma mark Default constructors

- (void)setUp
{
    //override this
}

+ (instancetype)instance
{
    return [[[self alloc] init] autorelease];
}

static BOOL loadingFromResourceFile = NO;

- (instancetype)init
{
    @synchronized ([BaseModel class])
    {
//        if (!loadingFromResourceFile)
//        {
            //attempt to load from resource file
//            loadingFromResourceFile = YES;
//            id object = [[[self class] alloc] initWithContentsOfFile:[[self class] resourceFilePath]];
//            loadingFromResourceFile = NO;
//            if (object)
//            {
//                [self release];
//                self = object;
//                return self;
//            }
//        }
        if ((self = [super init]))
        {
            
#ifdef DEBUG
            if ([self class] == [BaseModel class])
            {
                [NSException raise:NSGenericException format:@"BaseModel class is abstract and should be subclassed rather than instantiated directly"];
            }
#endif
            [self setUp];
        }
        return self;
    }
}

+ (instancetype)instanceWithObject:(id)object
{
    //return nil if object is nil
    return object? [[[self alloc] initWithObject:object] autorelease]: nil;
}

- (NSString *)setterNameForClass:(Class)class
{
    //get class name
    NSString *className = NSStringFromClass(class);
    
    //strip NS prefix
    if ([className hasPrefix:@"NS"])
    {
        className = [className substringFromIndex:2];
    }
    
    //return setter name
    return [NSString stringWithFormat:@"setWith%@:", className];
}

- (instancetype)initWithObject:(id)object
{
    if ((self = [self init]))
    {
        Class class = [object class];
        while (true)
        {
            SEL setter = NSSelectorFromString([self setterNameForClass:class]);
            if ([self respondsToSelector:setter])
            {
                objc_msgSend(self, setter, object);
                return self;
            }
            if ([class superclass] == [NSObject class]) break;
            class = [class superclass];
        }
        [NSException raise:NSGenericException
                    format:@"%@ not implemented", [self setterNameForClass:class]];
    }
    return self;
}

+ (NSArray *)instancesWithArray:(NSArray *)array
{
    NSMutableArray *result = [NSMutableArray array];
    for (id object in array)
    {
        [result addObject:[self instanceWithObject:object]];
    }
    return result;
}

+ (instancetype)instanceWithCoder:(NSCoder *)decoder
{
    //return nil if coder is nil
    return decoder? [[[self alloc] initWithCoder:decoder] autorelease]: nil;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if ((self = [self init]))
    {
        if ([self respondsToSelector:@selector(setWithCoder:)])
        {
            [self setWithCoder:decoder];
        }
        else
        {
            [NSException raise:NSGenericException format:@"setWithCoder: not implemented"];
        }
    }
    return self;
}

+ (instancetype)instanceWithContentsOfFile:(NSString *)filePath
{
//	[NSThread stackTrace];
	return nil;
}
/*
	//check if the path is a full path or not
    NSString *path = filePath;
    if (![path isAbsolutePath])
    {
        //try resources
        path = [self resourceFilePath:filePath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            //try application support
            path = [self saveFilePath:filePath];
        }
    }

    return [[[self alloc] initWithContentsOfFile:path] autorelease];
}
*/

- (instancetype)initWithContentsOfFile:(NSString *)filePath
{
//	[NSThread stackTrace];
	return nil;
}

/*
    static NSCache *cachedResourceFiles = nil;
    if (cachedResourceFiles == nil)
    {
        cachedResourceFiles = [[NSCache alloc] init];
    }
    
    //check cache for existing instance
    //only cache files inside the main bundle as they are immutable 
    BOOL isResourceFile = [filePath hasPrefix:[[NSBundle mainBundle] bundlePath]];
    if (isResourceFile)
    {
        id object = cachedResourceFiles[filePath];
        if (object)
        {
            [self release];
            return ((self = (object == [NSNull null])? nil: [object ah_retain]));
        }
    }
    
    //load the file
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    
    //attempt to deserialise data as a plist
    id object = nil;
    if (data)
    {
        NSPropertyListFormat format;
        NSPropertyListReadOptions options = NSPropertyListMutableContainersAndLeaves;
        object = [NSPropertyListSerialization propertyListWithData:data options:options format:&format error:NULL];
    }
        
    //success?
    if (object)
    {
        //check if object is an NSCoded archive
        if ([object respondsToSelector:@selector(objectForKey:)])
        {
            if (object[@"$archiver"])
            {
                Class coderClass = NSClassFromString(@"CryptoCoder");
                if (!coderClass)
                {
                    coderClass = [NSKeyedUnarchiver class];
                }
                object = [coderClass unarchiveObjectWithData:data];
            }
            else
            {
                Class HRCoderClass = NSClassFromString(@"HRCoder");
                NSString *classNameKey = [HRCoderClass valueForKey:@"classNameKey"];
                if (object[classNameKey])
                {
                    object = objc_msgSend(HRCoderClass, @selector(unarchiveObjectWithPlist:), object);
                }
            }
            
            if ([object isKindOfClass:[self class]])
            {
                //return object
                [self release];
                return ((self = [object ah_retain]));
            }
        }

        if (isResourceFile)
        {
            //cache for next time
            cachedResourceFiles[filePath] = object;
        }
        
        //load with object
        return ((self = [self initWithObject:object]));
    }
    else if (isResourceFile)
    {
        //store null for non-existent files to improve performance next time
        cachedResourceFiles[filePath] = [NSNull null];
    }
    
    //failed to load
    [self release];
    return ((self = nil));
}

- (void)writeToFile:(NSString *)path atomically:(BOOL)atomically
{
    NSData *data = nil;
    Class CryptoCoderClass = NSClassFromString(@"CryptoCoder");
    Class HRCoderClass = NSClassFromString(@"HRCoder");
    if (CryptoCoderClass && [[self class] respondsToSelector:@selector(CCPassword)])
    {
        data = [CryptoCoderClass archivedDataWithRootObject:self];
    }
    else if (HRCoderClass && [self useHRCoderIfAvailable])
    {
        id plist = objc_msgSend(HRCoderClass, @selector(archivedPlistWithRootObject:), self);
        NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
        data = [NSPropertyListSerialization dataWithPropertyList:plist format:format options:0 error:NULL];
    }
    else
    {
        data = [NSKeyedArchiver archivedDataWithRootObject:self];
    }
    [data writeToFile:[[self class] saveFilePath:path] atomically:YES];
}
*/

#pragma mark -
#pragma mark Unique identifier generation

+ (NSString *)newUniqueIdentifier
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef identifier = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return [CFBridgingRelease(identifier) ah_retain];
}

//#ifdef BASEMODEL_ENABLE_UNIQUE_ID

@synthesize uniqueID = _uniqueID;

- (NSString *)uniqueID
{
    if (_uniqueID == nil)
    {
        _uniqueID = [[self class] newUniqueIdentifier];
    }
    return _uniqueID;
}

- (void)dealloc
{
    [_uniqueID release];
    [super ah_dealloc];
}

//#endif

@end

