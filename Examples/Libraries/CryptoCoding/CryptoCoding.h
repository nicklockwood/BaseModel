//
//  CryptoCoding.h
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


#import <Foundation/Foundation.h>


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"


extern NSString *const CryptoCoderErrorDomain;
extern NSString *const CryptoCoderException;


extern const float CryptoCodingVersion;


@interface NSData (CryptoCoding)

- (NSData *)AESEncryptedDataWithPassword:(NSString *)password
                                      IV:(NSData **)IV
                                    salt:(NSData **)salt
                                   error:(NSError **)error
                                 version:(float)version;

- (NSData *)AESDecryptedDataWithPassword:(NSString *)password
                                      IV:(NSData *)IV
                                    salt:(NSData *)salt
                                   error:(NSError **)error
                                 version:(float)version;
@end


@interface CryptoArchive : NSObject <NSSecureCoding, NSCopying>

@property (nonatomic, strong, readonly) NSData *iv;
@property (nonatomic, strong, readonly) NSData *salt;
@property (nonatomic, strong, readonly) NSData *cypher;
@property (nonatomic, strong, readonly) Class rootObjectClass;
@property (nonatomic, assign, readonly) float version;

- (instancetype)initWithRootObject:(id<NSCoding>)rootObject password:(NSString *)password;
- (id)unarchiveRootObjectWithPassword:(NSString *)password;

@end


@protocol CryptoCoding <NSCoding>

+ (NSString *)CCPassword;

@end


@interface CryptoCoder : NSObject

+ (id)unarchiveObjectWithData:(NSData *)data;
+ (id)unarchiveObjectWithFile:(NSString *)path;
+ (NSData *)archivedDataWithRootObject:(id<CryptoCoding>)rootObject;
+ (BOOL)archiveRootObject:(id<CryptoCoding>)rootObject toFile:(NSString *)path;

+ (void)setClassName:(NSString *)codedName forClass:(Class)cls;
+ (NSString *)classNameForClass:(Class)cls;
+ (void)setClass:(Class)cls forClassName:(NSString *)codedName;
+ (Class)classForClassName:(NSString *)codedName;

@end


#pragma GCC diagnostic pop

