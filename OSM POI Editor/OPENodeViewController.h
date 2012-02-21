//
//  OPENodeViewController.h
//  OSM POI Editor
//
//  Created by David Chiles on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OPENode.h"
#import "OPETagInterpreter.h"
#import "OPETextEdit.h"
#import "OPETypeViewController.h"

@interface OPENodeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, PassText, PassCategoryAndType>
{
    UITableView *tableView;
    OPETagInterpreter * tagInterpreter;
    NSDictionary * osmKeyValue;
}

@property (nonatomic, strong) OPENode * node;
@property (nonatomic, strong) OPENode * theNewNode;
@property (nonatomic, strong) IBOutlet UITableView* tableView;
@property (nonatomic, strong) NSArray * catAndType;
@property (nonatomic, strong) NSString * type;
@property (nonatomic, strong) IBOutlet UIButton * deleteButton;

- (void) saveButtonPressed;
- (void) deleteButtonPressed;



@end
