//
//  LogView.h
//  MapAttack
//
//  Created by wenchao jiang on 05/02/2012.
//  Copyright (c) 2012 university of nottingham. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LogView : UIViewController{
 
    IBOutlet UITextView *logText;

}



@property (nonatomic, retain) IBOutlet UITextView *logText;

-(IBAction)back:(id)sender;
@end
