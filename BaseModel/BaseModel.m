//
//  BaseModel.m
//
//  Version 2.5
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


#import "BaseModel.h"
#import <objc/message.h>


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


NSString *const BaseModelSharedInstanceUpdatedNotification = @"BaseModelSharedInstanceUpdatedNotification";
NSString *const BaseModelException = @"BaseModelException";

static char BMClassPropertiesKey;
static char BMSharedInstanceKey;
static char BMLoadingFromResourceFileKey;


@implementation BaseModel

#pragma mark -
#pragma mark Private utility methods

+ (NSString *)BM_resourceFilePath:(NSString *)path
{
    //check if the path is a full path or not
    if (![path isAbsolutePath])
    {
        return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:path];
    }
    return path;
}

+ (NSString *)BM_resourceFilePath
{
    return [self BM_resourceFilePath:[self resourceFile]];
}

+ (NSString *)BM_saveFilePath:(NSString *)path
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

+ (NSString *)BM_saveFilePath
{
    return [self BM_saveFilePath:[self saveFile]];
}

+ (NSArray *)BM_propertyKeys
{
    __autoreleasing NSMutableArray *codableKeys = objc_getAssociatedObject(self, &BMClassPropertiesKey);
    if (!codableKeys)
    {
        codableKeys = [NSMutableArray array];
        Class subclass = [self class];
        while (subclass != [BaseModel class])
        {
            unsigned int propertyCount;
            objc_property_t *properties = class_copyPropertyList(subclass, &propertyCount);
            for (unsigned int i = 0; i < propertyCount; i++)
            {
                //get property
                objc_property_t property = properties[i];
                const char *propertyName = property_getName(property);
                NSString *key = @(propertyName);
                
                //see if there is a backing ivar
                char *ivar = property_copyAttributeValue(property, "V");
                if (ivar)
                {
                    //check if ivar has KVC-compliant name
                    NSString *ivarName = [NSString stringWithFormat:@"%s", ivar];
                    if ([ivarName isEqualToString:key] ||
                        [ivarName isEqualToString:[@"_" stringByAppendingString:key]])
                    {
                        //setValue:forKey: will work
                        [codableKeys addObject:key];
                    }
                    free(ivar);
                }
            }
            free(properties);
            NSArray *uncodable = [subclass uncodableProperties];
            if ([uncodable count])
            {
                NSLog(@"You have implemented the AutoCoding +uncodableProperties method on the class %@. BaseModel supports this for now, but you should switch to using ivars for properties that you do not want to be saved instead.", subclass);
                [codableKeys removeObjectsInArray:uncodable];
            }
            subclass = [subclass superclass];
        }
        objc_setAssociatedObject(self, &BMClassPropertiesKey, codableKeys, OBJC_ASSOCIATION_RETAIN);
    }
    return codableKeys;
}

+ (NSArray *)uncodableProperties
{
    return nil;
}

#pragma mark -
#pragma mark Singleton behaviour

+ (void)setSharedInstance:(BaseModel *)instance
{
    if (instance && ![instance isKindOfClass:self])
    {
        [NSException raise:BaseModelException format:@"setSharedInstance: instance class does not match"];
    }
    id oldInstance = objc_getAssociatedObject(self, &BMSharedInstanceKey);
    objc_setAssociatedObject(self, &BMSharedInstanceKey, instance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (oldInstance)
    {
        void (^update)() = ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:BaseModelSharedInstanceUpdatedNotification object:oldInstance];
        };
        if ([NSThread currentThread] == [NSThread mainThread])
        {
            update();
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), update);
        }
    }
}

+ (BOOL)hasSharedInstance
{
    return objc_getAssociatedObject(self, &BMSharedInstanceKey) != nil;
}

+ (instancetype)sharedInstance
{
    @synchronized ([self class])
    {
        id instance = objc_getAssociatedObject(self, &BMSharedInstanceKey);
        if (instance == nil)
        {
            //load or create instance
            [self reloadSharedInstance];
            
            //get loaded instance
            instance = objc_getAssociatedObject(self, &BMSharedInstanceKey);
        }
        return instance;
    }
}

+ (void)reloadSharedInstance
{
    id instance = nil;
    
    //try loading previously saved version
    instance = [self instanceWithContentsOfFile:[self BM_saveFilePath]];
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
    NSString *extension = nil;
    switch ([self saveFormat])
    {
        case BMFileFormatKeyedArchive:
        case BMFileFormatCryptoCoding:
        case BMFileFormatHRCodedXML:
        case BMFileFormatHRCodedBinary:
        {
            extension = @"plist";
            break;
        }
        case BMFileFormatHRCodedJSON:
        {
            extension = @"json";
            break;
        }
        case BMFileFormatFastCoding:
        {
            extension = @"fast";
            break;
        }
    }
    return [NSStringFromClass(self) stringByAppendingPathExtension:extension];
}

