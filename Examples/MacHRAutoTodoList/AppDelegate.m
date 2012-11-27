//
//  AppDelegate.m
//  MacHRAutoTodoList
//
//  Created by Alex Gray on 11/26/12.
//  Copyright (c) 2012 Alex Gray. All rights reserved.
//

#import "AppDelegate.h"





@implementation TodoPriorityClickCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[[NSColor blackColor]set];	NSRectFill(cellFrame);
	NSString* string = ((NSNumber*)self.objectValue).stringValue;
	NSDictionary *attrs =	@{	NSFontAttributeName            : [NSFont userFontOfSize:cellFrame.size.height - 4],
//								NSStrokeWidthAttributeName 	   : @3.0,
								NSForegroundColorAttributeName : [NSColor whiteColor],
								NSKernAttributeName        	   : @0,
								NSObliquenessAttributeName 	   : @0.1 };
				NSSize stringSize = [string sizeWithAttributes:attrs];
 	[string drawInRect:NSMakeRect( NSMidX(cellFrame) - stringSize.width / 2, 0, stringSize.width, stringSize.height) withAttributes:attrs];
}
- (id) target 	{ return self; 					  }

- (SEL) action	{ return @selector(tickPriority); }

- (void) tickPriority
{
	NSLog(@"rep:%@  objectV:%@", [self controlView], self.objectValue);
	NSUInteger val = [[self objectValue]unsignedIntegerValue];
	NSUInteger u = [(NSTableView*)[self controlView]selectedRow];
	((TodoItem*)[[TodoList sharedInstance] items][u]).priority = @( val < 8 ? val + 1 : 0 ); //NSLog(@"newp:%@", newP); [[self representedObject]setValue:newP];
}

@end

@implementation TodoColorCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[(NSColor*)self.objectValue set];	NSRectFill(cellFrame);
}

@end

@implementation AppDelegate

- (IBAction)deleteAll:(id)sender
{
	self.todos.items = [NSMutableArray array];
}
- (IBAction)saveTodos:(id)sender	{  [[TodoList sharedInstance]save]; }

- (TodoList*)todos	{    return _todos = _todos ?: [TodoList sharedInstance];	}

- (IBAction)loadFromPlist:(id)sender
{
	self.todos = [TodoList instanceWithContentsOfFile:[TodoList resourceFile]];
	[TodoList setSharedInstance:_todos];
}
- (IBAction)copyTodo:(id)sender
{
	TodoItem *td = self.todos.items[[_table selectedRow]];
	NSLog(@"td: %@", td);
	[self.todos copyTodo:td];
}
- (IBAction)newTodo:(id)sender
{
	[TodoList.sharedInstance updateKey:@"items" inBlock:^{

		[[TodoList sharedInstance].items addObject: [TodoItem instanceWithObject:
				@{ @"label" 	 : [[NSDate date] descriptionWithCalendarFormat:@"%A" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]],
				   @"priority" : @2}]];
	}];
}

-(void)awakeFromNib
{
//	[TodoList setSharedInstance:[TodoList instance]];
//	[NOTIFICATIONC addObserver:self selector:@selector(setUpObservers) name:BaseModelSharedInstanceUpdatedNotification object:nil];
	((NSTableColumn*)[_table tableColumns][[_table columnWithIdentifier:@"Status"]]).dataCell = [TodoColorCell new];
	((NSTableColumn*)[_table tableColumns][[_table columnWithIdentifier:@"Priority"]]).dataCell = [TodoPriorityClickCell new];

}
- (void) setUpObservers
{
	NSLog(@"setting observers.  sharedI: %@", [TodoList sharedInstance]);
	/* AUTOSAVING */
//	[@[NSApplicationDidBecomeActiveNotification, NSApplicationDidResignActiveNotification, NSApplicationWillTerminateNotification ] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//		[NOTIFICATIONC addObserver:[TodoList sharedInstance] selector:@selector(save) name:obj object:nil];
//	}];
//	[_table reloadData];
}

@end



/*	Convenience category to trigger updates on ArrayController when calling 
	"addObject:" on bound mutable array.  satisfies header in .pch	 */
	
@implementation NSObject (KVONotifyBlock)
- (void)updateKey:(NSString*)key inBlock:(updateKVCKeyBlock)block	{	[self willChangeValueForKey:key];	block();	[self didChangeValueForKey:key];	}
@end
