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

+ (NSString *)resourceFile
{
    //name of the default list in the application bundle
	return @"TodoList.plist";
}

+ (NSString *)documentFile
{
    //name of the save file in the documents folder
	return @"TodoList.plist";
}

//override the generic sharedInstance
//with a concrete type, this makes it
//easier to use without casting
+ (TodoList *)sharedInstance
{
	return [super sharedInstance];
}

- (id)init
{
	if ((self = [super init]))
	{
		items = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithArray:(NSArray *)array
{
	if ((self = [self init]))
	{
		for (NSString *label in array)
		{
			[items addObject:[TodoItem instanceWithLabel:label]];
		}
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [self init]))
	{
		[items setArray:[aDecoder decodeObjectForKey:@"items"]];
	}
	return self;
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
