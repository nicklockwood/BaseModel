//
//  BaseModel.m
//
//  Version 2.0
//
//  Created by Nick Lockwood on 25/06/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//
//  Get the latest version of BaseModel from either of these locations:
//
//  http://charcoaldesign.co.uk/source/cocoa#basemodel
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

#import "BaseModel.h"
#include <sys/xattr.h>


#define MAXIMUM_CACHABLE_DATA_SIZE (1024 * 10)
#define MAXIMUM_CACHABLE_COLLECTION_SIZE 1024


NSString *const BaseModelSharedInstanceUpdatedNotification = @"BaseModelSharedInstanceUpdatedNotification";


@implementation NSObject (BaseModel)

static NSCache *cachedResourceFiles = nil;

+ (id)objectWithContentsOfFile:(NSString *)filePath
{   
    //check cache for existing instance
	//only cache files inside the main bundle as they are immutable 
    BOOL isResourceFile = [filePath hasPrefix:[[NSBundle mainBundle] bundlePath]];
    if (isResourceFile)
    {
		cachedResourceFiles = cachedResourceFiles ?: [[NSCache alloc] init];
        id object = [cachedResourceFiles objectForKey:filePath];
		if (object)
		{
			return (object == [NSNull null])? nil: object;
		}
    }
    
    //load the file
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    
    //attempt to deserialise data as a plist
    id object = nil;
    if (data)
    {
        NSPropertyListFormat format;
        if ([NSPropertyListSerialization respondsToSelector:@selector(propertyListWithData:options:format:error:)])
        {
            object = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&format error:NULL];
        }
        else
        {
            object = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:&format errorDescription:NULL];
        }
		
		//success?
		if (object)
		{
			//check if object is an NSCoded unarchive
			if ([object respondsToSelector:@selector(objectForKey:)] && [object objectForKey:@"$archiver"])
			{
				object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			}
		}
		else
		{
			//return raw data
			object = data;
		}
    }
    
    //cache object if immutable
    if (isResourceFile)
    {
        if (object == nil)
        {
            //store null for non-existent files to improve performance next time
            [cachedResourceFiles setObject:[NSNull null] forKey:filePath];
        }
		else if (([object isKindOfClass:[NSData class]] && [object length] < MAXIMUM_CACHABLE_DATA_SIZE) ||
                ([object isKindOfClass:[NSString class]] && [object length] < MAXIMUM_CACHABLE_DATA_SIZE) ||
                ([object isKindOfClass:[NSArray class]] && [object count] < MAXIMUM_CACHABLE_COLLECTION_SIZE) ||
        		([object isKindOfClass:[NSDictionary class]] && [object count] < MAXIMUM_CACHABLE_COLLECTION_SIZE))
        {
            //copy object before caching to enforce immutability
            object = [[object copy] autorelease];
        	[cachedResourceFiles setObject:object forKey:filePath];
        }
    }
    
	//return object
	return object;
}

- (void)writeToFile:(NSString *)filePath atomically:(BOOL)useAuxiliaryFile
{
    //note: NSData, NSDictionary and NSArray already implement this method
    
    if ([self isKindOfClass:[NSString class]])
    {
        //save as UTF8 text
        [(NSString *)self writeToFile:filePath atomically:useAuxiliaryFile encoding:NSUTF8StringEncoding error:NULL];
    }
    else if ([self conformsToProtocol:@protocol(NSCoding)])
    {
        //archive object
		//TODO: use auxiliary file
        [NSKeyedArchiver archiveRootObject:self toFile:filePath];
    }
    else
    {
        //give up
        [NSException raise:NSGenericException
                    format:@"Unable to save object, does not conform to NSCoding"];
    }
}
    
@end


@implementation BaseModel

@synthesize uniqueID = uniqueID;


#pragma mark -
#pragma mark Private utility methods

+ (NSString *)resourceFilePath
{
	//check if the path is a full path or not
	if (![[self resourceFile] isAbsolutePath])
	{
		return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[self resourceFile]];
	}
	return [self resourceFile];
}

+ (NSString *)saveFilePath
{
	//check if the path is a full path or not
	if (![[self saveFile] isAbsolutePath])
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
		
		return [folder stringByAppendingPathComponent:[self saveFile]];
	}
	return [self saveFile];
}

#pragma mark -
#pragma mark Singleton behaviour

static NSMutableDictionary *sharedInstances = nil;

+ (void)setSharedInstance:(BaseModel *)instance
{
	if (![instance isKindOfClass:self])
	{
		[NSException raise:NSGenericException
					format:@"setSharedInstance: instance class does not match"];
	}
	sharedInstances = sharedInstances ?: [[NSMutableDictionary alloc] init];
	id oldInstance = [[[sharedInstances objectForKey:NSStringFromClass(self)] retain] autorelease];
	[sharedInstances setObject:instance forKey:NSStringFromClass(self)];
	if (oldInstance)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:BaseModelSharedInstanceUpdatedNotification object:oldInstance];
	}
}

