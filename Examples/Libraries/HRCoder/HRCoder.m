//
//  HRCoder.m
//
//  Version 1.3.1
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

#import "HRCoder.h"


#pragma GCC diagnostic ignored "-Wdirect-ivar-access"


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


NSString *const HRCoderException = @"HRCoderException";
NSString *const HRCoderClassNameKey = @"$class";
NSString *const HRCoderRootObjectKey = @"$root";
NSString *const HRCoderObjectAliasKey = @"$alias";
NSString *const HRCoderBase64DataKey = @"$data";


@interface HRCoderAliasPlaceholder : NSObject

+ (HRCoderAliasPlaceholder *)placeholder;

@end


@interface NSObject (HRCoding_Private)

- (id)unarchiveObjectWithHRCoder:(HRCoder *)coder;
- (id)archivedObjectWithHRCoder:(HRCoder *)coder;

@end


@implementation HRCoderAliasPlaceholder

+ (HRCoderAliasPlaceholder *)placeholder
{
    static HRCoderAliasPlaceholder *sharedInstance = nil;
    if (sharedInstance == nil)
    {
        sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@>", [self class]];
}

@end


@interface HRCoder ()

@property (nonatomic, strong) NSMutableArray *stack;
@property (nonatomic, strong) NSMutableDictionary *knownObjects;
@property (nonatomic, strong) NSMutableDictionary *unresolvedAliases;
@property (nonatomic, strong) NSString *keyPath;
@property (nonatomic, strong) NSMutableData *data;

@end


@implementation HRCoder

+ (NSString *)classNameKey
{
    //used by BaseModel
    return HRCoderClassNameKey;
}

- (id)init
{
    if ((self = [super init]))
    {
        self.stack = [NSMutableArray arrayWithObject:[NSMutableDictionary dictionary]];
        _knownObjects = [[NSMutableDictionary alloc] init];
        _unresolvedAliases = [[NSMutableDictionary alloc] init];
        _outputFormat = HRCoderFormatXML;
    }
    return self;
}

#pragma mark -
#pragma mark Unarchiving

+ (id)unarchiveObjectWithPlistOrJSON:(__unsafe_unretained id)plistOrJSON
{
    return [[[self alloc] init] unarchiveRootObjectWithPlistOrJSON:plistOrJSON];
}

+ (id)unarchiveObjectWithData:(__unsafe_unretained NSData *)data
{
    if (data)
    {
        //attempt to deserialize as plist
        id plistOrJSON = [NSPropertyListSerialization propertyListWithData:data
                                                                   options:NSPropertyListMutableContainers
                                                                    format:NULL
                                                                     error:NULL];
        if (!plistOrJSON)
        {
            //attempt to deserialize as JSON
            plistOrJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:NULL];
        }
        
        //unarchive
        return [self unarchiveObjectWithPlistOrJSON:plistOrJSON];
    }
    return nil;
}

+ (id)unarchiveObjectWithFile:(__unsafe_unretained NSString *)path
{
    //load the file
    return [self unarchiveObjectWithData:[NSData dataWithContentsOfFile:path]];
}

- (id)unarchiveRootObjectWithPlistOrJSON:(__unsafe_unretained id)plistOrJSON
{
    [_stack removeAllObjects];
    [_knownObjects removeAllObjects];
    [_unresolvedAliases removeAllObjects];
    __autoreleasing id rootObject = [plistOrJSON unarchiveObjectWithHRCoder:self];
    if (rootObject)
    {
        _knownObjects[HRCoderRootObjectKey] = rootObject;
        for (__unsafe_unretained NSString *keyPath in _unresolvedAliases)
        {
            __autoreleasing id aliasKeyPath = _unresolvedAliases[keyPath];
            __autoreleasing id aliasedObject = _knownObjects[aliasKeyPath];
            __autoreleasing id node = rootObject;
            for (__unsafe_unretained NSString *key in [keyPath componentsSeparatedByString:@"."])
            {
                __autoreleasing id _node = nil;
                if ([node isKindOfClass:[NSArray class]])
                {
                    NSUInteger index = (NSUInteger)[key integerValue];
                    _node = node[index];
                    if (_node == [HRCoderAliasPlaceholder placeholder])
                    {
                        node[index] = aliasedObject;
                        break;
                    }
                }
                else
                {
                    _node = [node valueForKey:key];
                    if (_node == nil || _node == [HRCoderAliasPlaceholder placeholder])
                    {
                        [node setValue:aliasedObject forKey:key];
                        break;
                    }
                }
                node = _node;
            }
        }
    }
    [self finishDecoding];
    return rootObject;
}

