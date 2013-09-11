//
//  HRCoder.m
//
//  Version 1.2.3
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
    return [NSString stringWithFormat:@"<%@>", NSStringFromClass([self class])];
}

@end


@interface HRCoder ()

@property (nonatomic, strong) NSMutableArray *stack;
@property (nonatomic, strong) NSMutableDictionary *knownObjects;
@property (nonatomic, strong) NSMutableDictionary *unresolvedAliases;
@property (nonatomic, strong) NSString *keyPath;
@property (nonatomic, strong) NSMutableData *data;

+ (NSString *)classNameKey;

@end


@implementation HRCoder

@synthesize stack = _stack;
@synthesize knownObjects = _knownObjects;
@synthesize unresolvedAliases = _unresolvedAliases;
@synthesize keyPath = _keyPath;

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
        _outputFormat = NSPropertyListXMLFormat_v1_0;
    }
    return self;
}

#if !__has_feature(objc_arc)

- (void)dealloc
{
    [_stack release];
    [_knownObjects release];
    [_unresolvedAliases release];
    [_keyPath release];
    [_data release];
    [super dealloc];
}

#endif


#pragma mark -
#pragma mark Unarchiving

+ (id)unarchiveObjectWithPlist:(id)plist
{
    HRCoder *coder = [[self alloc] init];
    
#if !__has_feature(objc_arc)
    [coder autorelease];
#endif
    
    return [coder unarchiveRootObjectWithPlist:plist];
}

+ (id)unarchiveObjectWithData:(NSData *)data
{
    //attempt to deserialise data as a plist
    id plist = nil;
    if (data)
    {
        NSPropertyListFormat format;
        NSPropertyListReadOptions options = NSPropertyListMutableContainersAndLeaves;
        plist = [NSPropertyListSerialization propertyListWithData:data options:options format:&format error:NULL];
    }
    
    //unarchive
    return [self unarchiveObjectWithPlist:plist];
}

+ (id)unarchiveObjectWithFile:(NSString *)path
{
    //load the file
    return [self unarchiveObjectWithData:[NSData dataWithContentsOfFile:path]];
}

