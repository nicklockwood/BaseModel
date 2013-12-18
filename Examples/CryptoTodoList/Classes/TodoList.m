//
//  TodoList.m
//  TodoListExample
//
//  Created by Nick Lockwood on 28/07/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "TodoList.h"
#import "TodoItem.h"


@implementation TodoList

@synthesize items;

//all we have to do to add automatic encryption
//support is to add the CryptoCoding class files and
//Security framework to the project, set the saveFormat
//to BMFileFormatCryptoCoding, and then use the
//+CCPassword method to specify a password for our model

+ (BMFileFormat)saveFormat
{
    return BMFileFormatCryptoCoding;
}

+ (NSString *)CCPassword
{
    return @"YsMXOHm2vsoIxTdSZWMILEVnQtgupefHGSROCLmwTnX3wBaCac";
}

- (void)setUp
{
    self.items = [NSMutableArray array];
}

- (void)setWithArray:(NSArray *)array
{
	//initialise with default list from plist
	[items setArray:[TodoItem instancesWithArray:array]];
}

//NOTE: no need to implement the NSCoding methods
//BaseModel does that for us automagically

@end
