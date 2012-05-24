//
//  BaseModel.h
//
//  Version 2.3
//
//  Created by Nick Lockwood on 25/06/2011.
//  Copyright 2011 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from either of these locations:
//
//  http://charcoaldesign.co.uk/source/cocoa#basemodel
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

//
//  ARC Helper
//
//  Version 1.3.1
//
//  Created by Nick Lockwood on 05/01/2012.
//  Copyright 2012 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://gist.github.com/1563325
//

#ifndef AH_RETAIN
#if __has_feature(objc_arc)
#define AH_RETAIN(x) (x)
#define AH_RELEASE(x) (void)(x)
#define AH_AUTORELEASE(x) (x)
#define AH_SUPER_DEALLOC (void)(0)
#define __AH_BRIDGE __bridge
#else
#define __AH_WEAK
#define AH_WEAK assign
#define AH_RETAIN(x) [(x) retain]
#define AH_RELEASE(x) [(x) release]
#define AH_AUTORELEASE(x) [(x) autorelease]
#define AH_SUPER_DEALLOC [super dealloc]
#define __AH_BRIDGE
#endif
#endif

//  ARC Helper ends


#import <Foundation/Foundation.h>


extern NSString *const BaseModelSharedInstanceUpdatedNotification;


//the BaseModel protocol defines optional methods that
//you can define on your BaseModel subclasses to extend their functionality

@protocol BaseModel <NSObject>
@optional

//loading sequence:
//setUp called first
//then setWithDictionary/Array/String if resource file exists
//then setWithCoder if save file exists

- (void)setUp;
- (void)setWithDictionary:(NSDictionary *)dict;
- (void)setWithArray:(NSArray *)array;
- (void)setWithString:(NSString *)string;
- (void)setWithNumber:(NSNumber *)number;
- (void)setWithData:(NSData *)data;
- (void)setWithCoder:(NSCoder *)coder;

//NSCoding

- (void)encodeWithCoder:(NSCoder *)coder;

@end


//use the BaseModel class as the base class for any of your
//model objects. BaseModels can be standalone objects, or
//act as sub-properties of a larger object

@interface BaseModel : NSObject <BaseModel>

//new autoreleased instance
+ (id)instance;

//shared (singelton) instance
+ (id)sharedInstance;
+ (BOOL)hasSharedInstance;
+ (void)setSharedInstance:(BaseModel *)instance;
+ (void)reloadSharedInstance;

//creating instances from collection or string
+ (id)instanceWithObject:(id)object;
- (id)initWithObject:(id)object;
+ (NSArray *)instancesWithArray:(NSArray *)array;

//creating an instance using NSCoding
+ (id)instanceWithCoder:(NSCoder *)decoder;
- (id)initWithCoder:(NSCoder *)decoder;

//loading and saving the model from a plist file
+ (id)instanceWithContentsOfFile:(NSString *)path;
- (id)initWithContentsOfFile:(NSString *)path;
- (void)writeToFile:(NSString *)path atomically:(BOOL)atomically;
- (BOOL)useHRCoderIfAvailable;

//resourceFile is a file, typically within the resource bundle that
//is used to initialise any BaseModel instance
//saveFile is a path, typically within application support that
//is used to save the shared instance of the model
//saveFileForID is a path, typically within application support that
//is used to save any instance of the model
+ (NSString *)resourceFile;
+ (NSString *)saveFile;

//save the model
- (void)save;

//generate unique identifier
//useful for creating universally unique
//identifiers and filenames for model objects
+ (NSString *)newUniqueIdentifier;

#ifdef BASEMODEL_ENABLE_UNIQUE_ID

//optional uniqueID property
//you can enable this by adding BASEMODEL_ENABLE_UNIQUE_ID
//to your preprocessor macros in the project build settings
@property (nonatomic, strong) NSString *uniqueID;

#endif

@end