//
//  BaseModel.m
//
//  Version 2.6.1
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


static NSString *const BMDateFormatterKey = @"BMDateFormatterKey";


static const void *BMAllPropertiesKey = &BMAllPropertiesKey;
static const void *BMCodablePropertiesKey = &BMCodablePropertiesKey;
static const void *BMSharedInstanceKey = &BMSharedInstanceKey;
static const void *BMLoadingFromResourceFileKey = &BMLoadingFromResourceFileKey;
static const void *BMWasSetUpKey = &BMWasSetUpKey;


static const NSUInteger BMStringDescriptionMaxLength = 16;


@implementation NSObject (BaseModel)

- (id)BM_propertyListRepresentation
{
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}

- (id)BM_JSONRepresentation
{
    return [[NSKeyedArchiver archivedDataWithRootObject:self] BM_JSONRepresentation];
}

- (id)BM_objectFromPropertyListOrJSON
{
    return self;
}

- (NSString *)BM_shortDescription
{
    return [NSString stringWithFormat:@"<%@: %p>", [self classForCoder], self];
}

@end


@implementation NSString (BaseModel)

- (id)BM_propertyListRepresentation
{
    return self;
}

- (id)BM_JSONRepresentation
{
    return self;
}

- (NSString *)BM_shortDescription
{
    NSString *string = self;
    if ([string length] > BMStringDescriptionMaxLength)
    {
        string = [[string substringToIndex:BMStringDescriptionMaxLength - 1] stringByAppendingString:@"…"];
    }
    return [NSString stringWithFormat:@"\"%@\"", string];
}

@end


@implementation NSNumber (BaseModel)

- (id)BM_propertyListRepresentation
{
    return self;
}

- (id)BM_JSONRepresentation
{
    return self;
}

- (NSString *)BM_shortDescription
{
    return [self description];
}

@end


@implementation NSData (BaseModel)

- (id)BM_propertyListRepresentation
{
    return self;
}

- (id)BM_JSONRepresentation
{
    NSString *base64String = nil;
    
#if (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_9) || \
(defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0)
    
    if (![self respondsToSelector:@selector(base64EncodedStringWithOptions:)])
    {
        base64String = [self base64Encoding];
    }
    else
#endif
    {
        base64String = [self base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
    }
    return base64String;
}

- (id)BM_objectFromPropertyListOrJSON
{
    //attempt to deserialise data as a plist
    NSDictionary *object = [NSPropertyListSerialization propertyListWithData:self options:0 format:NULL error:NULL];
    if ([object respondsToSelector:@selector(objectForKey:)] && object[@"$archiver"])
    {
        //unarchive object
        return [NSKeyedUnarchiver unarchiveObjectWithData:self];
    }
    return self;
}

@end


@implementation NSDate (BaseModel)

- (id)BM_propertyListRepresentation
{
    return self;
}

- (id)BM_JSONRepresentation
{
    NSDateFormatter *formatter = [[NSThread currentThread] threadDictionary][BMDateFormatterKey];
    if (!formatter)
    {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        [[NSThread currentThread] threadDictionary][BMDateFormatterKey] = formatter;
    }
    return [formatter stringFromDate:self];
}

- (NSString *)BM_shortDescription
{
    return [self description];
}

@end


@implementation NSArray (BaseModel)

- (id)BM_propertyListRepresentation
{
    NSMutableArray *copy = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateObjectsUsingBlock:^(__unsafe_unretained id obj, __unused NSUInteger idx, __unused BOOL *stop) {
        [copy addObject:[obj BM_propertyListRepresentation]];
    }];
    return copy;
}

- (id)BM_JSONRepresentation
{
    NSMutableArray *copy = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateObjectsUsingBlock:^(__unsafe_unretained id obj, __unused NSUInteger idx, __unused BOOL *stop) {
        [copy addObject:[obj BM_JSONRepresentation]];
    }];
    return copy;
}

- (id)BM_objectFromPropertyListOrJSON
{
    NSMutableArray *copy = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateObjectsUsingBlock:^(__unsafe_unretained id obj, __unused NSUInteger idx, __unused BOOL *stop) {
        [copy addObject:[obj BM_objectFromPropertyListOrJSON]];
    }];
    return copy;
}

@end


@implementation NSDictionary (BaseModel)

- (id)BM_propertyListRepresentation
{
    NSMutableDictionary *copy = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(__unsafe_unretained id key, __unsafe_unretained id obj, __unused BOOL *stop) {
        copy[key] = [obj BM_propertyListRepresentation];
    }];
    return copy;
}

- (id)BM_JSONRepresentation
{
    NSMutableDictionary *copy = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(__unsafe_unretained id key, __unsafe_unretained id obj, __unused BOOL *stop) {
        copy[key] = [obj BM_JSONRepresentation];
    }];
    return copy;
}

- (id)BM_objectFromPropertyListOrJSON
{
    NSMutableDictionary *copy = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(__unsafe_unretained id key, __unsafe_unretained id obj, __unused BOOL *stop) {
        copy[key] = [obj BM_objectFromPropertyListOrJSON];
    }];
    return copy;
}

