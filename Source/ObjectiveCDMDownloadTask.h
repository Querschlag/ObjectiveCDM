//
//  ObjectiveCDMDownloadTask.h
//  ObjectiveCDM-Example
//
//  Created by James Huynh on 24/5/14.
//
//

#import <Foundation/Foundation.h>
#import "ObjectiveCDM.h"
#import "FileHash.h"

@interface ObjectiveCDMDownloadTask : NSObject {
    FileHashAlgorithm fileHashAlgorithm;
}

@property(nonatomic, assign) float cachedProgress;
@property(nonatomic, assign) BOOL completed;
@property(nonatomic, assign) int64_t totalBytesWritten;
@property(nonatomic, assign) int64_t totalBytesExpectedToWrite;

@property(nonatomic, assign) NSUInteger position;
@property(nonatomic, retain) NSURL* url;
@property(nonatomic, retain) NSString* urlString;
@property(nonatomic, retain) NSString* destination;
@property(nonatomic, retain) NSString* fileName;
@property(nonatomic, retain) NSString* checkSum;
@property(nonatomic, retain) NSError* error;
@property(nonatomic, retain) NSString* lastErrorMessage;
@property(nonatomic, retain) NSString* identifier;
@property(nonatomic, assign) BOOL hasAbsoluteDestination;

- (instancetype) initWithURLString:(NSString *)urlString
                   withDestination:(NSString *)destination
      andTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWriteInput
                       andChecksum:(NSString *)checksum
              andFileHashAlgorithm:(FileHashAlgorithm) fileHashAlgorithmInput
                 andIsAbsolutePath:(BOOL)isAbsoluteDestination NS_DESIGNATED_INITIALIZER;

- (instancetype) initWithURL:(NSURL *)url
             withDestination:(NSString *)destination
andTotalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWriteInput
                 andChecksum:(NSString *)checksum
        andFileHashAlgorithm:(FileHashAlgorithm) fileHashAlgorithmInput
           andIsAbsolutePath:(BOOL)isAbsoluteDestination NS_DESIGNATED_INITIALIZER;

- (void) cleanUp;
- (void) cleanUpWithResumableData:(NSData *)data;
@property (NS_NONATOMIC_IOSONLY, readonly) float downloadingProgress;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL verifyDownload;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *fullErrorDescription;
@property (NS_NONATOMIC_IOSONLY, getter=isHittingErrorBecauseOffline, readonly) BOOL hittingErrorBecauseOffline;
@property (NS_NONATOMIC_IOSONLY, getter=isHittingErrorConnectingToServer, readonly) BOOL hittingErrorConnectingToServer;
- (void) captureReceivedError:(NSError *)error;
@end
