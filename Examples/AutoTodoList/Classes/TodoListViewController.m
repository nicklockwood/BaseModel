//
//  TodoList1ViewController.m
//  TodoList1
//
//  Created by Nick Lockwood on 08/04/2010.
//  Copyright AKQA 2010. All rights reserved.
//

#import "TodoListViewController.h"
#import "NewItemViewController.h"
#import "TodoItem.h"
#import "TodoList.h"

@implementation TodoListViewController

#pragma mark - UITableViewDataSource methods

-        (NSInteger) tableView:(UITableView*)tV numberOfRowsInSection:(NSInteger)sect		{

	return TRACE_CALL(_cmd, self, @(TodoList.sharedInstance.items.count),nil), TodoList.sharedInstance.items.count;

}
- (UITableViewCell*) tableView:(UITableView*)tV cellForRowAtIndexPath:(NSIndexPath*)iPath	{ 	static NSString *cellType	= @"Cell";

	TRACE_CALL(_cmd, self, @(iPath.row), nil);

	UITableViewCell *cell 	= [tV dequeueReusableCellWithIdentifier:cellType]
								  ?: [UITableViewCell.alloc initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellType];
	
	TodoItem *item 			= TodoList.sharedInstance.items[iPath.row];
	cell.textLabel.text 		= item.label;
	cell.accessoryType 		= item.checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	return cell;
}

#pragma mark - UITableViewDelegate methods

-                        (void) tableView:(UITableView*)tV didSelectRowAtIndexPath:(NSIndexPath*)iPath					{

	TRACE_CALL(_cmd, self, iPath, nil);

	TodoItem *item 	= TodoList.sharedInstance.items[iPath.row];
	item.checked 		= !item.checked;

	[item save];	[tV reloadData];
}
- (UITableViewCellEditingStyle) tableView:(UITableView*)tV editingStyleForRowAtIndexPath:(NSIndexPath*)iPath 			{

	return UITableViewCellEditingStyleDelete;
}
- 								 (void) tableView:(UITableView*)tV commitEditingStyle:(UITableViewCellEditingStyle)editStyle
																				forRowAtIndexPath:(NSIndexPath*)iPath							{

	TRACE_CALL(_cmd, self, nil);

	[TodoList.sharedInstance.items removeObjectAtIndex:iPath.row];
	[TodoList.sharedInstance save];
	[tV reloadData];
}

#pragma mark - Standard view methods

-     (void) viewDidLoad							{	[super viewDidLoad];

	self.navigationItem.leftBarButtonItem 	= self.editButtonItem;
	self.clearsSelectionOnViewWillAppear 	= YES;
}
-     (void) viewWillAppear:(BOOL)animated	{	[super viewWillAppear:YES];	[self.tableView reloadData];	}
- (IBAction) createNewItem							{	[self.navigationController pushViewController:NewItemViewController.new animated:YES];	}


@end
