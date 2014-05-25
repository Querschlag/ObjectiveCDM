//
//  ObjectiveCDMDownloadBatch.m
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 16/5/14.
//
//

#import "ObjectiveCDMDownloadBatch.h"

@implementation ObjectiveCDMDownloadBatch

- (instancetype) initWithDownloadSession:(NSURLSession *)inputSession andFileHashAlgorithm:(FileHashAlgorithm)fileHashAlgorithmInput {
    self = [super init];
    if(self) {
        downloadInputs = [[NSMutableArray alloc] initWithArray:@[]];
        urls = [[NSMutableArray alloc] initWithArray:@[]];
        session = inputSession;
        fileHashAlgorithm = fileHashAlgorithmInput;
    }//end if
    return self;
}

- (void) addTask:(NSDictionary *)taskInfo {
    NSString *urlString = nil;
    BOOL isURLString = YES;
    if([taskInfo[@"url"] isKindOfClass:[NSURL class]]) {
        urlString = [((NSURL *)taskInfo[@"url"]) absoluteString];
        isURLString = NO;
    }//end if
    else {
        urlString = taskInfo[@"url"];
    }//end else
    
    NSString *destination = taskInfo[@"destination"];
    int64_t totalExpectedToWrite = 0;
    if(taskInfo[@"fileSize"]) {
        totalExpectedToWrite = [(NSNumber *)taskInfo[@"fileSize"] longLongValue];
    }
    if([self isTaskExistWithURL:urlString andDestination:destination] == NO) {
        ObjectiveCDMDownloadTask *downloadTask = nil;
        if(isURLString) {
            downloadTask = [[ObjectiveCDMDownloadTask alloc]
                                initWithURLString:urlString
                                  withDestination:destination
                    andTotalBytesExepectedToWrite:totalExpectedToWrite
                                      andChecksum:taskInfo[@"checksum"]
                              andFileHashAlgorithm:fileHashAlgorithm];
        } else {
            downloadTask = [[ObjectiveCDMDownloadTask alloc]
                            initWithURLString:taskInfo[@"url"]
                              withDestination:destination
                andTotalBytesExepectedToWrite:totalExpectedToWrite
                                  andChecksum:taskInfo[@"checksum"]
                         andFileHashAlgorithm:fileHashAlgorithm];
;
        }//end else
        if(taskInfo[@"identifier"]) {
            downloadTask.identifier = taskInfo[@"identifier"];
        }//end if
        downloadTask.position = [downloadInputs count];
        [urls addObject:urlString];
        [downloadInputs addObject:downloadTask];
    }//end if
}

- (BOOL) isTaskExistWithURL:(NSString *)urlString andDestination:(NSString *)destination {
    return [urls indexOfObject:urlString] != NSNotFound;
}

- (BOOL) handleDownloadedFileAt:(NSURL *)downloadedFileLocation forDownloadURL:(NSString *)downloadURL {
    NSError *movingFileError;
    ObjectiveCDMDownloadTask *downloadTaskInfo = [self downloadInfoOfTaskUrl:downloadURL];
    NSString *destinationPath = downloadTaskInfo.destination;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    [fileManager moveItemAtPath:downloadedFileLocation.path toPath:destinationPath error:&movingFileError];
    
    if(movingFileError) {
        NSLog(@"Error: %@", movingFileError.localizedDescription);
        return NO;
    } else {
        BOOL isVerified = [downloadTaskInfo verifyDownload];
        if(isVerified) {
            [self updateCompleteStatus];
        }//end if
        return isVerified;
    }//end else
}

- (ObjectiveCDMDownloadTask *) captureDownloadingInfoOfDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    // task is already inside the session - do nothing
    NSURL *url = downloadTask.originalRequest.URL;
    ObjectiveCDMDownloadTask *downloadTaskInfo = [self downloadInfoOfTaskUrl:url.absoluteString];
    downloadTaskInfo.totalBytesWritten = downloadTask.countOfBytesReceived;

    if(downloadTaskInfo.totalBytesExpectedToWrite == 0) {
        downloadTaskInfo.totalBytesExpectedToWrite = downloadTask.countOfBytesExpectedToReceive;
    }//end if
    
    return downloadTaskInfo;
}

