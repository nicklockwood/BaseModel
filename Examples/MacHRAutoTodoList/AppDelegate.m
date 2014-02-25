
//  AppDelegate.m   MacHRAutoTodoList
//  Created by Alex Gray on 11/26/12.  Copyright (c) 2012 Alex Gray. All rights reserved.

#import "AppDelegate.h"

@implementation      AppDelegate @synthesize todos = _todos;

- (TodoList*) todos               { return _todos = _todos ?: TodoList.sharedInstance; }
-  (IBAction) deleteAll:    (id)s { _todos.items = NSMutableArray.new; }
-  (IBAction) saveTodos:    (id)s { [TodoList.sharedInstance save]; }
-  (IBAction) copyTodo:     (id)s {	_table.selectedRowIndexes.count ? [self.todos copyTodo:self.todos.items[_table.selectedRow]] : nil; }
-  (IBAction) newTodo:      (id)s { [_todos newTodo]; }
-  (IBAction) loadFromPlist:(id)s {

  [self setValue:TodoList.sharedInstance = [TodoList instanceWithContentsOfFile:TodoList.resourceFile]
          forKey:@"todos"];
}
@end


/**  Custom cells, etc...  not directly related to Basemodel, etc... but you can see some ways to access the shared instance, etc */

@interface         TodoColorCell : NSActionCell @end
@interface TodoPriorityClickCell : NSActionCell @end
@implementation      AppDelegate   (General)
- (void) awakeFromNib              {
	((NSTableColumn*)_table.tableColumns[[_table columnWithIdentifier:   @"Status"]]).dataCell = TodoColorCell.new;
	((NSTableColumn*)_table.tableColumns[[_table columnWithIdentifier: @"Priority"]]).dataCell = TodoPriorityClickCell.new;
}        @end

@implementation TodoPriorityClickCell
-   (id) target       { return self; }
-  (SEL) action       { return @selector(tickPriority); }
- (void) tickPriority {

	NSUInteger val = [self.objectValue unsignedIntegerValue];
	((TodoItem*)TodoList.sharedInstance.items[((NSTableView*)self.controlView).selectedRow]).priority = @(val < 8 ? val + 1 : 0 );
}
- (void) drawWithFrame:(NSRect)cellF inView:(NSView*)v {

	[NSColor.darkGrayColor set];
	NSRectFill(cellF);
	NSString    * str = ((NSNumber*)self.objectValue).stringValue;
	NSDictionary *att = @{ NSFontAttributeName : [NSFont fontWithName:@"Lucida Grande Bold" size: cellF.size.height - 10], NSForegroundColorAttributeName : NSColor.whiteColor};
	NSSize      strSz = [str sizeWithAttributes:att];
 	[str drawInRect:(NSRect){NSMidX(cellF) - strSz.width/2, cellF.origin.y + 3, strSz.width, strSz.height} withAttributes:att];
}
@end
@implementation TodoColorCell
- (void) drawWithFrame:(NSRect)cellF inView:(NSView*)v {	[(NSColor*)self.objectValue set];	NSRectFill(cellF); }
@end