@end


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

- (NSDictionary *)BM_propertyListRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (__unsafe_unretained NSString *key in [[self class] codablePropertyKeys])
    {
        id value = [self valueForKey:key];
        if (value) dict[key] = [(NSObject *)value BM_propertyListRepresentation];
    }
    return dict;
}

- (NSDictionary *)BM_JSONRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (__unsafe_unretained NSString *key in [[self class] codablePropertyKeys])
    {
        id value = [self valueForKey:key];
        if (value) dict[key] = [(NSObject *)value BM_JSONRepresentation];
    }
    return dict;
}

- (void)BM_setUp
{
    objc_setAssociatedObject(self, BMWasSetUpKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setUp];
}

- (void)BM_tearDown
{
    [self tearDown];
}


#pragma mark -
#pragma mark Description

- (NSString *)debugDescription
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p", [self class], self];
    [[self dictionaryRepresentation] enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, __unused BOOL *stop) {
        
        [description appendFormat:@"; %@ = %@", key, [obj BM_shortDescription]];
    }];
    [description appendString:@">"];
    return description;
}


#pragma mark -
#pragma mark Singleton behaviour

+ (void)setSharedInstance:(BaseModel *)instance
{
    if (instance && ![instance isKindOfClass:self])
    {
        [NSException raise:BaseModelException format:@"setSharedInstance: instance class does not match"];
    }
    id oldInstance = objc_getAssociatedObject(self, BMSharedInstanceKey);
    objc_setAssociatedObject(self, BMSharedInstanceKey, instance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    return objc_getAssociatedObject(self, BMSharedInstanceKey) != nil;
}

+ (instancetype)sharedInstance
{
    @synchronized ([self class])
    {
        id instance = objc_getAssociatedObject(self, BMSharedInstanceKey);
        if (instance == nil)
        {
            //load or create instance
            [self reloadSharedInstance];
            
            //get loaded instance
            instance = objc_getAssociatedObject(self, BMSharedInstanceKey);
        }
        return instance;
    }
}

+ (void)reloadSharedInstance
{
    id instance = nil;
    
    //try loading previously saved version
    if ([self saveFormat] == BMFileFormatUserDefaults)
    {
        instance = [self instanceWithObject:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
    }
    else if ([self saveFormat] == BMFileFormatKeychain)
    {
        Class keychainClass = NSClassFromString(@"FXKeychain");
        NSAssert(keychainClass, @"FXKeychain library was not found");
        id defaultKeychain = [keychainClass valueForKey:@"defaultKeychain"];
        NSMutableDictionary *properties = [NSMutableDictionary dictionary];
        for (NSString *key in [self codablePropertyKeys])
        {
            id value = defaultKeychain[key];
            if (value) properties[key] = value;
        }
        instance = [self instanceWithObject:properties];
    }
    else
    {
        instance = [self instanceWithContentsOfFile:[self BM_saveFilePath]];
    }
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
        case BMFileFormatXMLPropertyList:
        case BMFileFormatBinaryPropertyList:
        case BMFileFormatCryptoCoding:
        case BMFileFormatHRCodedXML:
        case BMFileFormatHRCodedBinary:
        {
            extension = @"plist";
            break;
        }
        case BMFileFormatJSON:
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
        case BMFileFormatUserDefaults:
        case BMFileFormatKeychain:
        {
            return nil;
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

- (BOOL)save
{
    if (objc_getAssociatedObject([self class], BMSharedInstanceKey) == self)
    {
        //shared (singleton) instance
        if ([[self class] saveFormat] == BMFileFormatUserDefaults)
        {
            [[NSUserDefaults standardUserDefaults] setValuesForKeysWithDictionary:[self BM_propertyListRepresentation]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            return YES;
        }
        else if ([[self class] saveFormat] == BMFileFormatKeychain)
        {
            Class keychainClass = NSClassFromString(@"FXKeychain");
            NSAssert(keychainClass, @"FXKeychain library was not found");
            id defaultKeychain = [keychainClass valueForKey:@"defaultKeychain"];
            for (NSString *key in [[self class] codablePropertyKeys])
            {
                id value = [self valueForKey:key];
                if (value) defaultKeychain[key] = value;
            }
            return YES;
        }
        else
        {
            return [self writeToFile:[[self class] BM_saveFilePath] atomically:YES];
        }
    }
    else
    {
        //no save implementation
        [NSException raise:BaseModelException format:@"Unable to save object, save method not implemented"];
        return NO;
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
    for (__unsafe_unretained NSString *key in [[self class] codablePropertyKeys])
    {
        id value = [coder decodeObjectForKey:key];
        if (value) [self setValue:value forKey:key];
    }
}

- (void)setWithDictionary:(NSDictionary *)dict
{
    [dict enumerateKeysAndObjectsUsingBlock:^(__unsafe_unretained id key, __unsafe_unretained id obj, __unused BOOL *stop) {
        
        [self setValue:[obj BM_objectFromPropertyListOrJSON] forKey:key];
    }];
}

- (void)setValue:(__unused id)value forUndefinedKey:(__unused NSString *)key
{
    //fail silently
}

- (id)valueForUndefinedKey:(__unused NSString *)key
{
    //return nothing
    return nil;
}

- (void)setNilValueForKey:(NSString *)key
{
    //handle gracefully
    [self setValue:@0 forKey:key];
}

+ (instancetype)instance
{
    return [[self alloc] init];
}

- (instancetype)init
{
    @synchronized ([self class])
    {
        if (!objc_getAssociatedObject([self class], BMLoadingFromResourceFileKey))
        {
            //attempt to load from resource file
            objc_setAssociatedObject([self class], BMLoadingFromResourceFileKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            id object = [[[self class] alloc] initWithContentsOfFile:[[self class] BM_resourceFilePath]];
            objc_setAssociatedObject([self class], BMLoadingFromResourceFileKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
            
            [self BM_setUp];
        }
        return self;
    }
}

- (void)tearDown
{
    //override this
}

- (void)dealloc
{
    if (objc_getAssociatedObject(self, BMWasSetUpKey))
    {
        [self BM_tearDown];
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
    if (!object)
    {
        return nil;
    }
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
        if ([object isKindOfClass:[NSNull class]])
        {
            return nil;
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
        id instance = [self instanceWithObject:object];
        if (instance) [result addObject:instance];
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
    
    //return nil if file does not exist
    return [[NSFileManager defaultManager] fileExistsAtPath:path]? [[self alloc] initWithContentsOfFile:path]: nil;
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
#pragma mark Property access

+ (NSArray *)allPropertyKeys
{
    __autoreleasing NSArray *propertyKeys = objc_getAssociatedObject(self, BMAllPropertiesKey);
    if (!propertyKeys)
    {
        NSMutableArray *keys = [NSMutableArray array];
        NSMutableArray *codableKeys = [NSMutableArray array];
        
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
                
                //add to properties
                [keys addObject:key];
                
                //see if there is a backing ivar
                char *ivar = property_copyAttributeValue(property, "V");
                if (ivar)
                {
                    //check if ivar has KVC-compliant name
                    NSString *ivarName = @(ivar);
                    if ([ivarName isEqualToString:key] || [ivarName isEqualToString:[@"_" stringByAppendingString:key]])
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
        
        //store keys
        propertyKeys = [keys copy];
        objc_setAssociatedObject(self, BMAllPropertiesKey, keys, OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(self, BMCodablePropertiesKey, codableKeys, OBJC_ASSOCIATION_COPY);
    }
    return propertyKeys;
}

+ (NSArray *)codablePropertyKeys
{
    NSArray *codableKeys = objc_getAssociatedObject(self, BMCodablePropertiesKey);
    if (!codableKeys)
    {
        [self allPropertyKeys];
        return [self codablePropertyKeys];
    }
    return codableKeys;
}

+ (NSArray *)uncodableProperties
{
    //DEPRECATED
    return nil;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (__unsafe_unretained NSString *key in [[self class] allPropertyKeys])
    {
        id value = [self valueForKey:key];
        if (value) dict[key] = value;
    }
    return dict;
}

#pragma mark -
#pragma mark Serializing

- (void)encodeWithCoder:(NSCoder *)coder
{
    for (__unsafe_unretained NSString *key in [[self class] codablePropertyKeys])
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
        case BMFileFormatXMLPropertyList:
        case BMFileFormatBinaryPropertyList:
        case BMFileFormatUserDefaults:
        case BMFileFormatKeychain:
        {
            NSPropertyListFormat plistFormat = (format == BMFileFormatXMLPropertyList)? NSPropertyListXMLFormat_v1_0: NSPropertyListBinaryFormat_v1_0;
            data = [NSPropertyListSerialization dataWithPropertyList:[self BM_propertyListRepresentation] format:plistFormat options:0 error:NULL];
            break;
        }
        case BMFileFormatJSON:
        {
            data = [NSJSONSerialization dataWithJSONObject:[self BM_JSONRepresentation] options:(NSJSONWritingOptions)0 error:NULL];
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
            NSString *selString = (format == BMFileFormatHRCodedJSON)? @"archivedJSONWithRootObject:": @"archivedPlistWithRootObject:";
            id plist = ((id (*)(id, SEL, id))objc_msgSend)(coderClass, NSSelectorFromString(selString), self);
            if (format == BMFileFormatHRCodedXML)
            {
                NSPropertyListFormat fmt = NSPropertyListXMLFormat_v1_0;
                data = [NSPropertyListSerialization dataWithPropertyList:plist format:fmt options:0 error:NULL];
            }
            else if (format == BMFileFormatHRCodedBinary)
            {
                NSPropertyListFormat fmt = NSPropertyListBinaryFormat_v1_0;
                data = [NSPropertyListSerialization dataWithPropertyList:plist format:fmt options:0 error:NULL];
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