- (ObjectiveCDMDownloadTask *) updateProgressOfDownloadURL:(NSString *)url withProgress:(float)percentage withTotalBytesWritten:(int64_t)totalBytesWritten {
    ObjectiveCDMDownloadTask *downloadTask = [self downloadInfoOfTaskUrl:url];
    downloadTask.totalBytesWritten = totalBytesWritten;
    
    return downloadTask;
}

- (NSArray *)downloadObjects {
    return downloadInputs;
}

- (ObjectiveCDMDownloadTask *)downloadInfoOfTaskUrl:(NSString *)url {
    return downloadInputs[[urls indexOfObject:url]];
}

- (void)startDownloadTask:(ObjectiveCDMDownloadTask *)downloadTaskInfo {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:downloadTaskInfo.url];
    if(downloadTaskInfo.totalBytesExpectedToWrite == 0) {
        [self requestForTotalBytesForURL:downloadTaskInfo.url withCallback:^(int64_t totalBytesToBeReceived)  {
            downloadTaskInfo.totalBytesExpectedToWrite = totalBytesToBeReceived;            
            [self downloadRequest:request ofTask:downloadTaskInfo];
        }];
    } else {
        [self downloadRequest:request ofTask:downloadTaskInfo];
    }//end else
}

- (void) downloadRequest:(NSMutableURLRequest *)request ofTask:(ObjectiveCDMDownloadTask *)downloadTaskInfo {
    [request setTimeoutInterval:90.0];
    if(downloadTaskInfo.error) {
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithResumeData:downloadTaskInfo.error.userInfo[NSURLSessionDownloadTaskResumeData]];
        [downloadTask resume];
        downloadTaskInfo.error = nil;
    } else {
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
        [downloadTask resume];
    }//end else
    
}

- (void) requestForTotalBytesForURL:(NSURL *)url withCallback:(void (^)(int64_t))completed {
    NSMutableURLRequest *headRequest = [[NSMutableURLRequest alloc] initWithURL:url];
    [headRequest setValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
    [headRequest setHTTPMethod:@"HEAD"];
    NSURLSession *sharedSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *headTask = [sharedSession dataTaskWithRequest:headRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        completed(response.expectedContentLength);
    }];
    [headTask resume];
}

- (NSDictionary *) totalBytesWrittenAndReceived {
    int64_t totalDownloadedBytes = 0;
    int64_t totalBytesExpectedToReceive = 0;
    for(ObjectiveCDMDownloadTask *downloadTaskInfo in downloadInputs) {
        totalDownloadedBytes += downloadTaskInfo.totalBytesWritten;
        totalBytesExpectedToReceive += downloadTaskInfo.totalBytesExpectedToWrite;
    }//end for
    
    return @{
        @"totalDownloadedBytes": [NSNumber numberWithLongLong:totalDownloadedBytes],
        @"totalToBeReceivedBytes": [NSNumber numberWithLongLong:totalBytesExpectedToReceive]
    };
}

- (void) updateCompleteStatus {
    for(ObjectiveCDMDownloadTask *task in downloadInputs) {
        // any incompleted task will mark the batch's completed as no and return
        if(task.completed == NO) {
            self.completed = NO;
            return;
        }//end if
    }//end for
    
    self.completed = YES;
}

- (void) continueAllInCompletedDownloadTask {
    for(ObjectiveCDMDownloadTask *downloadTask in downloadInputs) {
        if(downloadTask.completed == NO) {
            [self startDownloadTask:downloadTask];
        }//end if
    }
}

- (void) resumeAllSuspendedTasks {
    
    [session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for(NSURLSessionDownloadTask *downloadTask in downloadTasks) {
            NSString *urlString = downloadTask.originalRequest.URL.absoluteString;
            if([self downloadInfoOfTaskUrl:urlString]) {
                if(downloadTask.state == NSURLSessionTaskStateSuspended) {
                    [downloadTask resume];
                }//end if
            }//end if
        }//end for
    }];

}

- (void) suspendAllOnGoingDownloadTask {
    [session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for(NSURLSessionDownloadTask *downloadTask in downloadTasks) {
            NSString *urlString = downloadTask.originalRequest.URL.absoluteString;
            if([self downloadInfoOfTaskUrl:urlString]) {
                if(downloadTask.state == NSURLSessionTaskStateRunning) {
                    [downloadTask suspend];
                }//end if
            }//end if
        }//end for
    }];
}

@end