+ (BMFileFormat)saveFormat
{
    if ([self respondsToSelector:NSSelectorFromString(@"useHRCoderIfAvailable")])
    {
        [NSException raise:BaseModelException format:@"You are using the deprecated useHRCoderIfAvailable method instead of specifying the saveFormat as BMFileFormatHRCodedBinary."];
    }
    if ([self respondsToSelector:NSSelectorFromString(@"CCPassword")])
    {
        NSLog(@"You have implemented the CCPassword method without specifying the saveFormat as BMFileFormatCryptoCoding. This is a warning for now, but may become an error in future.");
        return BMFileFormatCryptoCoding;
    }
    return BMFileFormatKeyedArchive;
}

- (void)save
{
    if (objc_getAssociatedObject([self class], &BMSharedInstanceKey) == self)
    {
        //shared (singleton) instance
        [self writeToFile:[[self class] BM_saveFilePath] atomically:YES];
    }
    else
    {
        //no save implementation
        [NSException raise:BaseModelException format:@"Unable to save object, save method not implemented"];
    }
}


#pragma mark -
#pragma mark Default constructors

- (void)setUp
{
    //override this
}

- (void)setWithCoder:(NSCoder *)coder
{
    for (__unsafe_unretained NSString *key in [[self class] BM_propertyKeys])
    {
        id value = [coder decodeObjectForKey:key];
        if (value) [self setValue:value forKey:key];
    }
}

- (void)setWithDictionary:(NSDictionary *)dict
{
    [dict enumerateKeysAndObjectsUsingBlock:^(__unsafe_unretained id key, __unsafe_unretained id obj, BOOL *stop) {
        [self setValue:obj forKey:key];
    }];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    //fail silently
}

+ (instancetype)instance
{
    return [[self alloc] init];
}

- (instancetype)init
{
    @synchronized ([self class])
    {
        if (!objc_getAssociatedObject([self class], &BMLoadingFromResourceFileKey))
        {
            //attempt to load from resource file
            objc_setAssociatedObject([self class], &BMLoadingFromResourceFileKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            id object = [[[self class] alloc] initWithContentsOfFile:[[self class] BM_resourceFilePath]];
            objc_setAssociatedObject([self class], &BMLoadingFromResourceFileKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (object)
            {
                return ((self = object));
            }
        }
        if ((self = [super init]))
        {
            if ([self class] == [BaseModel class])
            {
                [NSException raise:BaseModelException format:@"BaseModel class is abstract and should be subclassed rather than instantiated directly"];
            }
            
            [self setUp];
        }
        return self;
    }
}

+ (instancetype)instanceWithObject:(id)object
{
    //return nil if object is nil
    return object? [[self alloc] initWithObject:object]: nil;
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
                ((void (*)(id, SEL, id))objc_msgSend)(self, setter, object);
                return self;
            }
            if ([class superclass] == [NSObject class]) break;
            class = [class superclass];
        }
        [NSException raise:BaseModelException format:@"%@ not implemented", [self setterNameForClass:class]];
    }
    return self;
}

+ (NSArray *)instancesWithArray:(NSArray *)array
{
    NSMutableArray *result = [NSMutableArray array];
    for (__unsafe_unretained id object in array)
    {
        [result addObject:[self instanceWithObject:object]];
    }
    return result;
}

+ (instancetype)instanceWithCoder:(NSCoder *)decoder
{
    //return nil if coder is nil
    return decoder? [[self alloc] initWithCoder:decoder]: nil;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if ((self = [self init]))
    {
        [self setWithCoder:decoder];
    }
    return self;
}

+ (instancetype)instanceWithContentsOfFile:(NSString *)filePath
{
    //check if the path is a full path or not
    NSString *path = filePath;
    if (![path isAbsolutePath])
    {
        //try resources
        path = [self BM_resourceFilePath:filePath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            //try application support
            path = [self BM_saveFilePath:filePath];
        }
    }
    
    return [[self alloc] initWithContentsOfFile:path];
}

