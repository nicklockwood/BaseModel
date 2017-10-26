//
//  CryptoCoding.m
//
//  Version 1.1.1
//
//  Created by Nick Lockwood on 23/09/2012.
//  Copyright (c) 2011 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/CryptoCoding
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

#import "CryptoCoding.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>


#pragma clang diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
#pragma clang diagnostic ignored "-Wpartial-availability"
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
#pragma clang diagnostic ignored "-Wdouble-promotion"
#pragma clang diagnostic ignored "-Wfloat-conversion"
#pragma clang diagnostic ignored "-Wgnu"


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


NSString *const CryptoCoderErrorDomain = @"CryptoCoderErrorDomain";
NSString *const CryptoCoderException = @"CryptoCoderException";

#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_5_0) || \
    (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_7)

const float CryptoCodingVersion = 1.0f;

#else

const float CryptoCodingVersion = 2.0f;

#endif


@implementation NSData (CryptoCoding)

//based on blog post by Rob Napier: http://robnapier.net/blog/aes-commoncrypto-564

+ (NSData *)AESKeyWithPassword:(NSString *)password salt:(NSData *)salt error:(__autoreleasing NSError **)error version:(float)version
{
    if ((version ?: CryptoCodingVersion) >= 2.0f)
    {
      
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_5_0) || \
    (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_7)
      
        //generate key using CCKeyDerivationPBKDF
        NSMutableData *key = [NSMutableData dataWithLength:kCCKeySizeAES128];
        int result = CCKeyDerivationPBKDF(kCCPBKDF2, // algorithm
                                          password.UTF8String, // password
                                          [password lengthOfBytesUsingEncoding:NSUTF8StringEncoding], // password length
                                          salt.bytes, // salt
                                          salt.length, // salt length
                                          kCCPRFHmacAlgSHA1, // PRF
                                          1024, // rounds
                                          key.mutableBytes, // derived key
                                          key.length); // derived key length
      
#else
      
        //CCKeyDerivationPBKDF is not available on iOS < 5 or Mac OS < 10.7
        NSMutableData *key = nil;
        int result = kCCUnimplemented;
      
#endif
      
        if (result == kCCSuccess)
        {
            return key;
        }
        else
        {
            if (error) *error = [NSError errorWithDomain:CryptoCoderErrorDomain code:result userInfo:@{NSLocalizedDescriptionKey: @"Could not generate encryption key"}];
            return nil;
        }
    }
    else
    {
        //use legacy key generation mechanism
        NSMutableData *key = [NSMutableData dataWithData:[password dataUsingEncoding:NSUTF8StringEncoding]];
        [key appendData:salt];
        key.length = MAX([key length], CC_MD5_DIGEST_LENGTH);
        for (NSInteger i = 0; i < 1024; i++)
        {
            CC_MD5(key.bytes, (CC_LONG)key.length, key.mutableBytes);
            [key setLength:CC_MD5_DIGEST_LENGTH];
        }
        key.length = kCCKeySizeAES128;
        return key;
    }
}