- (id)initForReadingWithData:(__unsafe_unretained NSData *)data
{
    if ((self = [self init]))
    {
        //attempt to deserialise data as a plist
        if (data)
        {
            //attempt to deserialize as plist
            NSPropertyListFormat format;
            NSError *error;
            __autoreleasing id plistOrJSON = [NSPropertyListSerialization propertyListWithData:data
                                                                                       options:NSPropertyListMutableContainers
                                                                                        format:&format
                                                                                         error:&error];
            if (!plistOrJSON && error)
            {
                //attempt to deserialize as JSON
                plistOrJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                if (!plistOrJSON && error)
                {
                    [NSException raise:HRCoderException format:@"initForReadingWithData: method was unable to parse the supplied data."];
                }
                _outputFormat = HRCoderFormatJSON;
            }
            else
            {
                //convert to HRCoderFormat
                switch (format)
                {
                    case NSPropertyListXMLFormat_v1_0:
                    case NSPropertyListOpenStepFormat:
                    {
                        _outputFormat = HRCoderFormatXML;
                        break;
                    }
                    case NSPropertyListBinaryFormat_v1_0:
                    {
                        _outputFormat = HRCoderFormatBinary;
                        break;
                    }
                }
            }
            
            //only works if root object is a dictionary
            if ([plistOrJSON isKindOfClass:[NSDictionary class]])
            {
                [_stack addObject:plistOrJSON];
            }
            else
            {
                [NSException raise:HRCoderException format:@"initForReadingWithData: method requires that the root object in the plist data is an NSDictionary. Decoding an %@ is not supported with this method. Try using unarchiveObjectWithData: instead.", [plistOrJSON class]];
            }
        }
    }
    return self;
}

- (void)finishDecoding
{
    [_unresolvedAliases removeAllObjects];
    [_knownObjects removeAllObjects];
    [_stack setArray:[NSMutableArray arrayWithObject:[NSMutableDictionary dictionary]]];
}


#pragma mark -
#pragma mark Archiving

+ (id)archivedPlistWithRootObject:(__unsafe_unretained id)rootObject
{
    HRCoder *coder = [[self alloc] init];
    return [coder archiveRootObject:rootObject];
}

+ (id)archivedJSONWithRootObject:(__unsafe_unretained id)rootObject
{
    HRCoder *coder = [[self alloc] init];
    coder.outputFormat = HRCoderFormatJSON;
    return [coder archiveRootObject:rootObject];
}

+ (NSData *)archivedDataWithRootObject:(__unsafe_unretained id)rootObject
{
    __autoreleasing NSMutableData *data = [NSMutableData data];
    __autoreleasing HRCoder *coder = [[self alloc] initForWritingWithMutableData:data];
    [coder archiveRootObject:rootObject];
    return data;
}

+ (BOOL)archiveRootObject:(__unsafe_unretained id)rootObject toFile:(__unsafe_unretained NSString *)path
{
    return [[self archivedDataWithRootObject:rootObject] writeToFile:path atomically:YES];
}

- (id)initForWritingWithMutableData:(__unsafe_unretained NSMutableData *)data
{
    if ((self = [self init]))
    {
        //set data
        self.data = data;
    }
    return self;
}

- (id)archiveRootObject:(__unsafe_unretained id)rootObject
{
    [_knownObjects removeAllObjects];
    [self encodeRootObject:rootObject];
    __autoreleasing id plistOrJSON = [_stack lastObject];
    [self finishEncoding];
    return plistOrJSON;
}