- (instancetype)initWithContentsOfFile:(NSString *)filePath
{
    id object = nil;
    NSData *data = nil;
    
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
        object = [cachedResourceFiles objectForKey:filePath];
        if (object == [NSNull null])
        {
            object = nil;
        }
        else if ([object isKindOfClass:[NSData class]])
        {
            data = object;
            object = nil;
        }
    }
    
    //load object if no cached version found
    if (!object)
    {
        if (!data)
        {
            //load the file
            data = [NSData dataWithContentsOfFile:filePath];
        }
        
        if (data)
        {
            //attempt to guess file type
            char byte = *((char *)data.bytes);
            if (byte == 'T')
            {
                //attempt to deserialise using FastCoding
                Class coderClass = NSClassFromString(@"FastCoder");
                object = ((id (*)(id, SEL, id))objc_msgSend)(coderClass, NSSelectorFromString(@"objectWithData:"), data);
            }
            
            if (!object && (byte == '{' || byte == '[' || byte == '"' || byte == 'n'))
            {
                //attempt to deserialise data as json
                object = [NSJSONSerialization JSONObjectWithData:data
                                                             options:NSJSONReadingAllowFragments
                                                               error:NULL];
            }
            
            if (!object)
            {
                //attempt to deserialise data as a plist
                NSPropertyListFormat format;
                NSPropertyListReadOptions options = NSPropertyListMutableContainersAndLeaves;
                object = [NSPropertyListSerialization propertyListWithData:data options:options format:&format error:NULL];
            }
            
            if (!object)
            {
                //data is not a known serialisation format
                object = data;
            }
        }
    }
    
    //success?
    if (object)
    {
        //check if object is an NSCoded archive
        if ([object respondsToSelector:@selector(objectForKey:)])
        {
            if (object[@"$archiver"])
            {
                if (isResourceFile)
                {
                    //cache data for next time
                    [cachedResourceFiles setObject:data forKey:filePath];
                }
                
                //unarchive object
                Class coderClass = NSClassFromString(@"CryptoCoder");
                if (!coderClass)
                {
                    coderClass = [NSKeyedUnarchiver class];
                }
                object = [coderClass unarchiveObjectWithData:data];
            }
            else
            {
                if (isResourceFile)
                {
                    //cache object for next time
                    [cachedResourceFiles setObject:object forKey:filePath];
                }
                
                //unarchive object
                Class HRCoderClass = NSClassFromString(@"HRCoder");
                NSString *classNameKey = [HRCoderClass valueForKey:@"classNameKey"];
                if (object[classNameKey])
                {
                    SEL selector = NSSelectorFromString(@"unarchiveObjectWithPlistOrJSON:");
                    if (![HRCoderClass respondsToSelector:selector])
                    {
                        [NSException raise:BaseModelException format:@"This version of HRCoder is not compatibile with this version BaseModel. Please ensure you have upgraded both libraries to the latest version."];
                    }
                    object = ((id (*)(id, SEL, id))objc_msgSend)(HRCoderClass, selector, object);
                }
            }
        }
        else if (isResourceFile)
        {
            //cache object for next time
            [cachedResourceFiles setObject:object forKey:filePath];
        }
        
        if ([object isKindOfClass:[self class]])
        {
            //return object
            return ((self = object));
        }
        
        //load with object
        return ((self = [self initWithObject:object]));
    }
    else if (isResourceFile)
    {
        //store null for non-existent files to improve performance next time
        [cachedResourceFiles setObject:[NSNull null] forKey:filePath];
    }
    
    //failed to load
    return ((self = nil));
}

#pragma mark -
#pragma mark Serializing

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (__unsafe_unretained NSString *key in [[self class] BM_propertyKeys])
    {
        id value = [self valueForKey:key];
        if (value) dict[key] = value;
    }
    return dict;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    for (__unsafe_unretained NSString *key in [[self class] BM_propertyKeys])
    {
        id value = [self valueForKey:key];
        if (value) [coder encodeObject:value forKey:key];
    }
}

- (BOOL)writeToFile:(NSString *)path format:(BMFileFormat)format atomically:(BOOL)atomically
{
    NSData *data = nil;
    switch (format)
    {
        case BMFileFormatKeyedArchive:
        {
            data = [NSKeyedArchiver archivedDataWithRootObject:self];
            break;
        }
        case BMFileFormatCryptoCoding:
        {
            Class coderClass = NSClassFromString(@"CryptoCoder");
            NSAssert(coderClass, @"CryptoCoding library was not found");
            data = [coderClass archivedDataWithRootObject:self];
            break;
        }
        case BMFileFormatHRCodedXML:
        case BMFileFormatHRCodedJSON:
        case BMFileFormatHRCodedBinary:
        {
            Class coderClass = NSClassFromString(@"HRCoder");
            NSAssert(coderClass, @"HRCoder library was not found");
            id plist = ((id (*)(id, SEL, id))objc_msgSend)(coderClass, NSSelectorFromString(@"archivedPlistWithRootObject:"), self);
            if (format == BMFileFormatHRCodedXML)
            {
                NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
                data = [NSPropertyListSerialization dataWithPropertyList:plist format:format options:0 error:NULL];
            }
            else if (format == BMFileFormatHRCodedBinary)
            {
                NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
                data = [NSPropertyListSerialization dataWithPropertyList:plist format:format options:0 error:NULL];
            }
            else
            {
                data = [NSJSONSerialization dataWithJSONObject:plist options:(NSJSONWritingOptions)0 error:NULL];
            }
            break;
        }
        case BMFileFormatFastCoding:
        {
            Class coderClass = NSClassFromString(@"FastCoder");
            NSAssert(coderClass, @"FastCoding library was not found");
            data = ((id (*)(id, SEL, id))objc_msgSend)(coderClass, NSSelectorFromString(@"dataWithRootObject:"), self);
            break;
        }
    }
    
    return [data writeToFile:[[self class] BM_saveFilePath:path] atomically:atomically];
}

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomically
{
    return [self writeToFile:path format:[[self class] saveFormat] atomically:atomically];
}


#pragma mark -
#pragma mark Unique identifier generation

+ (NSString *)newUniqueIdentifier
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef identifier = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return CFBridgingRelease(identifier);
}

@end