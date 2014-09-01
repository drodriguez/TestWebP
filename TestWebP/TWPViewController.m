//
//  TWPViewController.m
//  TestWebP
//
//  Created by Daniel Rodríguez Troitiño on 01/09/14.
//  Copyright (c) 2014 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "TWPViewController.h"

#include <mach/mach_time.h>
#import <STWebP/STWebPDecoder.h>

struct TWPBenchmark {
  uint64_t startTime;
  uint64_t endTime;
};

typedef struct TWPBenchmark *TWPBenchmark;

static TWPBenchmark TWPBenchmarkCreate();
static void TWPBenchmarkRelease(TWPBenchmark benchmark);
static void TWPBenchmarkEnter(TWPBenchmark benchmark);
static void TWPBenchmarkLeave(TWPBenchmark benchmark);
static double TWPBenchmarkTime(TWPBenchmark benchmark);


@interface TWPViewController ()

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation TWPViewController

- (void)viewDidLoad {
  self.operationQueue = [[NSOperationQueue alloc] init];
}

- (IBAction)testWebP:(id)sender {
  NSArray *imageURLs = @[[NSURL URLWithString:@"https://www.gstatic.com/webp/gallery/1.webp"],
                         [NSURL URLWithString:@"https://www.gstatic.com/webp/gallery/2.webp"],
                         [NSURL URLWithString:@"https://www.gstatic.com/webp/gallery/3.webp"],
                         [NSURL URLWithString:@"https://www.gstatic.com/webp/gallery/4.webp"],
                         [NSURL URLWithString:@"https://www.gstatic.com/webp/gallery/5.webp"]];

  NSUInteger count = imageURLs.count;
  TWPBenchmark *downloadTime = calloc(sizeof(TWPBenchmark), count);
  TWPBenchmark *decodeTime = calloc(sizeof(TWPBenchmark), count);
  for (int idx = 0; idx < count; idx++) {
    downloadTime[idx] = TWPBenchmarkCreate();
    decodeTime[idx] = TWPBenchmarkCreate();
  }

  dispatch_group_t group = dispatch_group_create();

  [imageURLs enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
    dispatch_group_enter(group);
    TWPBenchmarkEnter(downloadTime[idx]);
    [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
      TWPBenchmarkLeave(downloadTime[idx]);
      // This is, more or less, what STWebPURLProtocol will execute when a webp
      // image is received
      TWPBenchmarkEnter(decodeTime[idx]);
      UIImage *image = [STWebPDecoder imageWithData:data error:NULL];
      NSData *pngData = UIImagePNGRepresentation(image);
      __unused UIImage *pngImage = [UIImage imageWithData:pngData];
      TWPBenchmarkLeave(decodeTime[idx]);
      dispatch_group_leave(group);
    }];
  }];

  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    double totalElapsed = 0, downloadElapsed = 0, decodeElapsed = 0;
    for (int idx = 0; idx < count; idx++) {
      double download = TWPBenchmarkTime(downloadTime[idx]);
      double decode = TWPBenchmarkTime(decodeTime[idx]);
      totalElapsed += download + decode;
      downloadElapsed += download;
      decodeElapsed += decode;
    }

    NSLog(@"WebP: total: %.3f; download: %.3f; decode: %.3f",
          totalElapsed, downloadElapsed, decodeElapsed);

    for (int idx = 0; idx < count; idx++) {
      TWPBenchmarkRelease(downloadTime[idx]);
      TWPBenchmarkRelease(decodeTime[idx]);
    }
  });
}

- (IBAction)testPNG:(id)sender {
  NSArray *imageURLs = @[[NSURL URLWithString:@"https://www.gstatic.com/webp/gallery/1.png"],
                         [NSURL URLWithString:@"https://www.gstatic.com/webp/gallery/2.png"],
                         [NSURL URLWithString:@"https://www.gstatic.com/webp/gallery/3.png"],
                         [NSURL URLWithString:@"https://www.gstatic.com/webp/gallery/4.png"],
                         [NSURL URLWithString:@"https://www.gstatic.com/webp/gallery/5.png"]];

  NSUInteger count = imageURLs.count;
  TWPBenchmark *downloadTime = calloc(sizeof(TWPBenchmark), count);
  TWPBenchmark *decodeTime = calloc(sizeof(TWPBenchmark), count);
  for (int idx = 0; idx < count; idx++) {
    downloadTime[idx] = TWPBenchmarkCreate();
    decodeTime[idx] = TWPBenchmarkCreate();
  }

  dispatch_group_t group = dispatch_group_create();

  [imageURLs enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
    dispatch_group_enter(group);
    TWPBenchmarkEnter(downloadTime[idx]);
    [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
      TWPBenchmarkLeave(downloadTime[idx]);
      TWPBenchmarkEnter(decodeTime[idx]);
      __unused UIImage *pngImage = [UIImage imageWithData:data];
      TWPBenchmarkLeave(decodeTime[idx]);
      dispatch_group_leave(group);
    }];
  }];

  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    double totalElapsed = 0, downloadElapsed = 0, decodeElapsed = 0;
    for (int idx = 0; idx < count; idx++) {
      double download = TWPBenchmarkTime(downloadTime[idx]);
      double decode = TWPBenchmarkTime(decodeTime[idx]);
      totalElapsed += download + decode;
      downloadElapsed += download;
      decodeElapsed += decode;
    }

    NSLog(@"PNG: total: %.3f; download: %.3f; decode: %.3f",
          totalElapsed, downloadElapsed, decodeElapsed);

    for (int idx = 0; idx < count; idx++) {
      TWPBenchmarkRelease(downloadTime[idx]);
      TWPBenchmarkRelease(decodeTime[idx]);
    }
  });
}

@end


static TWPBenchmark TWPBenchmarkCreate() {
  return (TWPBenchmark) malloc(sizeof(struct TWPBenchmark));
}

static void TWPBenchmarkRelease(TWPBenchmark benchmark) {
  free(benchmark);
}

static void TWPBenchmarkEnter(TWPBenchmark benchmark) {
  benchmark->startTime = mach_absolute_time();
}

static void TWPBenchmarkLeave(TWPBenchmark benchmark) {
  benchmark->endTime = mach_absolute_time();
}

static double TWPBenchmarkTime(TWPBenchmark benchmark) {
  // Elapsed time in mach time units
  uint64_t elapsedTime = benchmark->endTime - benchmark->startTime;

  // The first time we get here, ask the system
  // how to convert mach time units to nanoseconds
  static double ticksToNanoseconds = 0.0;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    ticksToNanoseconds = (double)timebase.numer / timebase.denom;
  });

  double elapsedTimeInNanoseconds = elapsedTime * ticksToNanoseconds;
  return elapsedTimeInNanoseconds;
}