- (NSData *)AESEncryptedDataWithPassword:(NSString *)password IV:(__autoreleasing NSData **)IV salt:(__autoreleasing NSData **)salt error:(__autoreleasing NSError **)error version:(float)version
{        
    //generate IV if not supplied
    if (*IV == nil)
    {
        *IV = [NSMutableData dataWithLength:kCCBlockSizeAES128];
        if (SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, ((NSMutableData *)*IV).mutableBytes))
        {
            if (error) *error = [NSError errorWithDomain:CryptoCoderErrorDomain code:errno userInfo:@{NSLocalizedDescriptionKey: @"Could not generate initialization vector value"}];
            return nil;
        }
    }
    
    //generate salt if not supplied
    if (*salt == nil)
    {
        *salt = [NSMutableData dataWithLength:8];
        if (SecRandomCopyBytes(kSecRandomDefault, [*salt length], ((NSMutableData *)*salt).mutableBytes))
        {
            if (error) *error = [NSError errorWithDomain:CryptoCoderErrorDomain code:errno userInfo:@{NSLocalizedDescriptionKey: @"Could not generate salt value"}];
            return nil;
        }
    }
    
    //generate key
    NSData *key = [NSData AESKeyWithPassword:password salt:*salt error:error version:version];
    if (!key) return nil;
    
    //encrypt the data
    size_t length = 0;
    NSMutableData *cypher = [NSMutableData dataWithLength:self.length + kCCBlockSizeAES128];
    CCCryptorStatus result = CCCrypt(kCCEncrypt, // operation
                                     kCCAlgorithmAES128, // algorithm
                                     kCCOptionPKCS7Padding, // options
                                     key.bytes, // key
                                     key.length, // key length
                                     (*IV).bytes, // iv
                                     self.bytes, // input
                                     self.length, // data length,
                                     cypher.mutableBytes, // ouput
                                     cypher.length, // output max length
                                     &length); // output length
    if (result == kCCSuccess)
    {
        cypher.length = length;
    }
    else
    {
        if (error) *error = [NSError errorWithDomain:CryptoCoderErrorDomain code:result userInfo:@{NSLocalizedDescriptionKey: @"Could not encrypt data"}];
        return nil;
    }
    return cypher;
}

- (NSData *)AESDecryptedDataWithPassword:(NSString *)password IV:(NSData *)IV salt:(NSData *)salt error:(__autoreleasing NSError **)error version:(float)version
{
    //generate key
    NSData *key = [NSData AESKeyWithPassword:password salt:salt error:error version:version];

    //decrypt the data
    size_t length = 0;
    NSMutableData *cleartext = [NSMutableData dataWithLength:self.length + kCCBlockSizeAES128];
    CCCryptorStatus result = CCCrypt(kCCDecrypt, // operation
                                     kCCAlgorithmAES128, // algorithm
                                     kCCOptionPKCS7Padding, // options
                                     key.bytes, // key
                                     key.length, // key length
                                     IV.bytes, // iv
                                     self.bytes, // input
                                     self.length, // data length,
                                     cleartext.mutableBytes, // ouput
                                     cleartext.length, // output max length
                                     &length); // output length
    if (result == kCCSuccess)
    {
        cleartext.length = length;
    }
    else
    {
        if (error) *error = [NSError errorWithDomain:CryptoCoderErrorDomain code:result userInfo:@{NSLocalizedDescriptionKey: @"Could not decrypt data"}];
        return nil;
    }
    return cleartext;
}

@end


@interface CryptoArchive ()

@property (nonatomic, strong) NSData *iv;
@property (nonatomic, strong) NSData *salt;
@property (nonatomic, strong) NSData *cypher;
@property (nonatomic, strong) Class rootObjectClass;
@property (nonatomic, assign) float version;

@end


@implementation CryptoArchive

- (instancetype)initWithRootObject:(id<NSCoding>)rootObject password:(NSString *)password
{
    if ((self = [self init]))
    {
        NSData *iv = nil;
        NSData *salt = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rootObject];
        self.version = CryptoCodingVersion;
        self.rootObjectClass = [(NSObject *)rootObject classForCoder];
        self.cypher = [data AESEncryptedDataWithPassword:password IV:&iv salt:&salt error:NULL version:CryptoCodingVersion];
        self.salt = salt;
        self.iv = iv;
    }
    return self;
}

