//
//  TodoItem.m
//  TodoList
//
//  Created by Nick Lockwood on 28/07/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "Todos.h"

@interface TodoItem ()
@property (readwrite) NSDate *created;
@end

@implementation TodoItem

- (void) setUp
{
	_checked 	= NO;
	_created 	= [NSDate date];
	_label  	= [NSString stringWithFormat:@"New todo, created:%@", [_created descriptionWithLocale:nil]];
	_priority  	= @1;

}

+ (instancetype)instanceWithLabel:(NSString *)label
{
	TodoItem *instance = [self instance];
    instance.label = label;
    return instance;
}

+ (instancetype)instanceWithObject:(id)object
{
	TodoItem *instance = [self instance];
	for (NSString *key in [object allKeys])
		if ([instance respondsToSelector:NSSelectorFromString([NSString stringWithFormat:@"set%@", [key uppercaseString]])])
			[instance setValue:((NSDictionary*)object)[key] forKey:key];
	return instance;
}

- (NSColor*) color
{
	return 	self.checked				? [NSColor colorWithPatternImage:[NSImage imageNamed:@"thatch"]] 				:
			self.priority.intValue == 1 ? [NSColor colorWithCalibratedRed:0.843 green:0.000 blue:0.119 alpha:1.000] :
			self.priority.intValue == 2 ? [NSColor colorWithCalibratedRed:1.000 green:0.861 blue:0.225 alpha:1.000] :
			self.priority.intValue == 3 ? [NSColor colorWithCalibratedRed:0.986 green:0.484 blue:0.032 alpha:1.000] :
			self.priority.intValue == 4 ? [NSColor colorWithCalibratedRed:0.739 green:0.900 blue:0.000 alpha:1.000] :
			self.priority.intValue == 5 ? [NSColor colorWithCalibratedRed:0.369 green:0.630 blue:0.589 alpha:1.000] :
			self.priority.intValue == 6 ? [NSColor colorWithCalibratedRed:0.253 green:0.478 blue:0.761 alpha:1.000] :
			self.priority.intValue == 7 ? [NSColor colorWithCalibratedRed:0.630 green:0.336 blue:0.576 alpha:1.000] :
										  [NSColor colorWithCalibratedRed:0.883 green:0.254 blue:0.700 alpha:1.000];
}


+ (NSSet*) keyPathsForValuesAffectingColor { return [NSSet setWithArray:@[@"checked", @"priority"]]; }


/* note: we've not implemented the NSCoding methods or initWithString/Dictionary, etc
	because the HRCoder and AutoCoding libraries take care of this for us */


@end
