/*
//  RunObject.h
//  prj1115
//
//  Created by ZFJ_APPLE on 15/11/11.
//  Copyright © 2015年 JiRanAsset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "SOMotionDetector.h"
#import "UpLoadModel.h"
#import <HealthKit/HealthKit.h>
#import "FileManager.h"

typedef void (^ motionType)(NSString *motionTypeBlock);
typedef void (^ speedStr)(NSString *speedStrBlock);
typedef void (^ isShaking)(BOOL isShakingBlock);
typedef void (^ stepCount)(NSString *stepCountBlock);
typedef void (^ timerCount)(NSString *timerCountBlock);

@interface RunObject : NSObject<CLLocationManagerDelegate,SOMotionDetectorDelegate>
{
    NSMutableArray *_locationArray;      //定位集合数组
    BOOL _isShaking;                     //是否在跑步
    NSInteger _timerCount;               //跑步计时器
    NSTimer *_timerFirst;                //计时器
    NSInteger _stepCountLoad;
    BOOL _isRequest;                     //是否在请求数据
    
    BOOL _isHealthKit;                   //是否有运动与健康
    
    BOOL _timerisBuld;                   //_timerFirst是否创建过
    
    NSMutableArray *_dateTimeArr;        //步数对应的时间
    
    NSInteger _nowAllStep;               //实时全部的M7数据 + 健康
    NSInteger _oldNowAllStep;            //旧的M7数据 + 健康
    //NSInteger _numberOfSteps;            //M7步数之和
    //NSInteger _oldNumberOfSteps;         //旧的M7步数之和
    
    NSInteger _countdown;                //静止是倒计时  数据上传
    
    FileManager *_fileMag;               //文件管理类
    NSString *_fileNameArr;                 //数组上传本地文件名称
}

@property (nonatomic,copy)motionType motionTypeBlock;        //运动类型
@property (nonatomic,copy)speedStr speedStrBlock;            //速度
@property (nonatomic,copy)isShaking isShakingBlock;          //是否晃动
@property (nonatomic,copy)stepCount stepCountBlock;          //运动步数
@property (nonatomic,copy)timerCount timerCountBlock;        //计时器


@property (nonatomic,assign) NSInteger oldNumberOfSteps;     //旧的步数
//@property (nonatomic,assign) NSInteger oldvalue;             //从健康获取的旧的步数

@property (nonatomic, strong) HKHealthStore *healthStore;
@property (nonatomic, strong) NSArray *items;


@property (nonatomic, strong) CMStepCounter *stepCounter;
@property (nonatomic, strong) CMMotionActivityManager *activityManager;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

//开始运动
- (void)startRuning;

//停止定位
- (void)stopUpdatingLocation;

@end
 */
