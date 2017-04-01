//
//  HKHealthStore+AAPLExtensions.h
//  prj1115
//
//  Created by ZFJ_APPLE on 15/11/27.
//  Copyright © 2015年 JiRanAsset. All rights reserved.
//

#import <HealthKit/HealthKit.h>

@interface HKHealthStore (AAPLExtensions)

// Fetches the most recent quantity of the specified type.
- (void)aapl_mostRecentQuantitySampleOfType:(HKQuantityType *)quantityType predicate:(NSPredicate *)predicate completion:(void (^)(NSArray *results, NSError *error))completion;

// Fetches the single most recent quantity of the specified type.
- (void)james_mostRecentQuantitySampleOfType:(HKQuantityType *)quantityType predicate:(NSPredicate *)predicate completion:(void (^)(HKQuantity *mostRecentQuantity, NSError *error))completion;//--->装b失败
@end
