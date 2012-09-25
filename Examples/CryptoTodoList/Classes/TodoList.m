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
//Security framework to the project, and then include
//the +CCPassword method in our model 

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

- (void)setWithCoder:(NSCoder *)aDecoder
{
	//replace default list with version from saved file
	[items setArray:[aDecoder decodeObjectForKey:@"items"]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:items forKey:@"items"];
}

- (void)dealloc
{
	[items release];
	[super dealloc];
}

@end
