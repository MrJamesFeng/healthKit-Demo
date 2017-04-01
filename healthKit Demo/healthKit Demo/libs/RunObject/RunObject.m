/*
//  RunObject.m
//  prj1115
//
//  Created by ZFJ_APPLE on 15/11/11.
//  Copyright © 2015年 JiRanAsset. All rights reserved.
//

#import "RunObject.h"
#import "SOMotionDetector.h"
#import "SOStepDetector.h"
#import "UpLoadModel.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <MapKit/MapKit.h>
#import <HealthKit/HealthKit.h>
#import "TTMHealthKitHelper.h"
#import "sys/sysctl.h"
#import "HealthManager.h"
#import "FileManager.h"


@implementation RunObject

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        //初始化步数
        [self initStepCount];
        //初始化数据
        [self initAll];
    }
    return self;
}

#pragma mark - 检查HealthKit -- 获取健康的步数
- (void)checkTheHealthKit
{
    if (![HKHealthStore isHealthDataAvailable])
    {
        [PersonInfo sharePersonInfo].isAllow = NO;
        Alert(@"HealthKit这该iOS设备上不可用,清检查手机设置！");
    }
    else
    {
        self.healthStore = [[HKHealthStore alloc] init];
        HKHealthStore *healthStore = [[HKHealthStore alloc]init];
        NSSet *readSet = [NSSet setWithArray:[NSArray arrayWithObjects:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount], nil]];
        [healthStore requestAuthorizationToShareTypes:nil readTypes:readSet completion:^(BOOL success, NSError * _Nullable error) {
            if (!success) {
                NSLog(@"error = %@",error.description);
                [PersonInfo sharePersonInfo].isAllow = NO;
                //授权失败
            }
            else
            {
                [PersonInfo sharePersonInfo].isAllow = YES;
            }
        }];
        if ([healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]]) {
            NSLog(@"允许共享这种类型数据");
            [PersonInfo sharePersonInfo].isAllow = YES;
        }
        else
        {
            NSLog(@"不允许共享这种类型数据");
            [PersonInfo sharePersonInfo].isAllow = NO;
        }
    }
}
#pragma mark - 初始化所有的控件或类型
- (void)initAll
{
    _fileNameArr = [NSString stringWithFormat:@"%@loadArr.txt",[PersonInfo sharePersonInfo].userId];
    _fileMag = [[FileManager alloc]init];
    
    _isHealthKit = [self getCurrentDeviceModel];
    
    _dateTimeArr = [[NSMutableArray alloc]init];
    
    [PersonInfo sharePersonInfo].isHealthKit = _isHealthKit;
    
    _locationArray = [[NSMutableArray alloc]init];
    NSArray *arr = [_fileMag readFileArrayWithFileName:_fileNameArr];
    if(arr!=nil && arr.count>0)
    {
        [_locationArray setArray:arr];
    }
    
    _timerisBuld = NO;
    
    _nowAllStep = 0;
    _oldNowAllStep = 0;
    _countdown = 0;
    
    if(!_timerisBuld)
    {
        _timerCount = 0;
        _timerFirst = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerRuning) userInfo:nil repeats:YES];
        [_timerFirst setFireDate:[NSDate distantPast]];
        _timerisBuld = YES;
    }
    _isRequest = YES;
    
    self.items = [TTMHealthKitHelper quantityTypes];
}

#pragma mark - 开始跑定时器
- (void)timerRuning
{
    _timerCount ++;
    NSString *strTimerCount = [self stringFromTimeInterval:_timerCount];
    //运动类型
    if (self.timerCountBlock) {
        self.timerCountBlock(strTimerCount);
    }
    if(_isHealthKit)
    {
        //获取步数从HealthKit 实时获取
        [self getstepCountFromHealthKit];
    }
}

#pragma mark - 初始化步数
- (void)initStepCount
{
    NSString *SearchTime = [RequestHelper getDateStrFromTimestamp:[RequestHelper getTheTimestamp]];
    NSString *stepCountStr = [self getStepCountWith:@"1" SearchTime:SearchTime SearchNumber:@"1"];
    NSInteger stepCount = 0;
    if([stepCountStr isEqual:[NSNull null]]||stepCountStr==nil||stepCountStr.length==0)
    {
        stepCount = 0;
    }
    else
    {
        stepCount = [stepCountStr integerValue];
    }
    [PersonInfo sharePersonInfo].stepCount = stepCount;   //实时步数
    [PersonInfo sharePersonInfo].oldStepCount = stepCount;//旧的步数
}

#pragma mark - 开始运动
- (void)startRuning
{
    if(_locationArray==nil)
    {
        _locationArray = [[NSMutableArray alloc]init];
    }
    
    //速度
    [SOMotionDetector sharedInstance].locationChangedBlock = ^(CLLocation *location) {
        BOOL isLogIn = [PersonInfo sharePersonInfo].isLogIn;//判断是否登录
        //BOOL isAllow = [PersonInfo sharePersonInfo].isAllow;//判断是否有获取健康数据的权限
        if(isLogIn)
        {
            NSString *speedStr = [NSString stringWithFormat:@"%.2f",[SOMotionDetector sharedInstance].currentSpeed * 3.6f];
            if (self.speedStrBlock) {
                self.speedStrBlock(speedStr);
            }
        }
    };
    
    //是否晃动
    [SOMotionDetector sharedInstance].accelerationChangedBlock = ^(CMAcceleration acceleration) {
        BOOL isLogIn = [PersonInfo sharePersonInfo].isLogIn;//判断是否登录
        if(isLogIn)
        {
            _isShaking = [SOMotionDetector sharedInstance].isShaking;
            
            if (self.isShakingBlock) {
                self.isShakingBlock(_isShaking);
            }
            if(_isShaking)
            {
                //用户开始运动 就把记录静止的时间字段置为0
                _countdown = 0;
            }
            else
            {
                //记录静止的时间
                _countdown ++;
            }
            CGFloat timerValue = _countdown/100;

            //用户静止超过15秒 上传数组里面剩余的步数
            if(timerValue>=15)
            {
                //数组里有步数才执行上传操作
                if(_locationArray.count >0)
                {
                    BOOL isBrokenNetwork = [PersonInfo sharePersonInfo].isBrokenNetwork;
                    if(isBrokenNetwork)
                    {
                        NSLog(@"断网状态，不上传数据");
                    }
                    else
                    {
                        [self upLoadlocationArray];//上传数据
                    }
                    _countdown = 0;//静止的时候数据上传成功后  就把记录静止的时间字段置为0
                }
            }
        }
    };
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        
        //Use M7 chip if available, otherwise use lib's algorithm
        [SOMotionDetector sharedInstance].useM7IfAvailable = YES;
    }
    
    [[SOMotionDetector sharedInstance] startDetection];
    //只有5s以上的版本可以使用运动与健身
    if(_isHealthKit)
    {
        //获取健康的步数
        [self checkTheHealthKit];
        //M7处理器获取步数------健康的步数加上M7的实时步数
        //[self newMethodsToGetStepCount];
    }
    else
    {
        //获取自己的算法计算的步数
        [self getStepCountOfMyMethods];
    }
    //[self newMethodsToGetStepCount];
    
}
#pragma mark - M7处理器获取步数
//改步数只是在界面上显示 动态显示数据  不上传服务器 真正上传服务器的数据来自健康的数据
- (void)newMethodsToGetStepCount
{
    if (!([CMStepCounter isStepCountingAvailable] || [CMMotionActivityManager isActivityAvailable]))
    {
        [self getStepCountOfMyMethods];
    }
    else
    {
        __weak RunObject *weakSelf = self;
        
        self.operationQueue = [[NSOperationQueue alloc] init];
        
        if ([CMStepCounter isStepCountingAvailable])
        {
            
            weakSelf.stepCounter = [[CMStepCounter alloc] init];
            
            [self.stepCounter startStepCountingUpdatesToQueue:self.operationQueue updateOn:1 withHandler:^(NSInteger numberOfSteps, NSDate *timestamp, NSError *error) {
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     if (error)
                     {
                         //数据获取失败
                     }
                     else
                     {
                         NSInteger nowNumberOfSteps = numberOfSteps - self.oldNumberOfSteps;
                         
                         self.oldNumberOfSteps = numberOfSteps;
                         
                         if(nowNumberOfSteps>0)
                         {
                             NSInteger stepCount = 0;
                             if(_nowAllStep==0)
                             {
                                 stepCount = [PersonInfo sharePersonInfo].stepCount;
                             }
                             else
                             {
                                 stepCount = _nowAllStep;
                             }
                             
                             stepCount = stepCount + nowNumberOfSteps;
                             
                             _nowAllStep = stepCount;
                             
                             NSString *value = [NSString stringWithFormat:@"%ld",(long)_nowAllStep];
                             NSLog(@"现在的步数 ================== %@",value);
                             
                             if(!_isHealthKit)
                             {
                                 //上传步数 //请求状态
                                 BOOL isLogIn = [PersonInfo sharePersonInfo].isLogIn;//判断是否登录
                                 if(isLogIn && _isRequest)
                                 {
                                     //健康不能用的时候用M7记步上传
                                     [self setStepCountAboutDataBase:value locationCount:20 getArr:nil];
                                 }
                             }
                             else
                             {
                                 //通过M7处理器获取最新的步数  不上传服务器
                                 if (weakSelf.stepCountBlock) {
                                     weakSelf.stepCountBlock(value);
                                 }
                             }
                         }
                         
                     }
                 });
             }];
        }
    }
}

#pragma mark - 获取自己的算法计算的步数
- (void)getStepCountOfMyMethods
{
    [[SOStepDetector sharedInstance] startDetectionWithUpdateBlock:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
            return;
        }
        //步数
        BOOL isLogIn = [PersonInfo sharePersonInfo].isLogIn;//判断是否登录
        if(isLogIn)
        {
            //不是在请求状态
            if(_isRequest)
            {
                NSInteger stepCount = [PersonInfo sharePersonInfo].stepCount;
                stepCount ++;
                [PersonInfo sharePersonInfo].stepCount = stepCount;
                
                NSString *stepCountStr = [NSString stringWithFormat:@"%ld",(long)stepCount];
                
                [self setStepCountAboutDataBase:stepCountStr locationCount:15 getArr:nil];
            }
        }
    }];
}

//停止定位
- (void)stopUpdatingLocation
{
    [_timerFirst setFireDate:[NSDate distantFuture]];
    _timerFirst = nil;
    _locationArray = nil;
    _isShaking = NO;
    _timerCount = 0;
}
#pragma mark - 拼接上传数据
- (void)upLoadlocationArray
{
    //合并相同时间的步数
    NSMutableArray *categoryArray = [[NSMutableArray alloc] init];
    NSMutableArray *dateTimeArr = [[NSMutableArray alloc] init];
    for (int i = 0; i < _locationArray.count; i++)
    {
        NSDictionary *dict = [_locationArray objectAtIndex:i];
        NSString *oldstepCount = dict[@"stepCount"];
        NSString *olddateTime = dict[@"dateTime"];
        if ([dateTimeArr containsObject:olddateTime] == NO)
        {
            //没有相同的就添加
            NSMutableDictionary *newDict = [[NSMutableDictionary alloc]initWithDictionary:dict];
            [categoryArray addObject:newDict];
            [dateTimeArr addObject:olddateTime];
        }
        else
        {
            //有相同的 合并
            for (NSMutableDictionary *newDict in categoryArray)
            {
                NSString *newdateTime = newDict[@"dateTime"];
                if([olddateTime isEqualToString:newdateTime])
                {
                    NSString *newstepCount = newDict[@"stepCount"];
                    NSInteger lastStepCount = [oldstepCount integerValue] + [newstepCount integerValue];
                    NSString *lastStepCountStr = [NSString stringWithFormat:@"%ld",(long)lastStepCount];
                    [newDict setValue:lastStepCountStr forKey:@"stepCount"];
                }
            }
        }
        
    }
    
    [_locationArray removeAllObjects];
    [_locationArray setArray:categoryArray];
    
    //拼接参数
    NSMutableString *ParamList = [[NSMutableString alloc]init];

    for (int i = 0;i<_locationArray.count;i++)
    {
        NSDictionary *dict = [_locationArray objectAtIndex:i];
        NSString *stepnumber = [dict objectForKey:@"stepCount"];
        NSString *RunDuration = [dict objectForKey:@"dateTime"];
        
        NSString *partStr = nil;
        
        if(i!=_locationArray.count-1)
        {
            partStr = [NSString stringWithFormat:@"stepnumber<%@|runduration<%@,",stepnumber,RunDuration];
        }
        else
        {
            partStr = [NSString stringWithFormat:@"stepnumber<%@|runduration<%@",stepnumber,RunDuration];
        }
        [ParamList appendString:partStr];
    }

    if(_isRequest)
    {
        //请求数据
        _isRequest = NO;
        [self requestDataWith:ParamList Gid:nil];
    }
}

#pragma mark - 请求数据
- (void)requestDataWith:(NSString *)ParamList Gid:(NSString *)Gid
{
    NSString *userid = [PersonInfo sharePersonInfo].userId;//用户ID
    if(userid==nil)
    {
        return;
    }
    NSString *Taskid = @"1";
    NSDictionary *wParamDict = @{@"userid":userid,@"Taskid":Taskid,@"Gid":@"1",@"ParamList":ParamList,@"Param":@"Param"};
    [RequestEngine UserModulescollegeWithDict:wParamDict wAction:@"1005" completed:^(NSString *errorCode, id resultDict) {
        _isRequest = YES;
        if([errorCode isEqualToString:@"0"])
        {
            NSArray *resultArr = (NSArray *)resultDict;
            NSDictionary *dict = [resultArr firstObject];
            
            [self dataUploadedSuccessfully:dict];//数据上传成功后处理返回的数据
            
            NSLog(@"上传成功");
        }
        else if([errorCode isEqualToString:@"112"])
        {
            [_locationArray removeAllObjects];
            BOOL isScu = [_fileMag delectFileArrayWithFileName:_fileNameArr];
            if(!isScu)
            {
                //如果删除失败，直接附一个空的数组给他
                [_fileMag writeFileArray:_locationArray fileName:_fileNameArr];
            }
        }
        else
        {
            NSLog(@"ReturnCode  ===  %@",[ReturnCode getResultFromReturnCode:errorCode]);
        }
    }];
}

#pragma mark - 数据上传成功
- (void)dataUploadedSuccessfully:(NSDictionary *)dict
{
    NSString *isok = [NSString stringWithFormat:@"%@",[dict objectForKey:@"isok"]];
    NSString *mileage = [NSString stringWithFormat:@"%@",[dict objectForKey:@"mileage"]];
    NSString *stepnumber = [NSString stringWithFormat:@"%@",[dict objectForKey:@"SetpNumber"]];
    NSString *taskid = [NSString stringWithFormat:@"%@",[dict objectForKey:@"taskid"]];
    [_locationArray removeAllObjects];
    BOOL isScu = [_fileMag delectFileArrayWithFileName:_fileNameArr];
    if(!isScu)
    {
        //如果删除失败，直接附一个空的数组给他
        [_fileMag writeFileArray:_locationArray fileName:_fileNameArr];
    }
    
    [PersonInfo sharePersonInfo].isok = isok;                          //五公里的线下活动有没有完成
    [PersonInfo sharePersonInfo].mileage = mileage;                    //返回的里程
    [PersonInfo sharePersonInfo].stepCount = [stepnumber integerValue];//返回的步数
    [PersonInfo sharePersonInfo].taskid = taskid;                      //任务ID
    
    if([isok isEqualToString:@"0"])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *isHaveDownRunPush = [defaults objectForKey:KisHaveDownRunPush];
        if(![isHaveDownRunPush isEqualToString:@"YES"])
        {
            NSString *alertBody = @"恭喜您，您已经完成五公里任务赛哦";
            NSDictionary *userDict = [NSDictionary dictionaryWithObject:alertBody forKey:KhaveDownRun];
            [LocalPush registerLocalNotification:1 alertBody:alertBody userDict:userDict];
        }
    }
    
    //将已经上传过后的数据时间存在本地
    //待完成。。。。。
}

#pragma mark - 从HealthKit获取数据
- (void)fetchQuantity:(HKQuantityType *)type completionHandler:(void (^)(NSArray *result, NSError *error))completionHandler
{
    if(self.healthStore==nil)
    {
        self.healthStore = [[HKHealthStore alloc]init];
    }
    //新的算法
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSPredicate *predicate = [HealthManager predicateForSamplesToday];
    HKSampleQuery *queryHKSampleQuery = [[HKSampleQuery alloc]initWithSampleType:stepType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:@[timeSortDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        if (!results) {
            if (completionHandler) {
                completionHandler(nil, error);
            }
            return;
        }
        if (completionHandler) {
            completionHandler(results, error);
        }
        
    }];
    
    [self.healthStore executeQuery:queryHKSampleQuery];
}

#pragma mark - 获取步数从HealthKit
- (void)getstepCountFromHealthKit
{
    HKQuantityType *type = self.items[5];
    [self fetchQuantity:type completionHandler:^(NSArray *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error)
            {
                //获取失败
                NSLog(@"error:%@",error);
                [PersonInfo sharePersonInfo].isAllow = NO;
            }
            else if ([result count] == 0)
            {
                //没有数据
                [PersonInfo sharePersonInfo].isAllow = YES;
            }
            // succeeded to retrieve the health data
            else
            {
                [PersonInfo sharePersonInfo].isAllow = YES;
                NSArray *array = [self getRealHealthData:result];
                
                
                //统计数组里面的步数
                NSInteger allArrStepCount = 0;
                //一个数组的添加
                for (NSDictionary *dict in array)
                {
                    NSInteger stepCount = [dict[@"stepCount"] integerValue];
                    allArrStepCount = allArrStepCount + stepCount;
                    NSString *dateTime = dict[@"dateTime"];
                    [_dateTimeArr addObject:dateTime];
                }
                
                NSString *value = [NSString stringWithFormat:@"%ld",(long)allArrStepCount];
                
                [self setStepCountAboutDataBase:value locationCount:1 getArr:array];
            }
          });
      }];
}

#pragma mark - 从健康中获取真实数据 -- 去除人为添加的
- (NSArray *)getRealHealthData:(NSArray *)resultArr
{
    NSMutableArray *returnArr = [[NSMutableArray alloc]init];
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    for (HKQuantitySample *model in resultArr)
    {
        //HKQuantity 类存储了给定单位的值,此值和单位就构成了数据。和 HKUnit 类一样,在使用它时, 需要进行实例化。实例化 HKQuantity 需要使用到 init(unit:doubleValue:)方法。它可以用来创建一个 quantity(数量)对象。
        HKQuantity *resultQuantity = model.quantity;
        HKUnit *unit = [TTMHealthKitHelper defaultUnitForQuantityType:stepType];
        double valueDou = [resultQuantity doubleValueForUnit:unit];
        NSString *value = [NSString stringWithFormat:@"%.0f",valueDou];

        //NSString *startDateStr = [RequestHelper getDateStrFromDate:model.startDate];
        NSString *endDateStr   = [RequestHelper getDateStrFromDate:model.endDate];
        
        NSDictionary *dict = (NSDictionary *)model.metadata;
        NSInteger wasUserEntered = [dict[@"HKWasUserEntered"] integerValue];
        
        if(wasUserEntered == 1)
        {
            //这是用户自己手动添加的数据 不上传 不加入
            //NSLog(@"value == %@",value);
        }
        else
        {
            //这是苹果HealthKit记录的数据
            NSDictionary *dictReturn = @{@"dateTime":endDateStr,@"stepCount":value};
            [returnArr addObject:dictReturn];
        }
    }
    return returnArr;
}

#pragma mark - 得到步数设置相关东西
- (void)setStepCountAboutDataBase:(NSString *)value locationCount:(NSInteger)locationCount  getArr:(NSArray *)array
{
    if(_dateTimeArr==nil)
    {
        _dateTimeArr = [[NSMutableArray alloc]init];
    }
    if(value==nil)
    {
        //待细化数据。。。。。。
//        //统计数组里面的步数
//        NSInteger allArrStepCount = 0;
//        //一个数组的添加
//        for (NSDictionary *dict in array)
//        {
//            [_locationArray addObject:dict];
//            NSInteger stepCount = [dict[@"stepCount"] integerValue];
//            allArrStepCount = allArrStepCount + stepCount;
//            NSString *dateTime = dict[@"dateTime"];
//            [_dateTimeArr addObject:dateTime];
//        }
//        
//        if (self.stepCountBlock) {
//            self.stepCountBlock([NSString stringWithFormat:@"%ld",allArrStepCount]);
//        }
//        
//        if(_locationArray.count >= array.count)
//        {
//            [self upLoadlocationArray];//上传数据
//        }
    }
    else if(value.length > 0)
    {
        //一条一条的添加
        if(_nowAllStep==0)
        {
            if (self.stepCountBlock) {
                self.stepCountBlock(value);
            }
        }
        
        [PersonInfo sharePersonInfo].stepCount = [value integerValue];
        
        NSInteger oldStepCount = [PersonInfo sharePersonInfo].oldStepCount;
        
        NSString *timerStr = [RequestHelper getTimerStrFromTimestamp];
        
        NSInteger differenceValue = [value integerValue] - oldStepCount;
        
        if(differenceValue > 0)
        {
            _nowAllStep = 0;
            if (self.stepCountBlock) {
                self.stepCountBlock(value);
            }
            //往步数数组添加数据
            [PersonInfo sharePersonInfo].oldStepCount = [value integerValue];
            NSString *stepCountStr = [NSString stringWithFormat:@"%ld",(long)differenceValue];
            NSDictionary *dict = @{@"dateTime":timerStr,@"stepCount":stepCountStr};
            [_locationArray addObject:dict];
        }
        
        NSLog(@"_locationArray.count == %ld",(long)_locationArray.count);
        
        if(_fileNameArr.length>0&&_locationArray.count>0)
        {
            [_fileMag writeFileArray:_locationArray fileName:_fileNameArr];
        }
        
        if(_locationArray.count >= locationCount)
        {
            BOOL isBrokenNetwork = [PersonInfo sharePersonInfo].isBrokenNetwork;
            if(isBrokenNetwork)
            {
                NSLog(@"断网状态，不上传数据");
            }
            else
            {
                [self upLoadlocationArray];//上传数据
            }
        }
    }
}

//获得设备型号
- (BOOL)getCurrentDeviceModel
{
    int mib[2];
    size_t len;
    char *machine;
    
    mib[0] = CTL_HW;
    mib[1] = HW_MACHINE;
    sysctl(mib, 2, NULL, &len, NULL, 0);
    machine = malloc(len);
    sysctl(mib, 2, machine, &len, NULL, 0);
    
    NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    
    if ([platform isEqualToString:@"iPhone1,1"]) return NO; //return @"iPhone 2G (A1203)";
    else if ([platform isEqualToString:@"iPhone1,2"]) return NO; //return @"iPhone 3G (A1241/A1324)";
    else if ([platform isEqualToString:@"iPhone2,1"]) return NO; //return @"iPhone 3GS (A1303/A1325)";
    else if ([platform isEqualToString:@"iPhone3,1"]) return NO; //return @"iPhone 4 (A1332)";
    else if ([platform isEqualToString:@"iPhone3,2"]) return NO; //return @"iPhone 4 (A1332)";
    else if ([platform isEqualToString:@"iPhone3,3"]) return NO; //return @"iPhone 4 (A1349)";
    else if ([platform isEqualToString:@"iPhone4,1"]) return NO; //return @"iPhone 4S (A1387/A1431)";
    else if ([platform isEqualToString:@"iPhone5,1"]) return NO; //return @"iPhone 5 (A1428)";
    else if ([platform isEqualToString:@"iPhone5,2"]) return NO; //return @"iPhone 5 (A1429/A1442)";
    else if ([platform isEqualToString:@"iPhone5,3"]) return NO; //return @"iPhone 5c (A1456/A1532)";
    else if ([platform isEqualToString:@"iPhone5,4"]) return NO; //return @"iPhone 5c (A1507/A1516/A1526/A1529)";
    else if ([platform isEqualToString:@"iPhone6,1"]) return YES; //return @"iPhone 5s (A1453/A1533)";
    else if ([platform isEqualToString:@"iPhone6,2"]) return YES; //return @"iPhone 5s (A1457/A1518/A1528/A1530)";
    else if ([platform isEqualToString:@"iPhone7,1"]) return YES; //return @"iPhone 6 Plus (A1522/A1524)";
    else if ([platform isEqualToString:@"iPhone7,2"]) return YES; //return @"iPhone 6 (A1549/A1586)";
    else if ([platform isEqualToString:@"iPhone8,1"]) return YES; //return @"iPhone 6s ";
    else if ([platform isEqualToString:@"iPhone8,2"]) return YES; //return @"iPhone 6s ";
    
    else if ([platform isEqualToString:@"iPod1,1"]) return NO;   //return @"iPod Touch 1G (A1213)";
    else if ([platform isEqualToString:@"iPod2,1"]) return NO;   //return @"iPod Touch 2G (A1288)";
    else if ([platform isEqualToString:@"iPod3,1"]) return NO;   //return @"iPod Touch 3G (A1318)";
    else if ([platform isEqualToString:@"iPod4,1"]) return NO;   //return @"iPod Touch 4G (A1367)";
    else if ([platform isEqualToString:@"iPod5,1"]) return NO;   //return @"iPod Touch 5G (A1421/A1509)";
    
    else if ([platform isEqualToString:@"iPad1,1"]) return NO;   //return @"iPad 1G (A1219/A1337)";
    
    else if ([platform isEqualToString:@"iPad2,1"]) return NO;   //return @"iPad 2 (A1395)";
    else if ([platform isEqualToString:@"iPad2,2"]) return NO;   //return @"iPad 2 (A1396)";
    else if ([platform isEqualToString:@"iPad2,3"]) return NO;   //return @"iPad 2 (A1397)";
    else if ([platform isEqualToString:@"iPad2,4"]) return NO;   //return @"iPad 2 (A1395+New Chip)";
    else if ([platform isEqualToString:@"iPad2,5"]) return NO;   //return @"iPad Mini 1G (A1432)";
    else if ([platform isEqualToString:@"iPad2,6"]) return NO;   //return @"iPad Mini 1G (A1454)";
    else if ([platform isEqualToString:@"iPad2,7"]) return NO;   //return @"iPad Mini 1G (A1455)";
    
    else if ([platform isEqualToString:@"iPad3,1"]) return NO;   //return @"iPad 3 (A1416)";
    else if ([platform isEqualToString:@"iPad3,2"]) return NO;   //return @"iPad 3 (A1403)";
    else if ([platform isEqualToString:@"iPad3,3"]) return NO;   //return @"iPad 3 (A1430)";
    else if ([platform isEqualToString:@"iPad3,4"]) return NO;   //return @"iPad 4 (A1458)";
    else if ([platform isEqualToString:@"iPad3,5"]) return NO;   //return @"iPad 4 (A1459)";
    else if ([platform isEqualToString:@"iPad3,6"]) return NO;   //return @"iPad 4 (A1460)";
    
    else if ([platform isEqualToString:@"iPad4,1"]) return NO;   //return @"iPad Air (A1474)";
    else if ([platform isEqualToString:@"iPad4,2"]) return NO;   //return @"iPad Air (A1475)";
    else if ([platform isEqualToString:@"iPad4,3"]) return NO;   //return @"iPad Air (A1476)";
    else if ([platform isEqualToString:@"iPad4,4"]) return NO;   //return @"iPad Mini 2G (A1489)";
    else if ([platform isEqualToString:@"iPad4,5"]) return NO;   //return @"iPad Mini 2G (A1490)";
    else if ([platform isEqualToString:@"iPad4,6"]) return NO;   //return @"iPad Mini 2G (A1491)";
    
    else if ([platform isEqualToString:@"i386"]) return NO;      //return @"iPhone Simulator";
    else if ([platform isEqualToString:@"x86_64"]) return NO;    //return @"iPhone Simulator";
    else return YES;
}

#pragma mark - 把时间戳格式化输出
- (NSString *)stringFromTimeInterval:(NSInteger)interval
{
    NSInteger seconds = interval % 60;
    NSInteger minutes = (interval / 60) % 60;
    NSInteger hours = (interval / 3600);
    
    return [NSString stringWithFormat:@"%02ld′%02ld″%02ld", (long)hours, (long)minutes, (long)seconds];
}
#pragma mark - 从服务器获取当天的步数数据
- (NSString *)getStepCountWith:(NSString *)Type SearchTime:(NSString *)SearchTime SearchNumber:(NSString *)SearchNumber
{
    NSString *userid = [PersonInfo sharePersonInfo].userId;
    NSDictionary *wParamDict = @{@"taskid":@"1",@"userid":userid};
    NSDictionary *dict = [RequestEngine getResponseObjectWithWParamDict:wParamDict wAction:@"1004"];
    NSDictionary *Data = [[dict objectForKey:@"Data"] lastObject];
    NSString *stepnumber = [NSString stringWithFormat:@"%@",[Data objectForKey:@"stepnumber"]];
    return stepnumber;
}
/////////

@end
 
 */
