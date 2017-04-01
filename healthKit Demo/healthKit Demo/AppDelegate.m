//
//  AppDelegate.m
//  healthKit Demo
//
//  Created by LDY on 17/3/31.
//  Copyright © 2017年 LDY. All rights reserved.
//

#import "AppDelegate.h"
#import <HealthKit/HealthKit.h>
#import "TabBarController.h"
#import "NavigationViewController.h"
@interface AppDelegate ()

@end

@implementation AppDelegate{
    HKHealthStore *healthStore;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self healthKit];
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
        return YES;
}

void uncaughtExceptionHandler(NSException *exception) {
    
    NSLog(@"reason: %@", exception);
    
    // Internal error reporting
    
}
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"healthKit_Demo"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}
#pragma healthKit
-(void)healthKit{
    healthStore = [[HKHealthStore alloc]init];
    //为每个控制器设置healthStore
    TabBarController *tabBarController = (TabBarController *)self.window.rootViewController;
    for (NavigationViewController *nav in tabBarController.viewControllers) {
        if ([nav respondsToSelector:@selector(setHealthStore:)]) {
            [nav setHealthStore:healthStore];
        }
    }
    //请求[HKHealthStore授权
    if ([HKHealthStore isHealthDataAvailable]) {
        [healthStore requestAuthorizationToShareTypes:[self writeHealthTypes] readTypes:[self readHealthTypes] completion:^(BOOL success, NSError * _Nullable error) {
            if (error) {
                NSLog(@"healthStore error %@",error);
            }else if (success){
                NSLog(@"healthStore success");
            }
        }];
    }
    
}
//要写的属性
-(NSSet *)writeHealthTypes{
    HKQuantityType *heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    HKQuantityType *bodyMassType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    HKQuantityType *bodyTemperatureType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyTemperature];
    return [NSSet setWithArray:@[heightType,bodyMassType,bodyTemperatureType]];
}
//要读的属性
-(NSSet *)readHealthTypes{
//    HKCategoryType
//    HKObjectType
//    HKWorkoutType
//    HKDocumentType
//    HKCorrelationType
//    HKSampleType
    HKCharacteristicType
    
    HKQuantityType *heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    HKQuantityType *bodyMassType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    HKQuantityType *bodyTemperatureType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyTemperature];
    HKCharacteristicType *dateOfBirthType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];
    return [NSSet setWithArray:@[heightType,bodyMassType,bodyTemperatureType,dateOfBirthType]];
}
@end
