//
//  ViewController.m
//  Lesson4
//
//  Created by Azat Almeev on 11.10.15.
//  Copyright © 2015 Azat Almeev. All rights reserved.
//

#import "ViewController.h"
#import "StubClass.h"

@interface ViewController ()
@property (nonatomic, strong) StubClass *myStub;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.myStub = [NSClassFromString(@"StubClass") new];
    self.myStub.n = @2;
    NSLog(@"%@, %@", self.myStub, self.myStub.n);
}

@end
