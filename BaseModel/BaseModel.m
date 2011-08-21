//
//  BaseModel.m
//
//  Version 1.1
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


@implementation BaseModel


#pragma mark -
#pragma mark Default constructors

//this is the designated initialiser
//every class should have a designated initaliser which is called
//by every other initialiser. usually this is the standard init method.
//if you don't want init to be your designated constructor, you might want
//to throw an exception in the init method so people don't call it by
//accident (init is inherited from NSObject, so it's always available even
//if you don't define it yourself)


+ (id)instance
{
	return [[[self alloc] init] autorelease];
}

- (id)init
{
	if ((self = [super init]))
	{
		//initialise common properties here, e.g.
		//someProperty = [[NSObject alloc] init];
	}
	return self;
}

- (void)dealloc
{
	//release any model properties, e.g.
	//[someProperty release];
	[super dealloc];
}


#pragma mark -
#pragma mark Loading and saving to an NSCoded plist file

//if your model is immutable - i.e. it isn't modifed at runtime, then
//you don't need to implement this stuff. you might want this for
//models where the user can modify the data and save it, or for models
//that are downloaded from a web service and need to be saved locally


- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [self init]))
	{
		////in the real implementation you would load propeties from the decoder object, e.g.
		//self.someProperty = [aDecoder decodeObjectForKey:@"someProperty"];
		[NSException raise:NSGenericException
					format:@"Abstract -initWithCoder implementation - you need to override this"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	////in the real implementation you would write properties to the coder object, e.g.
	//[aCoder encodeObject:someProperty forKey:@"someProperty"];
	[NSException raise:NSGenericException
				format:@"Abstract -encodeWithCoder implementation - you need to override this"];
}


#pragma mark -
#pragma mark Loading from a dictionary

//these methods initialise the object from a dictionary
//this is handy because it allows the object to be loaded from
//a plist file (useful for loading objects from the bundle) or
//from a json file (useful for downloading objects from a web service).
//note that there is no 'saveToDict' method - generally it's much better
//to use NSCoding to save objects because it's faster and produces
//simpler code since you can save objects directly in the plist instead
//of converting to and from dictionaries. note also that the initWithDict
//method calls [self init], not [super init] because we still want to
//invoke our designated initialiser


+ (id)instanceWithDict:(NSDictionary *)dict
{
    //return nil if dict is nil
	return dict? [[[self alloc] initWithDict:dict] autorelease]: nil;
}

- (id)initWithDict:(NSDictionary *)dict
{
	if ((self = [self init]))
	{
        //in the real implementation, you would set properties from dictionary, e.g.
		//self.someProperty = [dictionary objectForKey:@"someProperty"];
        [NSException raise:NSGenericException
                    format:@"Abstract -initWithDict implementation - you need to override this"];
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
        //in the real implementation, you would set a property from the array, e.g.
		//self.items = [[array mutableCopy] autorelease];
        [NSException raise:NSGenericException
                    format:@"Abstract -initWithDict implementation - you need to override this"];
	}
	return self;
}


#pragma mark -
#pragma mark Merging

//this method is for merging model objects
//it is useful for cases where a model object is initialised from data in the app
//and then need

- (id)mergeWithObject:(id)object
{
    //return the result of merging object into self
    return nil;
}

@end


@implementation BaseModel(Files)


#pragma mark -
#pragma mark Filesystem functions

//these utility methods make it easier to work with files from within
//your model. they assume that paths are relative to the application
//support folder unless otherwise specified, so you can save effort on
//building path strings. objects will automatically be saved and loaded
//using whatever mechanism seems appropriate based on the extension and
//data format

+ (NSString *)applicationFolderForSearchPath:(NSSearchPathDirectory)searchPath appendAppName:(BOOL)appendAppName
{
    //get the path to the folder
	NSString *folder = [NSSearchPathForDirectoriesInDomains(searchPath, NSUserDomainMask, YES) objectAtIndex:0];
    
#ifndef __IPHONE_OS_VERSION_MAX_ALLOWED
    
    if (appendAppName)
    {
        //append application name on Mac OS, which doesn't have a sandboxed file system
        NSString *identifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
        folder = [folder stringByAppendingPathComponent:identifier];
	}
    
#endif
    
    //create the folder if it doesn't exist
	if (![[NSFileManager defaultManager] fileExistsAtPath:folder])
    {
		[[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	return folder;
}

+ (NSString *)cachesFolder
{
    //get the path to the application caches folder
    return [self applicationFolderForSearchPath:NSCachesDirectory appendAppName:YES];
}

+ (NSString *)documentsFolder
{
    //get the path to the application documents folder
	return [self applicationFolderForSearchPath:NSDocumentDirectory appendAppName:NO];
}

+ (NSString *)applicationSupportFolder
{
    //get the application support directory
	return [self applicationFolderForSearchPath:NSApplicationSupportDirectory appendAppName:NO];
}

+ (NSString *)saveFilePath:(NSString *)filePath
{
	//check if the path is a full path or not
	if (![filePath isAbsolutePath])
	{
		return [[self applicationSupportFolder] stringByAppendingPathComponent:filePath];
	}
	return filePath;
}

+ (NSString *)bundleFilePath:(NSString *)filePath
{
	//check if the path is a full path or not
	if (![filePath isAbsolutePath])
	{
		return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filePath];
	}
	return filePath;
}

+ (NSString *)saveOrBundleFilePath:(NSString *)filePath
{
	//first, check in the application support folder
    NSString *fullPath = [[self applicationSupportFolder] stringByAppendingPathComponent:filePath];
		
    //check if file exists, if not, look in the application bundle
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath])
    {
        fullPath = [self bundleFilePath:filePath];
    }

    //return path
	return fullPath;
}

- (BOOL)fileExistsAtPath:(NSString *)filePath
{
	return [[NSFileManager defaultManager] fileExistsAtPath:[[self class] saveFilePath:filePath]];
}

- (void)removeFileAtPath:(NSString *)filePath
{
	[[NSFileManager defaultManager] removeItemAtPath:[[self class] saveFilePath:filePath] error:NULL];
}

- (void)writeObject:(id)object toFile:(NSString *)filePath
{
	//check if the path is a full path or not
	//if not, assume we want to look in the application support folder
	filePath = [[self class] saveFilePath:filePath];
	
	if ([object isKindOfClass:[NSDictionary class]] ||
		[object isKindOfClass:[NSArray class]] ||
		[object isKindOfClass:[NSData class]])
	{
		//save as plist or raw data
		[object writeToFile:filePath atomically:YES];
	}
	else if ([object isKindOfClass:[NSString class]])
	{
		//save as UTF8 text
		[object writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	}
	else if ([object conformsToProtocol:@protocol(NSCoding)])
	{
		//archive object
		[NSKeyedArchiver archiveRootObject:self toFile:filePath];
	}
	else
	{
		//give up
		[NSException raise:NSGenericException
                    format:@"Unable to save object - not a known format"];
	}
}

- (id)objectWithContentsofFile:(NSString *)filePath
{
	//get full path
	filePath = [[self class] saveOrBundleFilePath:filePath];
    
    //load the file
    NSData *data = [NSData dataWithContentsOfFile:filePath];

    //attempt to deserialise data as a plist
    id object = nil;
    if (data)
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSPropertyListFormat format;
        if ([NSPropertyListSerialization respondsToSelector:@selector(propertyListWithData:options:format:error:)])
        {
            object = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&format error:NULL];
        }
        else
        {
            object = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:0 format:&format errorDescription:NULL];
        }
        [object retain];
        [pool drain];
    }
    
    //success?
    if (object)
    {
        //check if object is an NSCoded unarchive
        if ([object respondsToSelector:@selector(objectForKey:)] && [object objectForKey:@"$archiver"])
        {
            [object release];
            return [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        
        //return object
        return [object autorelease];
    }

	//treat the raw data
	return data;
}


#pragma mark -
#pragma mark Loading and saving from a plist file

//if your model is immutable - i.e. it isn't modifed at runtime, then
//you don't need to implement this stuff. you might want this for
//models where the user can modify the data and save it, or for models
//that are downloaded from a web service and need to be cached


+ (id)instanceWithContentsOfFile:(NSString *)filePath
{
	return [[self alloc] initWithContentsOfFile:filePath];
}

- (id)initWithContentsOfFile:(NSString *)filePath
{
	//load object
	id object = [self objectWithContentsofFile:filePath];
	
	if ([object isKindOfClass:[self class]])
	{
		//return object
		[self release];
		return [object retain];
	}
	
    if ([object isKindOfClass:[NSDictionary class]])
	{
		//load as dictionary
        return [self initWithDict:object];
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

- (void)writeToFile:(NSString *)filePath
{	
	[self writeObject:self toFile:filePath];
}

@end


@implementation BaseModel(Singletons)


#pragma mark -
#pragma mark Configuration methods

//these methods set the filenames used for saving and loading the
//singleton. override these with you own implementation


+ (NSString *)resourceFile
{
	//override this method if you want to load your
	//singleton from a file in the application bundle resources
	return nil;
}

+ (NSString *)saveFile
{
	//override this method if you want to save or load
	//your singleton from a file in the application support folder
	return nil;
}


#pragma mark -
#pragma mark Shared storage

//because the BaseModel is designed to be subclassed
//we need to do something clever with shared instances or multiple
//subclasses of BaseModel would all share the same static instance,
//which probably isn't what we want!


static NSMutableDictionary *sharedStorage = nil;

+ (void)initialize
{
	sharedStorage = [[NSMutableDictionary alloc] init];
}

+ (NSMutableDictionary *)classStorage
{
	NSString *className = NSStringFromClass([self class]);
	NSMutableDictionary *storage = [sharedStorage objectForKey:className];
	if (storage == nil)
	{
		storage = [NSMutableDictionary dictionary];
		[sharedStorage setObject:storage forKey:className];
	}
	return storage;
}

+ (id)objectForKey:(NSString *)key
{
	return [[self classStorage] objectForKey:key];
}

+ (void)setObject:(id)object forKey:(NSString *)key
{
	return [[self classStorage] setObject:object forKey:key];
}


#pragma mark -
#pragma mark Singleton methods

//these methods only apply to 'master objects' such as the container
//object for your application's entire data model. if the model
//object in question is a child property of another model, it doesn't make
//sense to implement it as a singleton. the sharedInstance method here is not
//thread safe; it can be made thread safe by doing some crazy stuff with
//grand central dispatch and blocks, but generally it's a bad idea to be
//accessing shared data from multiple threads anyway, so my advice it to keep it
//simple and only access your singletons from the main thread. you can also run
//into trouble if you try to call the singleton from a method that is triggered
//from within the singleton's own initialisation, so try not to have too many
//dependencies in your loading code


static NSMutableDictionary *sharedInstances = nil;

+ (id)sharedInstance
{
	if (sharedInstances == nil)
	{
		sharedInstances = [[NSMutableDictionary alloc] init];
	}
	
	id instance = [sharedInstances objectForKey:NSStringFromClass(self)];
	if (instance == nil)
	{
		//load data
		[self reload];
		instance = [sharedInstances objectForKey:NSStringFromClass(self)];
	}
	
	return instance;
}

+ (void)reload
{
	id instance = nil;
	if ([self saveFile])
	{
		//try loading previously saved version
		instance = [self instanceWithContentsOfFile:[self saveFilePath:[self saveFile]]];
	}

    BOOL shouldMerge = instance && [self instancesRespondToSelector:@selector(mergeValuesFromObject:)];
	if ((instance == nil || shouldMerge) && [self resourceFile])
	{
		//load from bundle resources
        id savedInstance = instance;
		instance = [self instanceWithContentsOfFile:[self bundleFilePath:[self resourceFile]]];
        
        //merging
        if (shouldMerge)
        {
            if (shouldMerge && instance)
            {
                [instance mergeValuesFromObject:savedInstance];
            }
            else
            {
                instance = savedInstance;
            }
        }
	}
	
	if (instance == nil)
	{
		//construct a new instance
		instance = [self instance];
	}
	
	//set singleton
	[sharedInstances setObject:instance forKey:NSStringFromClass(self)];
}

+ (void)save
{
	//can't save if saveFile path is not set
	if ([self saveFile] == nil)
	{
		[NSException raise:NSGenericException
					format:@"Abstract +saveFile implementation - you need to override this to save files"];
	}
	
	//save the shared instance
	[[self sharedInstance] writeToFile:[self saveFilePath:[self saveFile]]];
}

@end