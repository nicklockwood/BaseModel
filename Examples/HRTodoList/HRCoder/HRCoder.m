//
//  HRCoder.m
//
//  Version 1.1.3
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


@interface NSObject (HRCoding)

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
        _stack = [[NSMutableArray alloc] initWithObjects:[NSMutableDictionary dictionary], nil];
        _knownObjects = [[NSMutableDictionary alloc] init];
        _unresolvedAliases = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (id)unarchiveObjectWithPlist:(id)plist
{
    HRCoder *coder = [[self alloc] init];
    
#if !__has_feature(objc_arc)
    [coder autorelease];
#endif
    
    return [coder unarchiveObjectWithPlist:plist];
}

+ (id)unarchiveObjectWithData:(NSData *)data
{
    HRCoder *coder = [[self alloc] init];
    
#if !__has_feature(objc_arc)
    [coder autorelease];
#endif
    
    return [coder unarchiveObjectWithData:data];
}

+ (id)unarchiveObjectWithFile:(NSString *)path
{
    HRCoder *coder = [[self alloc] init];
    
#if !__has_feature(objc_arc)
    [coder autorelease];
#endif
    
    return [coder unarchiveObjectWithFile:path];
}

+ (id)archivedPlistWithRootObject:(id)rootObject
{
    HRCoder *coder = [[self alloc] init];
    
#if !__has_feature(objc_arc)
    [coder autorelease];
#endif
    
    return [coder archivedPlistWithRootObject:rootObject];
}

+ (NSData *)archivedDataWithRootObject:(id)rootObject
{
    HRCoder *coder = [[self alloc] init];
    
#if !__has_feature(objc_arc)
    [coder autorelease];
#endif
    
    return [coder archivedDataWithRootObject:rootObject];
}

+ (BOOL)archiveRootObject:(id)rootObject toFile:(NSString *)path
{
    HRCoder *coder = [[self alloc] init];
    
#if !__has_feature(objc_arc)
    [coder autorelease];
#endif
    
    return [coder archiveRootObject:rootObject toFile:path];
}

