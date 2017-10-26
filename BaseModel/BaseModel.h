//
//  BaseModel.h
//
//  Version 2.6.4
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


#import <Foundation/Foundation.h>


extern NSString *const BaseModelSharedInstanceUpdatedNotification;
extern NSString *const BaseModelException;


typedef NS_ENUM(NSUInteger, BMFileFormat)
{
    BMFileFormatKeyedArchive = 0, //default
    BMFileFormatXMLPropertyList,
    BMFileFormatBinaryPropertyList,
    BMFileFormatJSON,
    BMFileFormatUserDefaults,
    BMFileFormatKeychain, //requires FXKeychain library
    BMFileFormatCryptoCoding, //requires CryptoCoding library
    BMFileFormatHRCodedXML, //requires HRCoder library
    BMFileFormatHRCodedJSON, //requires HRCoder library
    BMFileFormatHRCodedBinary, //requires HRCoder library
    BMFileFormatFastCoding, //requires FastCoding library
};


//use the BaseModel class as the base class for any of your
//model objects. BaseModels can be standalone objects, or
//act as sub-properties of a larger object

@interface BaseModel : NSObject <NSCoding>

//loading sequence:
//setUp called first
//then setWithDictionary/Coder/etc if resource file exists
//then setWithDictionary/Coder/etc again if save file exists
//tearDown is called prior to dealloc (but only if setUp was called)

- (void)setUp;
- (void)setWithDictionary:(NSDictionary *)dict;
- (void)setWithCoder:(NSCoder *)decoder;
- (void)tearDown;

//new autoreleased instance
+ (instancetype)instance;

//shared (singelton) instance
+ (instancetype)sharedInstance;
+ (BOOL)hasSharedInstance;
+ (void)setSharedInstance:(BaseModel *)instance;
+ (void)reloadSharedInstance;

//creating instances from a configuration object
+ (instancetype)instanceWithObject:(id)object;
- (instancetype)initWithObject:(id)object;
+ (NSArray *)instancesWithArray:(NSArray *)array;

//creating an instance using NSCoding
+ (instancetype)instanceWithCoder:(NSCoder *)decoder;
- (instancetype)initWithCoder:(NSCoder *)decoder;

//loading and saving the model from a data file
+ (instancetype)instanceWithContentsOfFile:(NSString *)path;
- (instancetype)initWithContentsOfFile:(NSString *)path;
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomically;
- (BOOL)writeToFile:(NSString *)path format:(BMFileFormat)format atomically:(BOOL)atomically;

//get model properties
+ (NSArray *)allPropertyKeys;
+ (NSArray *)codablePropertyKeys;
- (NSDictionary *)dictionaryRepresentation;

//resourceFile is a file, typically within the resource bundle that
//is used to initialise any BaseModel instance
//saveFile is a path, typically within application support that
//is used to save the shared instance of the model
//saveFormat is the preferred format to use when saving the file
+ (NSString *)resourceFile;
+ (NSString *)saveFile;
+ (BMFileFormat)saveFormat;

//save the model
- (BOOL)save;

//generate unique identifier
//useful for creating universally unique
//identifiers and filenames for model objects
+ (NSString *)newUniqueIdentifier;

@end
