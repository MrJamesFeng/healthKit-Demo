//
//  NavigationViewController.m
//  healthKit Demo
//
//  Created by LDY on 17/3/31.
//  Copyright © 2017年 LDY. All rights reserved.
//

#import "NavigationViewController.h"
#import "HKHealthStore+AAPLExtensions.h"
#ifdef DEBUG
#define NSLog(format, ...) printf("[%s] %s [第%d行] %s\n", __TIME__, __FUNCTION__, __LINE__, [[NSString stringWithFormat:format, ## __VA_ARGS__] UTF8String]);
#else
#define NSLog(format, ...)
#endif
@interface NavigationViewController ()

@end

@implementation NavigationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self birthdayOfHealthstore];
    //查询更新体重
//      [self updateWeight];
    //查询更新体温
    [self updateTemperature];
}

//更新体重
-(void)updateWeight{
    //查询旧数据
    HKQuantityType *bodyMassType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    [self.healthStore aapl_mostRecentQuantitySampleOfType:bodyMassType predicate:nil completion:^(NSArray *results, NSError *error) {
        if (error) {
            NSLog(@"aapl_mostRecentQuantitySampleOfType error:%@",error);
        }else{
//            NSLog(@"aapl_mostRecentQuantitySampleOfType results:%@",results);
            
//                NSLog(@"startDate=%@ endDate=%@",sample.startDate,sample.endDate);
                for (HKQuantitySample *model in results) {//体温数据保存在HKQuantitySample model.quantity中
//                    NSLog(@"quantitySample=%@",model);
//                    //                quantitySample=-235.65 degC 836B4255-607B-4B9C-8F90-13E0D29F8E3D "healthKit Demo" (1)  (2017-04-01 14:58:49 +0800 - 2017-04-01 14:58:49 +0800)
//                    NSLog(@"quantity  ==  %@",model.quantity);
//                    //                NSLog(@"source  ==  %@",model.source);
//                    NSLog(@"sourceRevision  ==  %@",model.sourceRevision);
//                    NSLog(@"startDate  ==  %@",model.startDate);
//                    NSLog(@"endDate  ==  %@",model.endDate);
//                    NSLog(@"metadata  ==  %@",model.metadata);
//                    
//                    NSDictionary *dict = (NSDictionary *)model.metadata;
//                    NSLog(@"HKWasUserEntered  ==  %@",dict[@"HKWasUserEntered"]);
                    //统计最近一周最高、最低、平均体温
                    
                    
        }
            
        }
        
    }];
    //储存新数据
    double weight = 57.0;
    HKUnit *poundUnit = [HKUnit poundUnit];
    HKQuantity *weightQuanity = [HKQuantity quantityWithUnit:poundUnit doubleValue:weight];
    HKQuantityType *weightQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    NSDate *timeStamp = [NSDate date];
    HKQuantitySample *weightQuantitySample = [HKQuantitySample quantitySampleWithType:weightQuantityType quantity:weightQuanity startDate:timeStamp endDate:timeStamp];
    [self.healthStore saveObject:weightQuantitySample withCompletion:^(BOOL success, NSError * _Nullable error) {
        if (error) {
            NSLog(@"healthStore saveObject error: %@",[error description]);
        }else{
             NSLog(@"healthStore saveObject sucessed !");
        }
    }];
    
}
//更新体温
-(void)updateTemperature{
    //HKQunityType
    HKQuantityType *temperatureQuantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyTemperature];
    
    //查询体温数据
    [self.healthStore aapl_mostRecentQuantitySampleOfType:temperatureQuantityType predicate:nil completion:^(NSArray *results, NSError *error) {
        if (error) {
            NSLog(@"healthStore save temperature error:%@",[error description]);
        }else{
//            NSLog(@"healthStore aapl_mostRecent temperature results:%@",results);
            HKUnit *kelvinUnit = [HKUnit kelvinUnit];
            double highmax = 0.0,lowmin = 0.0,average = 0.0,kelvinQuntity = 0.0,sumKelvinQuntity = 0.0;
            int num = 0;
            for (HKQuantitySample *model in results) {//体温数据保存在HKQuantitySample model.quantity中
//                NSLog(@"quantitySample=%@",model);
////                quantitySample=-235.65 degC 836B4255-607B-4B9C-8F90-13E0D29F8E3D "healthKit Demo" (1)  (2017-04-01 14:58:49 +0800 - 2017-04-01 14:58:49 +0800)
//                NSLog(@"quantity  ==  %@",model.quantity);
////                NSLog(@"source  ==  %@",model.source);
//                NSLog(@"sourceRevision  ==  %@",model.sourceRevision);
//                NSLog(@"startDate  ==  %@",model.startDate);
//                NSLog(@"endDate  ==  %@",model.endDate);
//                NSLog(@"metadata  ==  %@",model.metadata);
//                
//                NSDictionary *dict = (NSDictionary *)model.metadata;
//                NSLog(@"HKWasUserEntered  ==  %@",dict[@"HKWasUserEntered"]);
                if ([[model startDate] timeIntervalSinceNow]<604800.0) {
                    kelvinQuntity = [[model quantity] doubleValueForUnit:kelvinUnit];
                    highmax = kelvinQuntity > highmax?[[model quantity] doubleValueForUnit:kelvinUnit]:highmax;
                    lowmin = kelvinQuntity < lowmin?[[model quantity] doubleValueForUnit:kelvinUnit]:lowmin;
                    sumKelvinQuntity += kelvinQuntity;
                    num ++;
                }
                
            }
            if (num>0) {
                average = sumKelvinQuntity/num;
                NSLog(@"highmax=%f lowmin=%f average=%f",highmax,lowmin,average);
            }
            
            /*
            for (HKCategoryType *categoryType in results) {//也可以用HKCategoryType遍历获取结果
                NSLog(@"categoryType＝%@",categoryType);
//                categoryType＝-235.65 degC DDA45F88-C4A9-495E-8E15-D74ADA4CC23F "healthKit Demo" (1)  (2017-04-01 11:47:55 +0800 - 2017-04-01 11:47:55 +0800)
            }
             */
//            for (HKSample *sample in results) {//不能用HKSample遍历要用它的子类HKQuantitySample
////                NSLog(@"startDate=%@ endDate=%@",sample.startDate,sample.endDate);
//                NSLog(@"UUID=%@ sourceRevision=%@ device=%@ metadata=%@ identifier=%@ -->%@",sample.UUID,sample.sourceRevision,sample.device,sample.metadata,sample.sampleType.identifier,[sample valueForKey:HKQuantityTypeIdentifierBasalBodyTemperature])
////                [sample valueForKey:@"HKQuantityTypeIdentifierBodyTemperature"];
//            }
        }
    }];
    
    double tempeature = 37.5;
    NSDate *timeStamp = [NSDate date];
    //单位
    HKUnit *temperatureUnit = [HKUnit kelvinUnit];
    //HKQunity实例
    HKQuantity *temperatureQuantity = [HKQuantity quantityWithUnit:temperatureUnit doubleValue:tempeature];
    //HKQunitySample
    HKQuantitySample *temperatureQuantitySample = [HKQuantitySample quantitySampleWithType:temperatureQuantityType quantity:temperatureQuantity startDate:timeStamp endDate:timeStamp];
    //保存数据
    [self.healthStore saveObject:temperatureQuantitySample withCompletion:^(BOOL success, NSError * _Nullable error) {
        if (error) {
            NSLog(@"healthStore save temperature error:%@",[error description]);
        }else{
            NSLog(@"healthStore save temperature sucess !");
        }
    }];
    
    
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(NSDateComponents *)birthdayOfHealthstore{
   
    NSError *error = nil;
    NSDateComponents *birthdayDateComponents = [self.healthStore dateOfBirthComponentsWithError:&error];
    if (error) {
        NSLog(@"birthday error:%@",[error description]);
    }else{
        NSLog(@"%ld-%ld-%ld",(long)birthdayDateComponents.year,birthdayDateComponents.month,birthdayDateComponents.day);
    }
    return birthdayDateComponents;
}
//-(void)setHealthStore:(HKHealthStore *)healthStore{
//    
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