- (void)finishEncoding
{
    if (_data)
    {
        switch (_outputFormat)
        {
            case HRCoderFormatXML:
            case HRCoderFormatBinary:
            {
                [_data setData:[NSPropertyListSerialization dataWithPropertyList:[_stack lastObject]
                                                                          format:(_outputFormat == HRCoderFormatXML)? NSPropertyListXMLFormat_v1_0: NSPropertyListBinaryFormat_v1_0
                                                                         options:0
                                                                           error:NULL]];
                break;
            }
            case HRCoderFormatJSON:
            {
                [_data setData:[NSJSONSerialization dataWithJSONObject:[_stack lastObject] options:(NSJSONWritingOptions)0 error:NULL]];
                break;
            }
        }
        self.data = nil;
    }
    [_knownObjects removeAllObjects];
    [_stack setArray:[NSMutableArray arrayWithObject:[NSMutableDictionary dictionary]]];
}


#pragma mark -
#pragma mark NSCoding

- (BOOL)allowsKeyedCoding
{
    return YES;
}

- (BOOL)containsValueForKey:(__unsafe_unretained NSString *)key
{
    return [_stack lastObject][key] != nil;
}

- (id)encodedObject:(__unsafe_unretained id)object forKey:(__unsafe_unretained NSString *)key
{
    if (object && key)
    {
        if (![object isKindOfClass:[NSNumber class]] &&
            ![object isKindOfClass:[NSDate class]] &&
            (![object isKindOfClass:[NSString class]] || [(NSString *)object length] < 32))
        {
            for (__unsafe_unretained NSString *aliasKeyPath in _knownObjects)
            {
                if (_knownObjects[aliasKeyPath] == object)
                {
                    //create alias
                    return @{HRCoderObjectAliasKey: aliasKeyPath};
                }
            }
        }
        
        //encode object
        __autoreleasing NSString *oldKeyPath = _keyPath;
        self.keyPath = _keyPath? [_keyPath stringByAppendingPathExtension:key]: key;
        _knownObjects[_keyPath] = object;
        __autoreleasing id encodedObject = [object archivedObjectWithHRCoder:self];
        self.keyPath = oldKeyPath;
        return encodedObject;
    }
    return nil;
}

- (void)encodeObject:(__unsafe_unretained id)objv forKey:(__unsafe_unretained NSString *)key
{
    __autoreleasing id object = [self encodedObject:objv forKey:key];
    if (object) [_stack lastObject][key] = object;
}

- (void)encodeRootObject:(__unsafe_unretained id)rootObject
{
    if (rootObject)
    {
        _knownObjects[HRCoderRootObjectKey] = rootObject;
        [_stack setArray:[NSMutableArray arrayWithObject:[rootObject archivedObjectWithHRCoder:self]]];
    }
}

- (void)encodeConditionalObject:(id)objv forKey:(__unsafe_unretained NSString *)key
{
    for (__unsafe_unretained id object in [_knownObjects allValues])
    {
        if (object == objv)
        {
            [self encodeObject:objv forKey:key];
            break;
        }
    }
}

- (void)encodeBool:(BOOL)boolv forKey:(__unsafe_unretained NSString *)key
{
    [_stack lastObject][key] = @(boolv);
}

- (void)encodeInt:(int)intv forKey:(__unsafe_unretained NSString *)key
{
    [_stack lastObject][key] = @(intv);
}

- (void)encodeInt32:(int32_t)intv forKey:(__unsafe_unretained NSString *)key
{
    [_stack lastObject][key] = @(intv);
}

- (void)encodeInt64:(int64_t)intv forKey:(__unsafe_unretained NSString *)key
{
    [_stack lastObject][key] = @(intv);
}

- (void)encodeFloat:(float)realv forKey:(__unsafe_unretained NSString *)key
{
    [_stack lastObject][key] = @(realv);
}

- (void)encodeDouble:(double)realv forKey:(__unsafe_unretained NSString *)key
{
    [_stack lastObject][key] = @(realv);
}

- (void)encodeBytes:(const uint8_t *)bytesp length:(NSUInteger)lenv forKey:(__unsafe_unretained NSString *)key
{
    [_stack lastObject][key] = [NSData dataWithBytes:bytesp length:lenv];
}

