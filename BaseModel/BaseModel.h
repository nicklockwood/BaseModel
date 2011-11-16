//
//  BaseModel.h
//
//  Version 2.0
//
//  Created by Nick Lockwood on 25/06/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//
//  Get the latest version of BaseModel from either of these locations:
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

#import <Foundation/Foundation.h>


extern NSString *const BaseModelSharedInstanceUpdatedNotification;


//BaseModel extends NSObject with the following methods

@interface NSObject (BaseModel)

//loading

+ (id)objectWithContentsOfFile:(NSString *)path;
- (void)writeToFile:(NSString *)filePath atomically:(BOOL)useAuxiliaryFile;

@end


//the BaseModel protocol defines optional methods that
//you can define on your BaseModel subclasses to extend their functionality

@protocol BaseModel <NSObject>
@optional

//loading sequence:
//setUp called first
//then setWithDictionary/Array if resource file exists
//then setWithCoder if save file exists

- (void)setUp;
- (void)setWithDictionary:(NSDictionary *)dict;
- (void)setWithArray:(NSArray *)array;
- (void)setWithCoder:(NSCoder *)aDecoder;

@end


//use the BaseModel class as the base class for any of your
//model objects. BaseModels can be standalone objects, or
//act as sub-properties of a larger object

@interface BaseModel : NSObject <NSCoding, BaseModel>

//instance properties

@property (nonatomic, copy) NSString *uniqueID;

//new autoreleased instance
+ (id)instance;

//shared (singelton) instance
+ (id)sharedInstance;
+ (BOOL)hasSharedInstance;
+ (void)setSharedInstance:(BaseModel *)instance;
+ (void)reloadSharedInstance;

//file management utility functions
+ (id)instanceWithDictionary:(NSDictionary *)dict;
- (id)initWithDictionary:(NSDictionary *)dict;
+ (id)instanceWithArray:(NSArray *)array;
- (id)initWithArray:(NSArray *)array;

//loading and saving the model from a plist file
+ (id)instanceWithContentsOfFile:(NSString *)path;
- (id)initWithContentsOfFile:(NSString *)path;

//resourceFile is a file, typically within the resource bundle that
//is used to initialise any BaseModel instance
//savefile is a path, typically within application support that
//is used to save the shared instance of the model
+ (NSString *)resourceFile;
+ (NSString *)saveFile;

//save the model
- (void)save;

@end