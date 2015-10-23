//
//  ViewController.m
//  Lesson4
//
//  Created by Azat Almeev on 11.10.15.
//  Copyright © 2015 Azat Almeev. All rights reserved.
//

#import "ViewController.h"
#import "StubClass.h"
#import "ClassResolver.h"

@interface ViewController ()
@property (nonatomic, strong) StubClass *myStub;
@property (nonatomic, strong) ClassResolver *classResolver;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.myStub = [NSClassFromString(@"StubClass") new];
    
//    [NSClassFromString(@"StubClass") classMethod];
//    id result = [NSClassFromString(@"StubClass") classMethodReturn];
    id result = [NSClassFromString(@"StubClass") classMethodReturnWithParam:@2];
    NSLog(@"%@", result);
//    self.myStub.n = @2;
//    NSLog(@"%@, %@", self.myStub, self.myStub.n);
//    self.myStub.n = @5;
//    NSLog(@"%@", self.myStub.n);
//    [self.myStub sayHello];
////    id result = [self.myStub sayHelloToCaller:@"sd"];
//    id result = [self.myStub sayHelloToCaller:@"sdf" withParam:@2];
//    NSLog(@"%@", result);
    
}

@end