- (id)decodeObject:(id)object forKey:(__unsafe_unretained NSString *)key
{
    if (object && key)
    {
        //new keypath
        __autoreleasing NSString *newKeyPath = _keyPath? [_keyPath stringByAppendingPathExtension:key]: key;
        
        //check if object is an alias
        if ([object isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *dictionary = object;
            __autoreleasing NSString *aliasKeyPath = dictionary[HRCoderObjectAliasKey];
            if (aliasKeyPath)
            {
                //object alias
                __autoreleasing id decodedObject = _knownObjects[aliasKeyPath];
                if (!decodedObject)
                {
                    _unresolvedAliases[newKeyPath] = aliasKeyPath;
                    decodedObject = [HRCoderAliasPlaceholder placeholder];
                }
                return decodedObject;
            }
            else
            {
                __autoreleasing NSString *base64Data = dictionary[HRCoderBase64DataKey];
                if (base64Data)
                {
                    Class dataClass = NSClassFromString(dictionary[HRCoderClassNameKey] ?: @"NSData");
                    
#if __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_9 || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
                    
                    if (![NSData instancesRespondToSelector:@selector(initWithBase64EncodedString:options:)])
                    {
                        object = [[dataClass alloc] initWithBase64Encoding:base64Data];
                    }
                    else
#endif
                    {
                        object = [[dataClass alloc] initWithBase64EncodedString:base64Data options:0];
                    }
                    if (!object)
                    {
                        return nil;
                    }
                }
            }
        }
        
        //new object
        __autoreleasing NSString *oldKeyPath = _keyPath;
        self.keyPath = newKeyPath;
        __autoreleasing id decodedObject = [object unarchiveObjectWithHRCoder:self];
        if (decodedObject) _knownObjects[_keyPath] = decodedObject;
        self.keyPath = oldKeyPath;
        return decodedObject;
    }
    return nil;
}

- (id)decodeObjectForKey:(__unsafe_unretained NSString *)key
{
    return [self decodeObject:[_stack lastObject][key] forKey:key];
}

- (BOOL)decodeBoolForKey:(__unsafe_unretained NSString *)key
{
    return [[_stack lastObject][key] boolValue];
}

- (int)decodeIntForKey:(__unsafe_unretained NSString *)key
{
    return [[_stack lastObject][key] intValue];
}

- (int32_t)decodeInt32ForKey:(__unsafe_unretained NSString *)key
{
    return (int32_t)[[_stack lastObject][key] longValue];
}

- (int64_t)decodeInt64ForKey:(__unsafe_unretained NSString *)key
{
    return [[_stack lastObject][key] longLongValue];
}

- (float)decodeFloatForKey:(__unsafe_unretained NSString *)key
{
    return [[_stack lastObject][key] floatValue];
}

- (double)decodeDoubleForKey:(__unsafe_unretained NSString *)key
{
    return [[_stack lastObject][key] doubleValue];
}

- (const uint8_t *)decodeBytesForKey:(__unsafe_unretained NSString *)key returnedLength:(NSUInteger *)lengthp
{
    __autoreleasing NSData *data = [_stack lastObject][key];
    *lengthp = [data length];
    return data.bytes;
}

@end


@implementation NSObject(HRCoding)

- (id)unarchiveObjectWithHRCoder:(__unused HRCoder *)coder
{
    return self;
}

- (id)archivedObjectWithHRCoder:(__unsafe_unretained HRCoder *)coder
{
    __autoreleasing NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [coder.stack addObject:result];
    result[HRCoderClassNameKey] = NSStringFromClass([self classForCoder]);
    [(id <NSCoding>)[self replacementObjectForCoder:coder] encodeWithCoder:coder];
    [coder.stack removeLastObject];
    return result;
}

@end    


@implementation NSDictionary(HRCoding)

- (id)unarchiveObjectWithHRCoder:(__unsafe_unretained HRCoder *)coder
{
    __autoreleasing NSString *className = self[HRCoderClassNameKey];
    if (className)
    {
        //encoded object
        [coder.stack addObject:self];
        Class objectClass = NSClassFromString(className);
        __autoreleasing id object = [[[objectClass alloc] initWithCoder:coder] awakeAfterUsingCoder:coder];
        [coder.stack removeLastObject];
        return object;
    }
    else
    {
        //ordinary dictionary
        __autoreleasing NSMutableDictionary *result = [NSMutableDictionary dictionary];
		[coder.stack addObject:self];
        for (__unsafe_unretained NSString *key in self)
        {
            __autoreleasing id object = [coder decodeObjectForKey:key];
            if (object) result[key] = object;
        }
		[coder.stack removeLastObject];
        return result;
    }
}

- (id)archivedObjectWithHRCoder:(__unsafe_unretained HRCoder *)coder
{
    __autoreleasing NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [coder.stack addObject:result];
    [self enumerateKeysAndObjectsUsingBlock:^(__unsafe_unretained id key, __unsafe_unretained id obj, __unused BOOL *stop) {
        [coder encodeObject:obj forKey:key];
    }];
    [coder.stack removeLastObject];
    return result;
}

@end


@implementation NSArray(HRCoding)

- (id)unarchiveObjectWithHRCoder:(__unsafe_unretained HRCoder *)coder
{
    __autoreleasing NSMutableArray *result = [NSMutableArray array];
    for (NSUInteger i = 0; i < [self count]; i++)
    {
        NSString *key = [@(i) description];
        id encodedObject = self[i];
        id decodedObject = [coder decodeObject:encodedObject forKey:key];
        [result addObject:decodedObject];
    }
    return result;
}

- (id)archivedObjectWithHRCoder:(__unsafe_unretained HRCoder *)coder
{
    NSMutableArray *result = [NSMutableArray array];
    for (NSUInteger i = 0; i < [self count]; i++)
    {
        id object = self[i];
        NSString *key = [@(i) description];
        [result addObject:[coder encodedObject:object forKey:key]];
    }
    return result;
}

@end


@implementation NSString(HRCoding)

- (id)unarchiveObjectWithHRCoder:(__unused HRCoder *)coder
{
    return self;
}

- (id)archivedObjectWithHRCoder:(__unsafe_unretained HRCoder *)coder
{
    if ([self classForCoder] == [NSMutableString class])
    {
        return [super archivedObjectWithHRCoder:coder];
    }
    return self;
}

@end


@implementation NSNumber(HRCoding)

- (id)unarchiveObjectWithHRCoder:(__unused HRCoder *)coder
{
    return self;
}

- (id)archivedObjectWithHRCoder:(__unused HRCoder *)coder
{
    return self;
}

@end


@implementation NSData(HRCoding)

- (id)unarchiveObjectWithHRCoder:(__unused HRCoder *)coder
{
    return self;
}

- (id)archivedObjectWithHRCoder:(__unsafe_unretained HRCoder *)coder
{
    Class coderClass = [self classForCoder];
    if (coder.outputFormat == HRCoderFormatJSON)
    {
        NSString *base64String = nil;
        
#if __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_9 || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
        
        if (![self respondsToSelector:@selector(base64EncodedStringWithOptions:)])
        {
            base64String = [self base64Encoding];
        }
        else
#endif
        {
            base64String = [self base64EncodedStringWithOptions:0];
        }
        return @{HRCoderClassNameKey: NSStringFromClass(coderClass), HRCoderBase64DataKey: base64String};
    }
    else if ([self classForCoder] == [NSMutableData class])
    {
        return [super archivedObjectWithHRCoder:coder];
    }
    return self;
}

@end


@implementation NSDate(HRCoding)

- (id)unarchiveObjectWithHRCoder:(__unused HRCoder *)coder
{
    return self;
}

- (id)archivedObjectWithHRCoder:(__unsafe_unretained HRCoder *)coder
{
    if (coder.outputFormat == HRCoderFormatJSON)
    {
        return [super archivedObjectWithHRCoder:coder];
    }
    return self;
}

@end


@implementation NSNull(HRCoding)

- (id)unarchiveObjectWithHRCoder:(__unused HRCoder *)coder
{
    return self;
}

- (id)archivedObjectWithHRCoder:(__unsafe_unretained HRCoder *)coder
{
    if (coder.outputFormat != HRCoderFormatJSON)
    {
        return [super archivedObjectWithHRCoder:coder];
    }
    return self;
}

@end
