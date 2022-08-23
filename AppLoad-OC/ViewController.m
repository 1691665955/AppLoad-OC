//
//  ViewController.m
//  AppLoad-OC
//
//  Created by 曾龙 on 2022/8/22.
//

#import "ViewController.h"
#include <stdint.h>
#include <stdio.h>
#include <sanitizer/coverage_interface.h>
#import <dlfcn.h>
#import <libkern/OSAtomic.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self saveOrderFile];
}

// 保存order文件
- (void)saveOrderFile {
    // 定义数组
    NSMutableArray<NSString *> *sybleNames = [NSMutableArray array];

    while (YES) {
        SymboNode *node =OSAtomicDequeue(&symbolList, offsetof(SymboNode, next));
        if (node == NULL) {
            break;
        }
        //获取符号信息
        Dl_info info;
        dladdr(node->pc, &info);
        // 转字符串
        NSString *name = @(info.dli_sname);
        // 区分函数，block和OC方法的符号，函数与block是一样的
        NSString *symbolName = ([name hasPrefix:@"+["] || [name hasPrefix:@"-["])? name: [@"_" stringByAppendingString:name];
        [sybleNames addObject:symbolName];
    }
    //反向遍历数组
    NSEnumerator *enumerator = [sybleNames reverseObjectEnumerator];
    NSMutableArray *funArray = [NSMutableArray arrayWithCapacity:sizeof(sybleNames.count)];
    // 遍历去除重复的符号
    NSString *name;
    while (name = [enumerator nextObject]) {
        if (![funArray containsObject:name]) {
            [funArray addObject:name];
        }
    }

    //去掉自己
    [funArray removeObject:[NSString stringWithFormat:@"%s", __func__]];
    // 写入order文件
    // 变成字符串
    NSString *funcStr = [funArray componentsJoinedByString:@"\n"];

    // 存储路径
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingString:@"/clangTrace.order"];
    // 文件
    NSData *file = [funcStr dataUsingEncoding:NSUTF8StringEncoding];

    // 创建文件
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:file attributes:nil];

    NSLog(@"\n%@", funcStr);
}

// 定义原子队列
static OSQueueHead symbolList = OS_ATOMIC_QUEUE_INIT;

// 定义符号的结构
typedef struct {
    void * pc; // 函数地址
    void * next; // 下一个函数节点
}SymboNode;

void __sanitizer_cov_trace_pc_guard_init(uint32_t *start,
                                         uint32_t *stop) {
    static uint64_t N;
    if (start == stop || *start) return;
    printf("INIT: %p %p\n", start, stop);
    for (uint32_t *x = start; x < stop; x++)
        *x = ++N;
}

void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {
    if (!*guard) return;
    void *PC = __builtin_return_address(0);

    //    Dl_info info;
    //    dladdr(PC, &info);
    //    printf("方法名称是:%s\n", info.dli_sname);

    // 创建结构体
    SymboNode *node = malloc(sizeof(SymboNode));
    // 先给node赋值，下个节点暂时先为空
    *node = (SymboNode){PC, NULL};
    // 结构体入栈,node存入symbolList，并把下一个地址给到node的next属性
    OSAtomicEnqueue(&symbolList, node, offsetof(SymboNode, next));
}


@end
