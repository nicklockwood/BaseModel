/**
  BaseModel.m

  Version 2.4.4

  Created by Nick Lockwood on 25/06/2011.
  Copyright 2011 Charcoal Design

  Distributed under the permissive zlib license
  Get the latest version from here:

  https://github.com/nicklockwood/BaseModel

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
  claim that you wrote the original software. If you use this software
  in a product, an acknowledgment in the product documentation would be
  appreciated but is not required.

  2. Altered source versions must be plainly marked as such, and must not be
  misrepresented as being the original software.

  3. This notice may not be removed or altered from any source distribution.  */


#import "BaseModel.h"
#include <objc/objc-class.h>

#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


NSString *const BaseModelSharedInstanceUpdatedNotification = @"BaseModelSharedInstanceUpdatedNotification";

static NSString 	*const BaseModelSharedInstanceKey = @"sharedInstance",
						*const BaseModelLoadingFromResourceFileKey = @"loadingFromResourceFile";

@implementation BaseModel

#pragma mark - Private utility methods

+ (NSString*) BaseModel_resourceFilePath:(NSString*)path {

	return path.isAbsolutePath ? path  	//check if the path is a full path or not
										: [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:path];
}
+ (NSString*) BaseModel_resourceFilePath						{

	return [self BaseModel_resourceFilePath:self.resourceFile];
}
+ (NSString*) BaseModel_saveFilePath:	  (NSString*)path	{

	if (path.isAbsolutePath) return path; 	//check if the path is a full path or not
	//get the path to the application support folder
	NSString *folder = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];

#ifndef __IPHONE_OS_VERSION_MAX_ALLOWED

	//append application name on Mac OS
	NSString *identifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey];
	folder = [folder stringByAppendingPathComponent:identifier];

#endif

	//create the folder if it doesn't exist
	if (![NSFileManager.defaultManager fileExistsAtPath:folder])
		[NSFileManager.defaultManager createDirectoryAtPath:folder
										withIntermediateDirectories:YES
															  attributes:nil
																	 error:NULL];

	return [folder stringByAppendingPathComponent:path];
}
+ (NSString*) BaseModel_saveFilePath							{	return [self BaseModel_saveFilePath:self.saveFile];	}

static NSMutableDictionary *classValues = nil;

+   (id) BaseModel_classPropertyForKey:					  (NSString*)key	{

	return classValues[NSStringFromClass(self)][key];
}
+ (void) BaseModel_setClassProperty:(id)property forKey:(NSString*)key	{

	@synchronized (BaseModel.class)
	{
		if (!classValues) classValues = NSMutableDictionary.new;
		NSMutableDictionary *values = classValues[NSStringFromClass(self)];
		if (!values)
			classValues[NSStringFromClass(self)] = (values = NSMutableDictionary.new);
		if (property)	values[key] = property;
		else				[values removeObjectForKey:key];
	}
}

#pragma mark - Singleton behaviour

+ (instancetype) sharedInstance									{

	@synchronized (self.class)
	{
		id instance = [self BaseModel_classPropertyForKey:BaseModelSharedInstanceKey];
		if (instance != nil) return instance;
		[self reloadSharedInstance]; 		//load or create instance
		//get loaded instance
		return [self BaseModel_classPropertyForKey:BaseModelSharedInstanceKey];
	}
}
+         (void) setSharedInstance:(BaseModel*)instance	{

	@synchronized (self.class)
	{
		if (instance && ![instance isKindOfClass:self])
			[NSException raise:NSGenericException format:@"setSharedInstance: instance class does not match"];

		id oldInstance = [self BaseModel_classPropertyForKey:BaseModelSharedInstanceKey];
		[self BaseModel_setClassProperty:instance forKey:BaseModelSharedInstanceKey];
		if (oldInstance)
			[NSNotificationCenter.defaultCenter postNotificationName:BaseModelSharedInstanceUpdatedNotification
																			  object:oldInstance];
	}
}
+         (BOOL) hasSharedInstance								{

	return [self BaseModel_classPropertyForKey:BaseModelSharedInstanceKey] != nil;
}
+         (void) reloadSharedInstance							{

	@synchronized (self.class)
	{
		id instance = nil;
		//try loading previously saved version
		instance = [self instanceWithContentsOfFile:self.BaseModel_saveFilePath];
		[self setSharedInstance:instance ?: self.instance];
		//set singleton
	}
}
+    (NSString*) resourceFile										{

	//used for every instance
	return [NSStringFromClass(self) stringByAppendingPathExtension:@"plist"];
}
+    (NSString*) saveFile											{

	//used to save shared (singleton) instance
	return [NSStringFromClass(self) stringByAppendingPathExtension:@"plist"];
}
-         (BOOL) useHRCoderIfAvailable							{	return YES;	}
-         (void) save												{

	[self.class BaseModel_classPropertyForKey:BaseModelSharedInstanceKey] == self
	?	//shared (singleton) instance
		[self writeToFile:self.class.BaseModel_saveFilePath atomically:YES]
	: 	//no save implementation
		[NSException raise:NSGenericException format:@"Unable to save object, save method not implemented"];
}

