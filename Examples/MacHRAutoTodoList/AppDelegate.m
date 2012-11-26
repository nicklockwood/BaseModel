//
//  AppDelegate.m
//  MacHRAutoTodoList
//
//  Created by Alex Gray on 11/26/12.
//  Copyright (c) 2012 Alex Gray. All rights reserved.
//

#import "AppDelegate.h"




@implementation NSObject (KVONotifyBlock)
- (void)updateKey:(NSString*)key inBlock:(updateKVCKeyBlock)block
{
	[self willChangeValueForKey:key];
	block();
	[self didChangeValueForKey:key];
}
@end


@implementation TodoColorCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSLog(@"reped: %@", [self objectValue]);// class]);// [self representedObject]);
	[(NSColor*)[self objectValue] set];
	NSRectFill(cellFrame);
}

@end


@implementation AppDelegate


-(TodoList*)todos { return 	[TodoList sharedInstance]; }

- (IBAction)newTodo:(id)sender
{
	[self.todos updateKey:@"items" inBlock:^{

		[self.todos.items addObject: [TodoItem instanceWithObject:
				@{ @"label" 	 : [[NSDate date] descriptionWithCalendarFormat:@"%A" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]],
				   @"priority" : @2}]];
	}];
}

- (void) applicationDidResignActive:(NSNotification *)notification {	[self.todos save]; }


-(void)awakeFromNib {

	NSTableColumn * colorColumn = [_table tableColumns][[_table columnWithIdentifier:@"Priority"]];
	TodoColorCell * colorCell 	= [TodoColorCell new];
	[colorColumn setDataCell:colorCell];


//	NSTableColumn *tableColumn = [[myTableView tableColumns] objectAtIndex:0];
//	customTextFieldCell *customHighlights = [[[customTextFieldCell alloc] init] autorelease];
//	[tableColumn setDataCell:customHighlights];
//	NSSize mySize;
//	mySize.width = mySize.height = 0;
//	[myTableView setIntercellSpacing:mySize];
//
//	list = [[NSArray alloc] initWithObjects:[NSString stringWithString:@"One"], [NSString stringWithString:@"Two"], [NSString stringWithString:@"Three"], nil];
}

#pragma mark - Tableview Datasource

//- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
//{
//	NSUInteger ct =  [TodoList sharedInstance].items.count;
//	NSLog(@"TodoList Reports: %ld item(s)", ct);
//	return ct;
//}
//

//- (NSImage*) iconForCell: (ImageTextCell*) cell data: (NSObject*) data;
//{
//
//}
//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
//{
//	NSString *label = tableColumn.identifier;
//	NSLog(@"requesting %@", tableColumn);
//	TodoItem *todo  = TodoList.sharedInstance.items[rowIndex];
//	return  [label isEqualToString:@"Todo"]		 ? todo.label :
//			[label isEqualToString:@"Priority"]  ? ^{
//				TodoColorCell *c = [[TodoColorCell alloc]init];
//				c.objectValue = todo.color.copy;
//				return  c;
//			}() 								 : nil;
//}
//

@end
@implementation CheckedValueTransformer

+ (Class) transformedValueClass 	 { 	return [NSString class]; 	}

+ (BOOL) allowsReverseTransformation { 	return YES; 					}

- (id) transformedValue: (id)value 	 {	return [value boolValue] ? [NSImage imageNamed:NSImageNameStopProgressTemplate]
																 : [NSImage imageNamed:NSImageNameRefreshFreestandingTemplate];
}

@end



//- (void) setObjectValue:(id<NSCopying>)obj
//{
//	NSLog(@"rep: %@", obj);
//	self.todo = (TodoItem*)obj;
//	[super setObjectValue:obj];
//}

//	NSImage* image = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:homepage.image]] autorelease];
//	TodoItem *td = [(NSArrayController*)self.representedObject selectedObjects][0];
//	[controlView lockFocus];
//	NSPoint p1 = cellFrame.origin;
//	p1.x += 5;
//	p1.y += 5 + [image size].height;
//	[image compositeToPoint:p1 operation:NSCompositeSourceOver];
//
//	NSPoint p2 = cellFrame.origin;
//	p2.x += 100;
//	p2.y += 20;
//	NSDictionary* attrs = [NSDictionary dictionary];
//	[homepage.title drawAtPoint:p2 withAttributes:attrs];
//	[controlView unlockFocus];


//- (id)copyWithZone:(NSZone *)zone
//{
//	NSLog(@"self=%@, copyWithZone:%@", self, zone);
//	TodoColorCell* cell = (TodoColorCell*)[super copyWithZone:zone];
//	return cell;
//}
////
//- (void)setObjectValue:(id < NSCopying >)object
//{
//	NSLog(@"setObjectValue: %@", object);
//	[super setObjectValue:object];
//}

