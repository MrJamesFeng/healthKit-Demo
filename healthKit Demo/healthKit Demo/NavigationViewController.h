//
//  NavigationViewController.h
//  healthKit Demo
//
//  Created by LDY on 17/3/31.
//  Copyright © 2017年 LDY. All rights reserved.
//

#import <UIKit/UIKit.h>
@import HealthKit;
@interface NavigationViewController : UINavigationController
@property(nonatomic,strong)HKHealthStore *healthStore;
@end
