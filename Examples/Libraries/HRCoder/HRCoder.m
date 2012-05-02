//
//  HRCoder.m
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

@synthesize stack;
@synthesize knownObjects;
@synthesize unresolvedAliases;
@synthesize keyPath;

+ (NSString *)classNameKey
{
    //used by BaseModel
    return HRCoderClassNameKey;
}

- (id)init
{
    if ((self = [super init]))
    {
        stack = [[NSMutableArray alloc] initWithObjects:[NSMutableDictionary dictionary], nil];
        knownObjects = [[NSMutableDictionary alloc] init];
        unresolvedAliases = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (id)unarchiveObjectWithPlist:(id)plist
{
    return [AH_AUTORELEASE([[self alloc] init]) unarchiveObjectWithPlist:plist];
}

+ (id)unarchiveObjectWithFile:(NSString *)path
{
    return [AH_AUTORELEASE([[self alloc] init]) unarchiveObjectWithFile:path];
}

+ (id)archivedPlistWithRootObject:(id)object
{
    return [AH_AUTORELEASE([[self alloc] init]) archivedPlistWithRootObject:object];
}

+ (BOOL)archiveRootObject:(id)rootObject toFile:(NSString *)path
{
    return [AH_AUTORELEASE([[self alloc] init]) archiveRootObject:rootObject toFile:path];
}

- (id)unarchiveObjectWithPlist:(id)plist
{
    [stack removeAllObjects];
    [knownObjects removeAllObjects];
    [unresolvedAliases removeAllObjects];
    id rootObject = [plist unarchiveObjectWithHRCoder:self];
    if (rootObject)
    {
        [knownObjects setObject:rootObject forKey:HRCoderRootObjectKey];
        for (NSString *_keyPath in unresolvedAliases)
        {
            id aliasKeyPath = [unresolvedAliases objectForKey:_keyPath];
            id aliasedObject = [knownObjects objectForKey:aliasKeyPath];
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
    [unresolvedAliases removeAllObjects];
    [knownObjects removeAllObjects];
    [stack removeAllObjects];
    return rootObject;
}

- (id)unarchiveObjectWithFile:(NSString *)path
{
    //load the file
    NSData *data = [NSData dataWithContentsOfFile:path];
    
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

- (id)archivedPlistWithRootObject:(id)rootObject
{
    [stack removeAllObjects];
    [knownObjects removeAllObjects];
    [knownObjects setObject:rootObject forKey:HRCoderRootObjectKey];
    id plist = [rootObject archivedObjectWithHRCoder:self];
    [knownObjects removeAllObjects];
    [stack removeAllObjects];
    return plist;
}

- (BOOL)archiveRootObject:(id)rootObject toFile:(NSString *)path
{
    id object = [self archivedPlistWithRootObject:rootObject];
    NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:object format:format options:0 error:NULL];
    return [data writeToFile:path atomically:YES];
}

- (void)dealloc
{
    AH_RELEASE(stack);
    AH_RELEASE(knownObjects);
    AH_RELEASE(unresolvedAliases);
    AH_SUPER_DEALLOC;
}

- (BOOL)allowsKeyedCoding
{
    return YES;
}

- (BOOL)containsValueForKey:(NSString *)key
{
    return [[stack lastObject] objectForKey:key] != nil;
}

- (id)encodedObject:(id)objv forKey:(NSString *)key
{
    NSInteger knownIndex = [[knownObjects allValues] indexOfObject:objv];
    if (knownIndex != NSNotFound)
    {
        //create alias
        NSString *aliasKeyPath = [[knownObjects allKeys] objectAtIndex:knownIndex];
        NSDictionary *alias = [NSDictionary dictionaryWithObject:aliasKeyPath forKey:HRCoderObjectAliasKey];
        return alias;
    }
    else
    {
        //encode object
        NSString *oldKeyPath = keyPath;
        self.keyPath = keyPath? [keyPath stringByAppendingPathExtension:key]: key;
        [knownObjects setObject:objv forKey:keyPath];
        id encodedObject = [objv archivedObjectWithHRCoder:self];
        self.keyPath = oldKeyPath;
        return encodedObject;
    }
}

- (void)encodeObject:(id)objv forKey:(NSString *)key
{
    id object = [self encodedObject:objv forKey:key];
    [[stack lastObject] setObject:object forKey:key];
}

- (void)encodeConditionalObject:(id)objv forKey:(NSString *)key
{
    if ([[knownObjects allValues] containsObject:objv])
    {
        [self encodeObject:objv forKey:key];
    }
}

- (void)encodeBool:(BOOL)boolv forKey:(NSString *)key
{
    [[stack lastObject] setObject:[NSNumber numberWithBool:boolv] forKey:key];
}

- (void)encodeInt:(int)intv forKey:(NSString *)key
{
    [[stack lastObject] setObject:[NSNumber numberWithInt:intv] forKey:key];
}

- (void)encodeInt32:(int32_t)intv forKey:(NSString *)key
{
    [[stack lastObject] setObject:[NSNumber numberWithLong:intv] forKey:key];
}

- (void)encodeInt64:(int64_t)intv forKey:(NSString *)key
{
    [[stack lastObject] setObject:[NSNumber numberWithLongLong:intv] forKey:key];
}

- (void)encodeFloat:(float)realv forKey:(NSString *)key
{
    [[stack lastObject] setObject:[NSNumber numberWithFloat:realv] forKey:key];
}

- (void)encodeDouble:(double)realv forKey:(NSString *)key
{
    [[stack lastObject] setObject:[NSNumber numberWithDouble:realv] forKey:key];
}

- (void)encodeBytes:(const uint8_t *)bytesp length:(NSUInteger)lenv forKey:(NSString *)key
{
    [[stack lastObject] setObject:[NSData dataWithBytes:bytesp length:lenv] forKey:key];
}

- (id)decodeObject:(id)object forKey:(NSString *)key
{
    if (object && key)
    {
        //new keypath
        NSString *newKeyPath = keyPath? [keyPath stringByAppendingPathExtension:key]: key;
        
        //check if object is an alias
        if ([object isKindOfClass:[NSDictionary class]])
        {
            NSString *aliasKeyPath = [(NSDictionary *)object objectForKey:HRCoderObjectAliasKey];
            if (aliasKeyPath)
            {
                //object alias
                id decodedObject = [knownObjects objectForKey:aliasKeyPath];
                if (!decodedObject)
                {
                    [unresolvedAliases setObject:aliasKeyPath forKey:newKeyPath];
                    decodedObject = [HRCoderAliasPlaceholder placeholder];
                }
                return decodedObject;
            }
        }
        
        //new object
        NSString *oldKeyPath = keyPath;
        self.keyPath = newKeyPath;
        id decodedObject = [object unarchiveObjectWithHRCoder:self];
        [knownObjects setObject:decodedObject forKey:keyPath];
        self.keyPath = oldKeyPath;
        return decodedObject;
    }
    return nil;
}

- (id)decodeObjectForKey:(NSString *)key
{
    return [self decodeObject:[[stack lastObject] objectForKey:key] forKey:key];
}

- (BOOL)decodeBoolForKey:(NSString *)key
{
    return [[[stack lastObject] objectForKey:key] boolValue];
}

- (int)decodeIntForKey:(NSString *)key
{
    return [[[stack lastObject] objectForKey:key] intValue];
}

- (int32_t)decodeInt32ForKey:(NSString *)key
{
    return [[[stack lastObject] objectForKey:key] longValue];
}

- (int64_t)decodeInt64ForKey:(NSString *)key
{
    return [[[stack lastObject] objectForKey:key] longLongValue];
}

- (float)decodeFloatForKey:(NSString *)key
{
    return [[[stack lastObject] objectForKey:key] floatValue];
}

- (double)decodeDoubleForKey:(NSString *)key
{
    return [[[stack lastObject] objectForKey:key] doubleValue];
}

- (const uint8_t *)decodeBytesForKey:(NSString *)key returnedLength:(NSUInteger *)lengthp
{
    NSData *data = [[stack lastObject] objectForKey:key];
    *lengthp = [data length];
    return data.bytes;
}

@end


@implementation NSObject(HRCoding)

- (id)unarchiveObjectWithHRCoder:(HRCoder *)coder
{
    return self;
}

- (id)archivedObjectWithHRCoder:(HRCoder *)coder
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [coder.stack addObject:result];
    [result setObject:NSStringFromClass([self class]) forKey:HRCoderClassNameKey];
    [(id <NSCoding>)self encodeWithCoder:coder];
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
        id object = AH_AUTORELEASE([[class alloc] initWithCoder:coder]);
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
            if (object)
            {
                [result setObject:object forKey:key];
            }
        }
        return AH_AUTORELEASE([result copy]);
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