- (id)unarchiveObjectWithPlist:(id)plist
{
    [_stack removeAllObjects];
    [_knownObjects removeAllObjects];
    [_unresolvedAliases removeAllObjects];
    id rootObject = [plist unarchiveObjectWithHRCoder:self];
    if (rootObject)
    {
        [_knownObjects setObject:rootObject forKey:HRCoderRootObjectKey];
        for (NSString *keyPath in _unresolvedAliases)
        {
            id aliasKeyPath = [_unresolvedAliases objectForKey:keyPath];
            id aliasedObject = [_knownObjects objectForKey:aliasKeyPath];
            id node = rootObject;
            for (NSString *key in [_keyPath componentsSeparatedByString:@"."])
            {
                id _node = nil;
                if ([node isKindOfClass:[NSArray class]])
                {
                    NSInteger index = [key integerValue];
                    _node = [node objectAtIndex:index];
                    if (_node == [HRCoderAliasPlaceholder placeholder])
                    {
                        [node replaceObjectAtIndex:index withObject:aliasedObject];
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
    [_unresolvedAliases removeAllObjects];
    [_knownObjects removeAllObjects];
    [_stack removeAllObjects];
    return rootObject;
}

- (id)unarchiveObjectWithData:(NSData *)data
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

- (id)unarchiveObjectWithFile:(NSString *)path
{
    //load the file
    return [self unarchiveObjectWithData:[NSData dataWithContentsOfFile:path]];
}

- (id)archivedPlistWithRootObject:(id)rootObject
{
    [_stack removeAllObjects];
    [_knownObjects removeAllObjects];
    if (rootObject) [_knownObjects setObject:rootObject forKey:HRCoderRootObjectKey];
    id plist = [rootObject archivedObjectWithHRCoder:self];
    [_knownObjects removeAllObjects];
    [_stack removeAllObjects];
    return plist;
}

- (NSData *)archivedDataWithRootObject:(id)rootObject
{
    id object = [self archivedPlistWithRootObject:rootObject];
    NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
    return [NSPropertyListSerialization dataWithPropertyList:object format:format options:0 error:NULL];
}

- (BOOL)archiveRootObject:(id)rootObject toFile:(NSString *)path
{
    return [[self archivedDataWithRootObject:rootObject] writeToFile:path atomically:YES];
}

#if !__has_feature(objc_arc)

- (void)dealloc
{
    [_stack release];
    [_knownObjects release];
    [_unresolvedAliases release];
    [_keyPath release];
    [super dealloc];
}

#endif

- (BOOL)allowsKeyedCoding
{
    return YES;
}

- (BOOL)containsValueForKey:(NSString *)key
{
    return [[_stack lastObject] objectForKey:key] != nil;
}

- (id)encodedObject:(id)object forKey:(NSString *)key
{
    if (object && key)
    {
        NSInteger knownIndex = [[_knownObjects allValues] indexOfObject:object];
        if (knownIndex != NSNotFound)
        {
            //create alias
            NSString *aliasKeyPath = [[_knownObjects allKeys] objectAtIndex:knownIndex];
            NSDictionary *alias = [NSDictionary dictionaryWithObject:aliasKeyPath forKey:HRCoderObjectAliasKey];
            return alias;
        }
        else
        {
            //encode object
            NSString *oldKeyPath = _keyPath;
            self.keyPath = _keyPath? [_keyPath stringByAppendingPathExtension:key]: key;
            [_knownObjects setObject:object forKey:_keyPath];
            id encodedObject = [object archivedObjectWithHRCoder:self];
            self.keyPath = oldKeyPath;
            return encodedObject;
        }
    }
    return nil;
}

- (void)encodeObject:(id)objv forKey:(NSString *)key
{
    id object = [self encodedObject:objv forKey:key];
    if (object) [[_stack lastObject] setObject:object forKey:key];
}

- (void)encodeConditionalObject:(id)objv forKey:(NSString *)key
{
    if ([[_knownObjects allValues] containsObject:objv])
    {
        [self encodeObject:objv forKey:key];
    }
}

- (void)encodeBool:(BOOL)boolv forKey:(NSString *)key
{
    [[_stack lastObject] setObject:[NSNumber numberWithBool:boolv] forKey:key];
}

- (void)encodeInt:(int)intv forKey:(NSString *)key
{
    [[_stack lastObject] setObject:[NSNumber numberWithInt:intv] forKey:key];
}

- (void)encodeInt32:(int32_t)intv forKey:(NSString *)key
{
    [[_stack lastObject] setObject:[NSNumber numberWithLong:intv] forKey:key];
}

- (void)encodeInt64:(int64_t)intv forKey:(NSString *)key
{
    [[_stack lastObject] setObject:[NSNumber numberWithLongLong:intv] forKey:key];
}

- (void)encodeFloat:(float)realv forKey:(NSString *)key
{
    [[_stack lastObject] setObject:[NSNumber numberWithFloat:realv] forKey:key];
}

- (void)encodeDouble:(double)realv forKey:(NSString *)key
{
    [[_stack lastObject] setObject:[NSNumber numberWithDouble:realv] forKey:key];
}

- (void)encodeBytes:(const uint8_t *)bytesp length:(NSUInteger)lenv forKey:(NSString *)key
{
    [[_stack lastObject] setObject:[NSData dataWithBytes:bytesp length:lenv] forKey:key];
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
            NSString *aliasKeyPath = [(NSDictionary *)object objectForKey:HRCoderObjectAliasKey];
            if (aliasKeyPath)
            {
                //object alias
                id decodedObject = [_knownObjects objectForKey:aliasKeyPath];
                if (!decodedObject)
                {
                    [_unresolvedAliases setObject:aliasKeyPath forKey:newKeyPath];
                    decodedObject = [HRCoderAliasPlaceholder placeholder];
                }
                return decodedObject;
            }
        }
        
        //new object
        NSString *oldKeyPath = _keyPath;
        self.keyPath = newKeyPath;
        id decodedObject = [object unarchiveObjectWithHRCoder:self];
        if (decodedObject) [_knownObjects setObject:decodedObject forKey:_keyPath];
        self.keyPath = oldKeyPath;
        return decodedObject;
    }
    return nil;
}

- (id)decodeObjectForKey:(NSString *)key
{
    return [self decodeObject:[[_stack lastObject] objectForKey:key] forKey:key];
}

- (BOOL)decodeBoolForKey:(NSString *)key
{
    return [[[_stack lastObject] objectForKey:key] boolValue];
}

- (int)decodeIntForKey:(NSString *)key
{
    return [[[_stack lastObject] objectForKey:key] intValue];
}

- (int32_t)decodeInt32ForKey:(NSString *)key
{
    return [[[_stack lastObject] objectForKey:key] longValue];
}

- (int64_t)decodeInt64ForKey:(NSString *)key
{
    return [[[_stack lastObject] objectForKey:key] longLongValue];
}

- (float)decodeFloatForKey:(NSString *)key
{
    return [[[_stack lastObject] objectForKey:key] floatValue];
}

- (double)decodeDoubleForKey:(NSString *)key
{
    return [[[_stack lastObject] objectForKey:key] doubleValue];
}

- (const uint8_t *)decodeBytesForKey:(NSString *)key returnedLength:(NSUInteger *)lengthp
{
    NSData *data = [[_stack lastObject] objectForKey:key];
    *lengthp = [data length];
    return data.bytes;
}

@end


@implementation NSObject(HRCoding)

- (BOOL)useHRCoderIfAvailable
{
    return YES;
}

- (id)unarchiveObjectWithHRCoder:(HRCoder *)coder
{
    return self;
}

- (id)archivedObjectWithHRCoder:(HRCoder *)coder
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [coder.stack addObject:result];
    [result setObject:NSStringFromClass([self classForCoder]) forKey:HRCoderClassNameKey];
    [(id <NSCoding>)[self replacementObjectForCoder:coder] encodeWithCoder:coder];
    [coder.stack removeLastObject];
    return result;
}

@end    


@implementation NSDictionary(HRCoding)

- (id)unarchiveObjectWithHRCoder:(HRCoder *)coder
{
    NSString *className = [self objectForKey:HRCoderClassNameKey];
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
        for (NSString *key in self)
        {
            id object = [coder decodeObjectForKey:key];
            if (object) [result setObject:object forKey:key];
        }
        result = [result copy];
        
#if !__has_feature(objc_arc)
        [result autorelease];
#endif
        
        return result;
    }
}

- (id)archivedObjectWithHRCoder:(HRCoder *)coder
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [coder.stack addObject:result];
    for (NSString *key in self)
    {
        [coder encodeObject:[self objectForKey:key] forKey:key];
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
        id encodedObject = [self objectAtIndex:i];
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
        id object = [self objectAtIndex:i];
        NSString *key = [NSString stringWithFormat:@"%i", i];
        [result addObject:[coder encodedObject:object forKey:key]];
    }
    return result;
}

@end


@implementation NSString(HRCoding)
    
- (id)archivedObjectWithHRCoder:(HRCoder *)coder
{
    return self;
}

@end


@implementation NSData(HRCoding)

- (id)archivedObjectWithHRCoder:(HRCoder *)coder
{
    return self;
}

@end


@implementation NSNumber(HRCoding)

- (id)archivedObjectWithHRCoder:(HRCoder *)coder
{
    return self;
}

@end


@implementation NSDate(HRCoding)

- (id)archivedObjectWithHRCoder:(HRCoder *)coder
{
    return self;
}

@end