- (id)unarchiveRootObjectWithPlist:(id)plist
{
    [_stack removeAllObjects];
    [_knownObjects removeAllObjects];
    [_unresolvedAliases removeAllObjects];
    id rootObject = [plist unarchiveObjectWithHRCoder:self];
    if (rootObject)
    {
        _knownObjects[HRCoderRootObjectKey] = rootObject;
        for (NSString *keyPath in _unresolvedAliases)
        {
            id aliasKeyPath = _unresolvedAliases[keyPath];
            id aliasedObject = _knownObjects[aliasKeyPath];
            id node = rootObject;
            for (NSString *key in [keyPath componentsSeparatedByString:@"."])
            {
                id _node = nil;
                if ([node isKindOfClass:[NSArray class]])
                {
                    NSInteger index = [key integerValue];
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

- (id)initForReadingWithData:(NSData *)data
{
    if ((self = [self init]))
    {
        //attempt to deserialise data as a plist
        if (data)
        {
            //load plist
            NSPropertyListReadOptions options = NSPropertyListMutableContainersAndLeaves;
            id plist = [NSPropertyListSerialization propertyListWithData:data
                                                                 options:options
                                                                  format:&_outputFormat
                                                                   error:NULL];
            //only works if root object is a dictionary
            if ([plist isKindOfClass:[NSDictionary class]])
            {
                [_stack addObject:plist];
            }
            else
            {
                [NSException raise:NSGenericException format:@"initForReadingWithData: method requires that the root object in the plist data is an NSDictionary. Decoding an %@ is not supported with this method. Try using unarchiveObjectWithData: instead.", [plist class]];
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

+ (id)archivedPlistWithRootObject:(id)rootObject
{
    HRCoder *coder = [[self alloc] init];
    id plist = [coder archiveRootObject:rootObject];
    
#if !__has_feature(objc_arc)
    [coder release];
#endif
    
    return plist;
}

+ (NSData *)archivedDataWithRootObject:(id)rootObject
{
    NSMutableData *data = [NSMutableData data];
    HRCoder *coder = [[self alloc] initForWritingWithMutableData:data];
    [coder archiveRootObject:rootObject];
    
#if !__has_feature(objc_arc)
    [coder release];
#endif
    
    return data;
}

+ (BOOL)archiveRootObject:(id)rootObject toFile:(NSString *)path
{
    return [[self archivedDataWithRootObject:rootObject] writeToFile:path atomically:YES];
}

- (id)initForWritingWithMutableData:(NSMutableData *)data
{
    if ((self = [self init]))
    {
        //set data
        self.data = data;
    }
    return self;
}

- (id)archiveRootObject:(id)rootObject
{
    [_knownObjects removeAllObjects];
    [self encodeRootObject:rootObject];
    id plist = [_stack lastObject];
    [self finishEncoding];
    return plist;
}

- (void)finishEncoding
{
    if (_data)
    {
        NSData *data = [NSPropertyListSerialization dataWithPropertyList:[_stack lastObject]
                                                                  format:_outputFormat
                                                                 options:0
                                                                   error:NULL];
        [_data setData:data];
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

- (BOOL)containsValueForKey:(NSString *)key
{
    return [_stack lastObject][key] != nil;
}

- (id)encodedObject:(id)object forKey:(NSString *)key
{
    if (object && key)
    {
        if (![object isKindOfClass:[NSNumber class]] &&
            ![object isKindOfClass:[NSDate class]] &&
            (![object isKindOfClass:[NSString class]] || [object length] < 32))
        {
            for (NSString *aliasKeyPath in _knownObjects)
            {
                if (_knownObjects[aliasKeyPath] == object)
                {
                    //create alias
                    return @{HRCoderObjectAliasKey: aliasKeyPath};
                }
            }
        }
        
        //encode object
        NSString *oldKeyPath = _keyPath;
        self.keyPath = _keyPath? [_keyPath stringByAppendingPathExtension:key]: key;
        _knownObjects[_keyPath] = object;
        id encodedObject = [object archivedObjectWithHRCoder:self];
        self.keyPath = oldKeyPath;
        return encodedObject;
    }
    return nil;
}

- (void)encodeObject:(id)objv forKey:(NSString *)key
{
    id object = [self encodedObject:objv forKey:key];
    if (object) [_stack lastObject][key] = object;
}

- (void)encodeRootObject:(id)rootObject
{
    if (rootObject)
    {
        _knownObjects[HRCoderRootObjectKey] = rootObject;
        [_stack setArray:[NSMutableArray arrayWithObject:[rootObject archivedObjectWithHRCoder:self]]];
    }
}

- (void)encodeConditionalObject:(id)objv forKey:(NSString *)key
{
    for (id object in _knownObjects)
    {
        if (object == objv)
        {
            [self encodeObject:objv forKey:key];
            break;
        }
    }
}

- (void)encodeBool:(BOOL)boolv forKey:(NSString *)key
{
    [_stack lastObject][key] = @(boolv);
}

- (void)encodeInt:(int)intv forKey:(NSString *)key
{
    [_stack lastObject][key] = @(intv);
}

- (void)encodeInt32:(int32_t)intv forKey:(NSString *)key
{
    [_stack lastObject][key] = [NSNumber numberWithLong:intv];
}

- (void)encodeInt64:(int64_t)intv forKey:(NSString *)key
{
    [_stack lastObject][key] = @(intv);
}

- (void)encodeFloat:(float)realv forKey:(NSString *)key
{
    [_stack lastObject][key] = @(realv);
}

- (void)encodeDouble:(double)realv forKey:(NSString *)key
{
    [_stack lastObject][key] = @(realv);
}

- (void)encodeBytes:(const uint8_t *)bytesp length:(NSUInteger)lenv forKey:(NSString *)key
{
    [_stack lastObject][key] = [NSData dataWithBytes:bytesp length:lenv];
}

- (id)decodeObject:(id)object forKey:(NSString *)key
{
    if (object && key)
    {
        //new keypath
        NSString *newKeyPath = _keyPath? [_keyPath stringByAppendingPathExtension:key]: key;
        
        //check if object is an alias
        if ([object isKindOfClass:[NSDictionary class]])
        {
            NSString *aliasKeyPath = ((NSDictionary *)object)[HRCoderObjectAliasKey];
            if (aliasKeyPath)
            {
                //object alias
                id decodedObject = _knownObjects[aliasKeyPath];
                if (!decodedObject)
                {
                    _unresolvedAliases[newKeyPath] = aliasKeyPath;
                    decodedObject = [HRCoderAliasPlaceholder placeholder];
                }
                return decodedObject;
            }
        }
        
        //new object
        NSString *oldKeyPath = _keyPath;
        self.keyPath = newKeyPath;
        id decodedObject = [object unarchiveObjectWithHRCoder:self];
        if (decodedObject) _knownObjects[_keyPath] = decodedObject;
        self.keyPath = oldKeyPath;
        return decodedObject;
    }
    return nil;
}

- (id)decodeObjectForKey:(NSString *)key
{
    return [self decodeObject:[_stack lastObject][key] forKey:key];
}

- (BOOL)decodeBoolForKey:(NSString *)key
{
    return [[_stack lastObject][key] boolValue];
}

- (int)decodeIntForKey:(NSString *)key
{
    return [[_stack lastObject][key] intValue];
}

- (int32_t)decodeInt32ForKey:(NSString *)key
{
    return (int32_t)[[_stack lastObject][key] longValue];
}

- (int64_t)decodeInt64ForKey:(NSString *)key
{
    return [[_stack lastObject][key] longLongValue];
}

- (float)decodeFloatForKey:(NSString *)key
{
    return [[_stack lastObject][key] floatValue];
}

- (double)decodeDoubleForKey:(NSString *)key
{
    return [[_stack lastObject][key] doubleValue];
}

- (const uint8_t *)decodeBytesForKey:(NSString *)key returnedLength:(NSUInteger *)lengthp
{
    NSData *data = [_stack lastObject][key];
    *lengthp = [data length];
    return data.bytes;
}

@end


@implementation NSObject(HRCoding)

- (id)unarchiveObjectWithHRCoder:(HRCoder *)coder
{
    [NSException raise:NSGenericException format:@"%@ is not a supported HRCoder archive type", [self class]];
    return nil;
}

- (id)archivedObjectWithHRCoder:(HRCoder *)coder
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [coder.stack addObject:result];
    result[HRCoderClassNameKey] = NSStringFromClass([self classForCoder]);
    [(id <NSCoding>)[self replacementObjectForCoder:coder] encodeWithCoder:coder];
    [coder.stack removeLastObject];
    return result;
}

@end    


@implementation NSDictionary(HRCoding)

- (id)unarchiveObjectWithHRCoder:(HRCoder *)coder
{
    NSString *className = self[HRCoderClassNameKey];
    if (className)
    {
        //encoded object
        [coder.stack addObject:self];
        Class class = NSClassFromString(className);
        id object = [[[class alloc] initWithCoder:coder] awakeAfterUsingCoder:coder];
        
#if !__has_feature(objc_arc)
        [object autorelease];
#endif
        
        [coder.stack removeLastObject];
        return object;
    }
    else
    {
        //ordinary dictionary
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
		[coder.stack addObject:self];
        for (NSString *key in self)
        {
            id object = [coder decodeObjectForKey:key];
            if (object) result[key] = object;
        }
		[coder.stack removeLastObject];
        return result;
    }
}

- (id)archivedObjectWithHRCoder:(HRCoder *)coder
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [coder.stack addObject:result];
    for (NSString *key in self)
    {
        [coder encodeObject:self[key] forKey:key];
    }
    [coder.stack removeLastObject];
    return result;
}

@end


@implementation NSArray(HRCoding)

- (id)unarchiveObjectWithHRCoder:(HRCoder *)coder
{
    NSMutableArray *result = [NSMutableArray array];
    for (int i = 0; i < [self count]; i++)
    {
        NSString *key = [NSString stringWithFormat:@"%i", i];
        id encodedObject = self[i];
        id decodedObject = [coder decodeObject:encodedObject forKey:key];
        [result addObject:decodedObject];
    }
    return result;
}

- (id)archivedObjectWithHRCoder:(HRCoder *)coder
{
    NSMutableArray *result = [NSMutableArray array];
    for (int i = 0; i < [self count]; i++)
    {
        id object = self[i];
        NSString *key = [NSString stringWithFormat:@"%i", i];
        [result addObject:[coder encodedObject:object forKey:key]];
    }
    return result;
}

@end


@implementation NSString(HRCoding)

- (id)unarchiveObjectWithHRCoder:(HRCoder *)coder
{
    return self;
}

- (id)archivedObjectWithHRCoder:(HRCoder *)coder
{
    return self;
}

@end


@implementation NSData(HRCoding)

- (id)unarchiveObjectWithHRCoder:(HRCoder *)coder
{
    return self;
}

- (id)archivedObjectWithHRCoder:(HRCoder *)coder
{
    return self;
}

@end


@implementation NSNumber(HRCoding)

- (id)unarchiveObjectWithHRCoder:(HRCoder *)coder
{
    return self;
}

- (id)archivedObjectWithHRCoder:(HRCoder *)coder
{
    return self;
}

@end


@implementation NSDate(HRCoding)

- (id)unarchiveObjectWithHRCoder:(HRCoder *)coder
{
    return self;
}

- (id)archivedObjectWithHRCoder:(HRCoder *)coder
{
    return self;
}

@end
