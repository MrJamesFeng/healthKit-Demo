//
//  HKHealthStore+AAPLExtensions.m
//  prj1115
//
//  Created by ZFJ_APPLE on 15/11/27.
//  Copyright © 2015年 JiRanAsset. All rights reserved.
//

#import "HKHealthStore+AAPLExtensions.h"

@implementation HKHealthStore (AAPLExtensions)

- (void)aapl_mostRecentQuantitySampleOfType:(HKQuantityType *)quantityType predicate:(NSPredicate *)predicate completion:(void (^)(NSArray *, NSError *))completion {
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    
    // Since we are interested in retrieving the user's latest sample, we sort the samples in descending order, and set the limit to 1. We are not filtering the data, and so the predicate is set to nil.
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:quantityType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:@[timeSortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        if (completion) {
            // If quantity isn't in the database, return nil in the completion block.
            //NSLog(@"results ---- > = %@",results);
            for (HKQuantitySample *model in results) {
                NSLog(@"quantity  ==  %@",model.quantity);
                NSLog(@"source  ==  %@",model.source);
                NSLog(@"sourceRevision  ==  %@",model.sourceRevision);
                NSLog(@"startDate  ==  %@",model.startDate);
                NSLog(@"endDate  ==  %@",model.endDate);
                NSLog(@"metadata  ==  %@",model.metadata);
                
                NSDictionary *dict = (NSDictionary *)model.metadata;
                NSLog(@"HKWasUserEntered  ==  %@",dict[@"HKWasUserEntered"]);
                
            }
            completion(results, error);
        }
    }];
    
    [self executeQuery:query];
}

- (void)james_mostRecentQuantitySampleOfType:(HKQuantityType *)quantityType predicate:(NSPredicate *)predicate completion:(void (^)(HKQuantity *mostRecentQuantity, NSError *error))completion{
    //排序规则
     NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
//    HKSourceQuery
//    HKObserverQuery
//    HKDocumentQuery
//    HKStatisticsQuery
//    HKCorrelationQuery
//    HKAnchoredObjectQuery
//    HKActivitySummaryQuery
//
//     HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:<#(nonnull HKSampleType *)#> predicate:<#(nullable NSPredicate *)#> limit:<#(NSUInteger)#> sortDescriptors:<#(nullable NSArray<NSSortDescriptor *> *)#> resultsHandler:<#^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error)resultsHandler#>
}

@end