- (id)unarchiveRootObjectWithPassword:(NSString *)password
{
    if (floor(_version) <= CryptoCodingVersion)
    {
        NSData *data = [_cypher AESDecryptedDataWithPassword:password IV:_iv salt:_salt error:NULL version:_version];
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    else
    {
        NSLog(@"Unsupported CryptoArchive version (%f)", _version);
        return nil;
    }
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ([aDecoder respondsToSelector:@selector(decodeObjectOfClass:forKey:)])
    {
        //secure coding
        self.iv = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"iv"];
        self.salt = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"salt"];
        self.cypher = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"cypher"];
        self.rootObjectClass = NSClassFromString([aDecoder decodeObjectOfClass:[NSString class] forKey:@"className"]);
        self.version = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@"version"] floatValue];
    }
    else
    {
        //regular coding
        self.iv = [aDecoder decodeObjectForKey:@"iv"];
        self.salt = [aDecoder decodeObjectForKey:@"salt"];
        self.cypher = [aDecoder decodeObjectForKey:@"cypher"];
        self.rootObjectClass = NSClassFromString([aDecoder decodeObjectForKey:@"className"]);
        self.version = [[aDecoder decodeObjectForKey:@"version"] floatValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_iv forKey:@"iv"];
    [aCoder encodeObject:_salt forKey:@"salt"];
    [aCoder encodeObject:_cypher forKey:@"cypher"];
    [aCoder encodeObject:NSStringFromClass(_rootObjectClass) forKey:@"className"];
    [aCoder encodeObject:@(_version) forKey:@"version"];
}

- (id)copyWithZone:(NSZone *)zone
{
    CryptoArchive *copy = [[CryptoArchive allocWithZone:zone] init];
    copy.iv = _iv;
    copy.salt = _salt;
    copy.cypher = _cypher;
    copy.rootObjectClass = _rootObjectClass;
    copy.version = _version;
    return copy;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p version=%g>", [self class], (void *)self, _version];
}

@end


@implementation CryptoCoder

+ (id)unarchiveObjectWithData:(NSData *)data
{
    id object = data? [NSKeyedUnarchiver unarchiveObjectWithData:data]: nil;
    if ([object isKindOfClass:[CryptoArchive class]])
    {
        CryptoArchive *archive = object;
        Class class = archive.rootObjectClass;
        if ([class respondsToSelector:@selector(CCPassword)])
        {
            NSString *password = [class CCPassword];
            object = [archive unarchiveRootObjectWithPassword:password];
        }
        else
        {
            [NSException raise:CryptoCoderException format:@"%@ does not conform to the CryptoCoding protocol", class];
            object = nil;
        }
    }
    return object;
}

+ (id)unarchiveObjectWithFile:(NSString *)path
{
    //load the file
    return [self unarchiveObjectWithData:[NSData dataWithContentsOfFile:path]];
}

+ (NSData *)archivedDataWithRootObject:(id<CryptoCoding>)rootObject
{
    Class class = [(NSObject *)rootObject classForCoder];
    if ([class respondsToSelector:@selector(CCPassword)])
    {
        NSString *password = [class CCPassword];
        CryptoArchive *archive = [[CryptoArchive alloc] initWithRootObject:rootObject password:password];
        return [NSKeyedArchiver archivedDataWithRootObject:archive];
    }
    else
    {
        [NSException raise:CryptoCoderException format:@"%@ does not conform to the CryptoCoding protocol", class];
        return nil;
    }
}

+ (BOOL)archiveRootObject:(id<CryptoCoding>)rootObject toFile:(NSString *)path
{
    return [[self archivedDataWithRootObject:rootObject] writeToFile:path atomically:YES];
}

+ (void)setClassName:(NSString *)codedName forClass:(Class)cls
{
    [NSKeyedArchiver setClassName:codedName forClass:cls];
}

+ (NSString *)classNameForClass:(Class)cls
{
    return [NSKeyedArchiver classNameForClass:cls];
}

+ (void)setClass:(Class)cls forClassName:(NSString *)codedName
{
    [NSKeyedUnarchiver setClass:cls forClassName:codedName];
}

+ (Class)classForClassName:(NSString *)codedName
{
    return [NSKeyedUnarchiver classForClassName:codedName];
}

@end
