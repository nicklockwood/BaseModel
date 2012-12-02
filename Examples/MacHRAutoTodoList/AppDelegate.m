//
//  AppDelegate.m
//  MacHRAutoTodoList
//
//  Created by Alex Gray on 11/26/12.
//  Copyright (c) 2012 Alex Gray. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate

- (TodoList*) todos				  { return _todos = _todos ?: TodoList.sharedInstance; }

- (IBAction) deleteAll: 	(id)s { self.todos.items = [NSMutableArray new];			 }

- (IBAction) saveTodos: 	(id)s { [TodoList.sharedInstance save]; 					 }

- (IBAction) copyTodo:  	(id)s {	_table.selectedRowIndexes.count != 0 ? [self.todos copyTodo:self.todos.items[_table.selectedRow]] : nil; }

- (IBAction) newTodo:   	(id)s { [self.todos newTodo]; }

- (IBAction) loadFromPlist:	(id)s
{
	self.todos = [TodoList instanceWithContentsOfFile:TodoList.resourceFile];
	TodoList.sharedInstance = _todos;
}

-(void)awakeFromNib
{
	((NSTableColumn*)_table.tableColumns[[_table columnWithIdentifier:   @"Status"]]).dataCell = [TodoColorCell new];
	((NSTableColumn*)_table.tableColumns[[_table columnWithIdentifier: @"Priority"]]).dataCell = [TodoPriorityClickCell new];
}

@end

/**  Custom cells...  not directly related to Basemodel, etc... but you can see some ways to access the shared instance, etc */

@implementation TodoPriorityClickCell

- (id) target 	{ return self; 					  }

- (SEL) action	{ return @selector(tickPriority); }

- (void) tickPriority
{
	NSUInteger val = [[self objectValue]unsignedIntegerValue];
	((TodoItem*)[TodoList sharedInstance].items[[(NSTableView*)[self controlView]selectedRow]]).priority = @( val < 8 ? val + 1 : 0 );
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[[NSColor darkGrayColor]set]; NSRectFill(cellFrame);
	NSString	*string = ((NSNumber*)self.objectValue).stringValue;
	NSDictionary *attrs = @{ NSFontAttributeName : [NSFont fontWithName:@"Lucida Grande Bold" size: cellFrame.size.height - 10], NSForegroundColorAttributeName : [NSColor whiteColor] };
	NSSize stringSize 	= [string sizeWithAttributes:attrs];
 	[string drawInRect: (NSRect) { NSMidX(cellFrame) - stringSize.width / 2, cellFrame.origin.y + 3, stringSize.width, stringSize.height } withAttributes:attrs];
}

@end

@implementation TodoColorCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {	[(NSColor*)self.objectValue set];	NSRectFill(cellFrame); }

@end

