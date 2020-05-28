//
//  ViewController.m
//  RACPractice
//
//  Created by ^_^ on 2020/5/19.
//  Copyright © 2020 rf. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveObjC.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //使用cocoaPods在podfile中添加 pod 'ReactiveObjC', '~> 3.1.0' ，然后pod install一下。在项目中#import <ReactiveObjC.h>
//    RAC中信号的其它动作：
//
//    信号映射：map、flattenMap
//
//    信号过滤：filter、ignore、distinctUntilChanged
//
//    信号合并：combineLatest、reduce、merge、zipWith
//
//    信号连接：concat、then
//
//    信号操作时间：timeout、interval、dely
//
//    信号跳过：skip
//
//    信号取值：take、takeLast、takeUntil
//
//    信号发送顺序：donext、cocompleted
//
//    获取信号中的信号：switchToLatest
//
//    信号错误重试：retry
    
    [self rac_button];
    [self rac_gesture];
    [self rac_kvo];
    
    [self rac_other];
}

- (void)rac_button{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 80, 100, 40);
    [button setTitle:@"rac按钮" forState:UIControlStateNormal];
    [self.view addSubview:button];
    [[button rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        self.label.text = [button titleForState:UIControlStateNormal];
        [self rac_createSignal];
        
    }];
    
}
- (void)rac_gesture{
    UILabel *lbl = [UILabel new];
    lbl.frame = CGRectMake(100, 80, 100, 40);
    lbl.text = @"rac手势";
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.userInteractionEnabled = YES;
    [self.view addSubview:lbl];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    [lbl addGestureRecognizer:tap];
    @weakify(self)
    [tap.rac_gestureSignal subscribeNext:^(__kindof UIGestureRecognizer * _Nullable x) {
        @strongify(self)
        self.label.text = lbl.text;
    }];
}
- (void)rac_kvo{
    [RACObserve(self.label, text) subscribeNext:^(id  _Nullable x) {
        NSLog(@"你变了:%@",x);
    }];
    
}
- (void)rac_delegate{
    
    [[self rac_signalForSelector:@selector(textFieldShouldBeginEditing:) fromProtocol:@protocol(UITextFieldDelegate)] subscribeNext:^(RACTuple * _Nullable x) {
        NSLog(@"这里会响应对应的协议方法:%@",x);
    }];
//    textfield.delegate = self;
}
- (void)rac_notification{
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillShowNotification object:nil] subscribeNext:^(NSNotification * _Nullable x) {
        NSLog(@"通知就这样去监听");
    }];
}
- (void)rac_timer{
    //注意要强引用self.timer
    
//      self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
//
//        dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);//2 开始时间 、持续时间、
//
//        dispatch_source_set_event_handler(self.timer, ^{
//
//                NSLog(@"GCD timer：%@", [NSThread currentThread]); //打印的是在子线程
//
//            });
//
//        dispatch_resume(self.timer); //启动
    
    
    RACDisposable *signal = [[RACSignal interval:2 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSDate * _Nullable x) {
        NSLog(@"%@",x);
    }];
//    [signal dispose];  //此方法销毁时间，
    
    //如需要在子线程执行
    [[RACSignal interval:1 onScheduler:[RACScheduler schedulerWithPriority:(RACSchedulerPriorityDefault) name:@"ssssss"]]   subscribeNext:^(NSDate * _Nullable x) {
        NSLog(@"子线程:%@", [NSThread currentThread]);
    }];
    
    // 延时执行
    // 五秒后执行一次
    [[RACScheduler mainThreadScheduler] afterDelay:5 schedule:^{
        
        NSLog(@"五秒后执行一次");
        
    }];
    
    
    // 定时执行
    // 每隔两秒执行一次
    // 这里要加takeUntil条件限制一下否则当控制器pop后依旧会执行 ﻿
    // 每一秒执行一次,这里要加上释放信号,否则控制器推出后依旧会执行
    [[[RACSignal interval:2 onScheduler:[RACScheduler mainThreadScheduler]] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        
        NSLog(@"每两秒执行一次");
        
    }];
}
- (void)rac_createSignal{
    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [subscriber sendNext:@"发送信号"];
        return [RACDisposable disposableWithBlock:^{  //销毁信息
            
        }];
    }];
    
    [signal subscribeNext:^(id  _Nullable x) {
        NSLog(@"%@",x);
    }];
    
    //方法2 使用子类.无实现销毁操作
    RACSubject *subject = [RACSubject subject];
    [subject subscribeNext:^(id  _Nullable x) {
        NSLog(@"订阅信号:%@",x);
    }];
    [subject sendNext:@"这里也发送信息"];
}
- (void)rac_other{
    // 跳跃 ： 如下，skip传入2 跳过前面两个值
    // 实际用处： 在实际开发中比如 后台返回的数据前面几个没用，我们想跳跃过去，便可以用skip
    RACSubject *subject = [RACSubject subject];
    [[subject skip:2] subscribeNext:^(id x) {
        NSLog(@"跳过前两个后的值%@", x);  //3
    }];
    [subject sendNext:@1];
    [subject sendNext:@2];
    [subject sendNext:@3];
   
    
    
    //distinctUntilChanged:-- 如果当前的值跟上一次的值一样，就不会被订阅到
    subject = [RACSubject subject];
    [[subject distinctUntilChanged] subscribeNext:^(id x) {
        NSLog(@"去重%@", x);  //1  2
    }];
    // 发送信号
    [subject sendNext:@1];
    [subject sendNext:@2];
    [subject sendNext:@2]; // 不会被订阅
    
    
    // take:可以屏蔽一些值,取前面几个值---这里take为2 则只拿到前两个值
    subject = [RACSubject subject];
    [[subject take:2] subscribeNext:^(id x) {
        NSLog(@"取前2个%@", x);
    }];
    // 发送信号
    [subject sendNext:@1];
    [subject sendNext:@2];
    [subject sendNext:@3];
   
    subject = [RACSubject subject];
    RACSubject *subject2 = [RACSubject subject];
    [[subject takeUntil:subject2] subscribeNext:^(id x) {
        NSLog(@"subject2响应时，subject失效%@", x);
    }];
    // 发送信号
    [subject sendNext:@1];
    [subject sendNext:@2];
    [subject2 sendNext:@3];  // 1
    //    [subject2 sendCompleted]; // 或2
    [subject sendNext:@4];
    
}
@end