+ (BOOL)hasSharedInstance
{
	return [sharedInstances objectForKey:NSStringFromClass(self)] != nil;
}

+ (id)sharedInstance
{
	sharedInstances = sharedInstances ?: [[NSMutableDictionary alloc] init];
	id instance = [sharedInstances objectForKey:NSStringFromClass(self)];
	if (instance == nil)
	{
		//load or create instance
		[self reloadSharedInstance];
		
		//get loaded instance
		instance = [sharedInstances objectForKey:NSStringFromClass(self)];
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

- (void)save
{
	if ([sharedInstances objectForKey:NSStringFromClass([self class])] == self)
	{
		//shared (singleton) instance
		[self writeToFile:[[self class] saveFilePath] atomically:YES];
	}
	else
	{
		//no save implementation
		[NSException raise:NSGenericException
					format:@"Unable to save object, save method not implemented"];
	}
}


#pragma mark -
#pragma mark Default constructors

- (void)setUp
{
	//override this
}

+ (id)instance
{
    return [[[self alloc] init] autorelease];
}

static BOOL loadingFromResourceFile = NO;

- (id)init
{
	@synchronized ([BaseModel class])
	{
		if (!loadingFromResourceFile)
		{
			//attempt to load from resource file
			loadingFromResourceFile = YES;
			id object = [[self class] instanceWithContentsOfFile:[[self class] resourceFilePath]];
			loadingFromResourceFile = NO;
			if (object)
			{
				[self release];
				self = [object retain];
				return self;
			}
		}
		if ((self = [super init]))
		{
			if ([self class] == [BaseModel class])
			{
				[NSException raise:NSGenericException
							format:@"BaseModel class is abstract and should be subclassed rather than instantiated directly"];
			}
			
			[self setUp];
			
			//clean up parent references
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateParent:) name:BaseModelSharedInstanceUpdatedNotification object:nil];
		}
		return self;
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [self init]))
	{
        if ([self respondsToSelector:@selector(setWithCoder:)])
        {
            [self setWithCoder:aDecoder];
        }
        else
        {
            [NSException raise:NSGenericException
                        format:@"-setWithCoder: not implemented"];
        }
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[NSException raise:NSGenericException
				format:@"-encodeWithCoder: not implemented"];
}

+ (id)instanceWithDictionary:(NSDictionary *)dict
{
    //return nil if dict is nil
	return dict? [[[self alloc] initWithDictionary:dict] autorelease]: nil;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	if ((self = [self init]))
	{
		[self setUp];
        if ([self respondsToSelector:@selector(setWithDictionary:)])
        {
            [self setWithDictionary:dict];
        }
        else
        {
            [NSException raise:NSGenericException
                        format:@"setWithDictionary: not implemented"];
        }
	}
	return self;
}

+ (id)instanceWithArray:(NSArray *)array
{
    //return nil if array is nil
    return array? [[[self alloc] initWithArray:array] autorelease]: nil;
}

- (id)initWithArray:(NSArray *)array
{
    if ((self = [self init]))
	{
		[self setUp];
        if ([self respondsToSelector:@selector(setWithArray:)])
        {
            [self setWithArray:array];
        }
        else
        {
            [NSException raise:NSGenericException
                        format:@"setWithArray: not implemented"];
        }
	}
	return self;
}

+ (id)instanceWithContentsOfFile:(NSString *)filePath
{
	return [[[self alloc] initWithContentsOfFile:filePath] autorelease];
}

- (id)initWithContentsOfFile:(NSString *)filePath
{
	//load object
	id object = [NSObject objectWithContentsOfFile:filePath];
	
	if ([object isKindOfClass:[self class]])
	{
		//return object
		[self release];
		return [object retain];
	}
	
    if ([object isKindOfClass:[NSDictionary class]])
	{
		//load as dictionary
        return [self initWithDictionary:object];
	}
	
	if ([object isKindOfClass:[NSArray class]])
    {
		//load as array
        return [self initWithArray:object];
    }
	
	//failed to load
    [self release];
    return nil;
}

- (NSString *)uniqueID
{
    if (uniqueID == nil)
    {
    	CFUUIDRef uuid = CFUUIDCreate(NULL);
    	uniqueID = (NSString *)CFUUIDCreateString(NULL, uuid);
    	CFRelease(uuid);
    }
    return uniqueID;
}

- (void)dealloc
{
    [uniqueID release];
    [super dealloc];
}

@end