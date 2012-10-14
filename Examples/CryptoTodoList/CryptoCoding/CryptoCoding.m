//
//  CryptoCoding.m
//
//  Version 1.0
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


NSString *const CryptoCoderErrorDomain = @"CryptoCoderErrorDomain";
NSString *const CryptoCoderException = @"CryptoCoderException";


const float CryptoCodingVersion = 1.0f;


@implementation NSData (CryptoCoding)

//based on blog post by Rob Napier: http://robnapier.net/blog/aes-commoncrypto-564

+ (NSData *)AESKeyWithPassword:(NSString *)password salt:(NSData *)salt
{    
    //generate key. ideally we'd just use the CCKeyDerivationPBKDF
    //method for this but it's not available on iOS < 5 or Mac OS < 10.7
    NSMutableData *key = [NSMutableData dataWithData:[password dataUsingEncoding:NSUTF8StringEncoding]];
    [key appendData:salt];
    key.length = MAX([key length], CC_MD5_DIGEST_LENGTH);
    for (int i = 0; i < 1024; i++)
    {
        CC_MD5(key.bytes, key.length, key.mutableBytes);
        [key setLength:CC_MD5_DIGEST_LENGTH];
    }
    key.length = kCCKeySizeAES128;
    return key;
}

- (NSData *)AESEncryptedDataWithPassword:(NSString *)password IV:(NSData **)IV salt:(NSData **)salt error:(NSError **)error
{        
    //generate IV if not supplied
    if (*IV == nil)
    {
        *IV = [NSMutableData dataWithLength:kCCBlockSizeAES128];
        if (SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, ((NSMutableData *)*IV).mutableBytes))
        {
            if (error) *error = [NSError errorWithDomain:CryptoCoderErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObject:@"Could not generate initialization vector value" forKey:NSLocalizedDescriptionKey]];
            return nil;
        }
    }
    
    //generate salt if not supplied
    if (*salt == nil)
    {
        *salt = [NSMutableData dataWithLength:8];
        if (SecRandomCopyBytes(kSecRandomDefault, [*salt length], ((NSMutableData *)*salt).mutableBytes))
        {
            if (error) *error = [NSError errorWithDomain:CryptoCoderErrorDomain code:errno userInfo:[NSDictionary dictionaryWithObject:@"Could not generate salt value" forKey:NSLocalizedDescriptionKey]];
            return nil;
        }
    }
    
    //generate key
    NSData *key = [NSData AESKeyWithPassword:password salt:*salt];
    
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
        if (error) *error = [NSError errorWithDomain:CryptoCoderErrorDomain code:result userInfo:[NSDictionary dictionaryWithObject:@"Could not encrypt data" forKey:NSLocalizedDescriptionKey]];
		return nil;
	}
	return cypher;
}

- (NSData *)AESDecryptedDataWithPassword:(NSString *)password IV:(NSData *)IV salt:(NSData *)salt error:(NSError **)error
{
    //generate key
    NSData *key = [NSData AESKeyWithPassword:password salt:salt];

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
        if (error) *error = [NSError errorWithDomain:CryptoCoderErrorDomain code:result userInfo:[NSDictionary dictionaryWithObject:@"Could not decrypt data" forKey:NSLocalizedDescriptionKey]];
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

@synthesize iv = _iv;
@synthesize salt = _salt;
@synthesize cypher = _cypher;
@synthesize rootObjectClass = _rootObjectClass;

- (id)initWithRootObject:(id)rootObject password:(NSString *)password
{
    if ((self = [self init]))
    {
        NSData *iv = nil;
        NSData *salt = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rootObject];
        self.version = CryptoCodingVersion;
        self.rootObjectClass = [rootObject class];
        self.cypher = [data AESEncryptedDataWithPassword:password IV:&iv salt:&salt error:NULL];
        self.salt = salt;
        self.iv = iv;
    }
    return self;
}

- (id)unarchiveRootObjectWithPassword:(NSString *)password
{
    if (floor(_version) <= CryptoCodingVersion)
    {
        NSData *data = [_cypher AESDecryptedDataWithPassword:password IV:_iv salt:_salt error:NULL];
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

- (id)initWithCoder:(NSCoder *)aDecoder
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
    [aCoder encodeObject:[NSNumber numberWithFloat:_version] forKey:@"version"];
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
    return [NSString stringWithFormat:@"<%@: 0x%x version=%g>", [self class], (int)self, _version];
}

#if !__has_feature(objc_arc)

- (void)dealloc
{
    [_iv release];
    [_salt release];
    [_cypher release];
    [_rootObjectClass release];
    [super dealloc];
}

#endif

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

+ (NSData *)archivedDataWithRootObject:(id)rootObject
{
    Class class = [rootObject class];
    if ([class respondsToSelector:@selector(CCPassword)])
    {
        NSString *password = [class CCPassword];
        CryptoArchive *archive = [[CryptoArchive alloc] initWithRootObject:rootObject password:password];
        
#if !__has_feature(objc_arc)
        [archive autorelease];
#endif
        
        return [NSKeyedArchiver archivedDataWithRootObject:archive];
    }
    else
    {
        [NSException raise:CryptoCoderException format:@"%@ does not conform to the CryptoCoding protocol", class];
        return nil;
    }
}

+ (BOOL)archiveRootObject:(id)rootObject toFile:(NSString *)path
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