#pragma mark - Default constructors

- 	       (void) setUp		{

	//override this
}
+ (instancetype) instance	{	return self.new;	}
- (instancetype) init		{

	@synchronized (self.class)
	{
		if (![[self.class BaseModel_classPropertyForKey:BaseModelLoadingFromResourceFileKey] boolValue])
		{
			//attempt to load from resource file
			[self.class BaseModel_setClassProperty:@YES forKey:BaseModelLoadingFromResourceFileKey];
			id object = [self.class.alloc initWithContentsOfFile:[self.class BaseModel_resourceFilePath]];
			[self.class BaseModel_setClassProperty:nil forKey:BaseModelLoadingFromResourceFileKey];
			if (object) return ((self = object));
		}
		if ((self = super.init))
		{
			if (self.class == BaseModel.class)
				[NSException raise:NSGenericException format:@"BaseModel class is abstract and should be subclassed rather than instantiated directly"];
			[self setUp];
		}
		return self;
	}
}
+ (instancetype) instanceWithObject:(id)object		{

	return object ? [self.alloc initWithObject:object]: nil; 	//return nil if object is nil
}
-    (NSString*) setterNameForClass:(Class)class	{

	//get class name
	NSString *className = NSStringFromClass(class);

	//strip NS prefix
	if ([className hasPrefix:@"NS"])
		className = [className substringFromIndex:2];
	//return setter name
	return [NSString stringWithFormat:@"setWith%@:", className];
}
- (instancetype) initWithObject:		(id)object		{

	if ((self = self.init))
	{
		Class class = [object class];
		while (true)
		{
			SEL setter = NSSelectorFromString([self setterNameForClass:class]);
			if ([self respondsToSelector:setter])
			{
				((void (*)(id, SEL, id))objc_msgSend)(self, setter, object);
				return self;
			}
			if (class.superclass == NSObject.class) break;
			class = class.superclass;
		}
		[NSException raise:NSGenericException
						format:@"%@ not implemented", [self setterNameForClass:class]];
	}
	return self;
}
+     (NSArray*) instancesWithArray:(NSArray*)array	{

	NSMutableArray *result = NSMutableArray.new;
	for (id object in array) [result addObject:[self instanceWithObject:object]];
	return result;
}
+ (instancetype) instanceWithCoder:	(NSCoder*)decoder	{

	return decoder? [self.alloc initWithCoder:decoder]: nil; 	//return nil if coder is nil
}
- (instancetype) initWithCoder:		(NSCoder*)decoder	{

	if ((self = self.init))
		[self respondsToSelector:@selector(setWithCoder:)]
		? [self setWithCoder:decoder]
		: [NSException raise:NSGenericException format:@"setWithCoder: not implemented"];
	return self;
}
+ (instancetype) instanceWithContentsOfFile:(NSString*)filePath	{

	NSString *path = filePath;			// check if the path is a full path or not
	if (!path.isAbsolutePath)	{ 		// try resources
		path = [self BaseModel_resourceFilePath:filePath];
		if (![NSFileManager.defaultManager fileExistsAtPath:path])
			path = [self BaseModel_saveFilePath:filePath]; 			//try application support
	}
	return [self.alloc initWithContentsOfFile:path];
}
- (instancetype) initWithContentsOfFile:	  (NSString*)filePath	{

	id object 		= nil;
	NSData *data 	= nil;

	static NSCache *cachedResourceFiles = nil;
	cachedResourceFiles = cachedResourceFiles ?: NSCache.new;

	//check cache for existing instance - only cache files inside the main bundle as they are immutable
	BOOL isResourceFile = [filePath hasPrefix:NSBundle.mainBundle.bundlePath];
	if (isResourceFile)
	{
		object = [cachedResourceFiles objectForKey:filePath];
		if (object == NSNull.null) 	object = nil;
		else if ([object isKindOfClass:NSData.class])
		{
			data = object;
			object = nil;
		}
	}
	if (!object) 	//load object if no cached version found
	{
		data = data ?:	[NSData dataWithContentsOfFile:filePath]; //load the file
		if (data)
		{
			NSString *extension = filePath.pathExtension.lowercaseString;
			if ([extension isEqualToString:@"json"] || [extension isEqualToString:@"js"])
			{
				//attempt to deserialise data as json
				Class FXJSONClass = NSClassFromString(@"FXJSON");
				if (FXJSONClass)
					object = ((id (*)(id, SEL, id))objc_msgSend)(FXJSONClass, @selector(objectWithJSONData:), data);
				else
				{

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_5_0 || __MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_7

					object = [NSJSONSerialization JSONObjectWithData:data
																		  options:NSJSONReadingAllowFragments
																			 error:NULL];
#else
					[NSException raise:NSGenericException format:@"NSJSONSerialization is not available on some of the platforms you are targeting. Add FXJSON (https://github.com/nicklockwood/FXJSON) to the project to resolve this."];
#endif
				}
			}
			else
			{
				//attempt to deserialise data as a plist
				NSPropertyListFormat format;
				NSPropertyListReadOptions options = NSPropertyListMutableContainersAndLeaves;
				object = [NSPropertyListSerialization propertyListWithData:data options:options format:&format error:NULL];
			}
			object = object ?: data; //data is not a known serialisation format
		}
	}
	if (object) 	//success?
	{
		if ([object respondsToSelector:@selector(objectForKey:)]) 		//check if object is an NSCoded archive
		{
			if (object[@"$archiver"])
			{
				if (isResourceFile)	[cachedResourceFiles setObject:data forKey:filePath]; //cache data for next time
				//unarchive object
				Class coderClass = NSClassFromString(@"CryptoCoder") ?: NSKeyedUnarchiver.class;
				object = [coderClass unarchiveObjectWithData:data];
			}
			else
			{
				if (isResourceFile)	[cachedResourceFiles setObject:object forKey:filePath]; //cache object for next time
				//unarchive object
				Class HRCoderClass 		= NSClassFromString(@"HRCoder");
				NSString *classNameKey 	= [HRCoderClass valueForKey:@"classNameKey"];
				if (object[classNameKey])
					object = ((id (*)(id, SEL, id))objc_msgSend)(HRCoderClass, NSSelectorFromString(@"unarchiveObjectWithPlist:"), object);
			}
			if ([object isKindOfClass:self.class]) return ((self = object));	// return object
		}
		else if (isResourceFile)
			[cachedResourceFiles setObject:object forKey:filePath]; 				// cache object for next time

		return ((self = [self initWithObject:object])); 							// load with object
	}
	else if (isResourceFile)
		//store null for non-existent files to improve performance next time
		[cachedResourceFiles setObject:NSNull.null forKey:filePath];

	 return ((self = nil)); 	//failed to load
}
-         (BOOL) writeToFile:(NSString*)path atomically:(BOOL)atomically	{

	NSData *data 				= nil;
	Class CryptoCoderClass 	= NSClassFromString(@"CryptoCoder");
	Class HRCoderClass 		= NSClassFromString(@"HRCoder");
	if (CryptoCoderClass && [self.class respondsToSelector:NSSelectorFromString(@"CCPassword")])
		data = [CryptoCoderClass archivedDataWithRootObject:self];
	else if (HRCoderClass && self.useHRCoderIfAvailable)
	{
		id plist = ((id (*)(id, SEL, id))objc_msgSend)(HRCoderClass, NSSelectorFromString(@"archivedPlistWithRootObject:"), self);
		NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
		data = [NSPropertyListSerialization dataWithPropertyList:plist format:format options:0 error:NULL];
	}
	else data = [NSKeyedArchiver archivedDataWithRootObject:self];
	return [data writeToFile:[self.class BaseModel_saveFilePath:path] atomically:atomically];
}

#pragma mark - Unique identifier generation

+ (NSString*)newUniqueIdentifier	{

	CFUUIDRef uuid 			= CFUUIDCreate(NULL);
	CFStringRef identifier 	= CFUUIDCreateString(NULL, uuid);
	CFRelease(uuid);
	return CFBridgingRelease(identifier);
}

@end
