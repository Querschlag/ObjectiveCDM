//
//  ObjectiveCDMDownloadBatch.h
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 16/5/14.
//
//


#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, FileHashAlgorithm) {
    FileHashAlgorithmMD5 = 1,
    FileHashAlgorithmSHA1 = 2,
    FileHashAlgorithmSHA512 = 3
};


typedef NS_OPTIONS(NSUInteger, ObjectiveCDMDownloadTaskStatus) {
    kUnitStringBinaryUnits     = 1 << 0,
    kUnitStringOSNativeUnits   = 1 << 1,
    kUnitStringLocalizedFormat = 1 << 2
};

@class ObjectiveCDMDownloadTask;

#import "ObjectiveCDM.h"
#import "ObjectiveCDMDownloadTask.h"

@interface ObjectiveCDMDownloadBatch : NSObject {
    NSMutableArray *downloadInputs;
    NSMutableArray *urls;
    NSURLSession *session;
    FileHashAlgorithm fileHashAlgorithm;
    int64_t numberOfBytesDownloadedSinceStart;
    NSDate *startTime;
}

@property(nonatomic, assign) BOOL completed;

- (instancetype) initWithFileHashAlgorithm:(FileHashAlgorithm)fileHashAlgorithmInput NS_DESIGNATED_INITIALIZER;
- (ObjectiveCDMDownloadTask *) addTask:(NSDictionary *)taskInfo;
- (BOOL) handleDownloadedFileAt:(NSURL *)downloadedFileLocation forDownloadURL:(NSString *)downloadURL;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *downloadObjects;
- (void) setDownloadingSessionTo:(NSURLSession *)inputSession;
- (ObjectiveCDMDownloadTask *)downloadInfoOfTaskUrl:(NSString *)url;

- (void) updateCompleteStatus;
- (ObjectiveCDMDownloadTask *) updateProgressOfDownloadURL:(NSString *)url withProgress:(float)percentage withTotalBytesWritten:(int64_t)totalBytesWritten;
- (ObjectiveCDMDownloadTask *) captureDownloadingInfoOfDownloadTask:(NSURLSessionDownloadTask *)downloadTask;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDictionary *totalBytesWrittenAndReceived;
- (void) startDownloadTask:(ObjectiveCDMDownloadTask *)downloadTaskInfo;
- (void) continueAllInCompletedDownloadTask;
- (void) suspendAllOnGoingDownloadTask;
- (void) resumeAllSuspendedTasks;
@property (NS_NONATOMIC_IOSONLY, getter=isDownloading, readonly) BOOL downloading;
- (void) redownloadRequestOfTask:(ObjectiveCDMDownloadTask *)downloadTaskInfo;

@property (NS_NONATOMIC_IOSONLY, readonly) int64_t downloadRate;
@property (NS_NONATOMIC_IOSONLY, readonly) double elapsedSeconds;
@end
