/*
 * Copyright (c) Microsoft. All rights reserved.
 * Licensed under the MIT license.
 *
 * Project Oxford: http://ProjectOxford.ai
 *
 * ProjectOxford SDK Github:
 * https://github.com/Microsoft/ProjectOxford-ClientSDK
 *
 * Copyright (c) Microsoft Corporation
 * All rights reserved.
 *
 * MIT License:
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include "precomp.h"

@interface ViewController (/*private*/)

@property (nonatomic, readonly)  NSString*               subscriptionKey;
@property (nonatomic, readonly)  NSString*               luisAppId;
@property (nonatomic, readonly)  NSString*               luisSubscriptionID;
@property (nonatomic, readonly)  NSString*               authenticationUri;
@property (nonatomic, readonly)  bool                    useMicrophone;
@property (nonatomic, readonly)  bool                    wantIntent;
@property (nonatomic, readonly)  SpeechRecognitionMode   mode;
@property (nonatomic, readonly)  NSString*               defaultLocale;
@property (nonatomic, readonly)  NSString*               shortWaveFile;
@property (nonatomic, readonly)  NSString*               longWaveFile;
@property (nonatomic, readonly)  NSDictionary*           settings;
@property (nonatomic, readwrite) NSArray*                buttonGroup;
@property (nonatomic, readonly)  NSUInteger              modeIndex;

@end

NSString* ConvertSpeechRecoConfidenceEnumToString(Confidence confidence);
NSString* ConvertSpeechErrorToString(int errorCode);

/**
 * The Main App ViewController
 */
@implementation ViewController


/**
 * Gets or sets subscription key
 */
-(NSString*)subscriptionKey {
    return [self.settings objectForKey:(@"primaryKey")];
}

/**
 * Gets the LUIS application identifier.
 * @return The LUIS application identifier.
 */
-(NSString*)luisAppId {
    return [self.settings objectForKey:(@"luisAppID")];
}

/**
 * Gets the LUIS subscription identifier.
 * @return The LUIS subscription identifier.
 */
-(NSString*)luisSubscriptionID {
    return [self.settings objectForKey:(@"luisSubscriptionID")];
}

/**
 * Gets the Cognitive Service Authentication Uri.
 * @return The Cognitive Service Authentication Uri.  Empty if the global default is to be used.
 */
-(NSString*)authenticationUri {
    return [self.settings objectForKey:(@"authenticationUri")];
}

/**
 * Gets a value indicating whether or not to use the microphone.
 * @return true if [use microphone]; otherwise, false.
 */
-(bool)useMicrophone {
    auto index = self.modeIndex;
    return index < 3;
}

/**
 * Gets a value indicating whether LUIS results are desired.
 * @return true if LUIS results are to be returned otherwise, false.
 */
-(bool)wantIntent {
    NSLog(@"wantIntent");
    auto index = self.modeIndex;
    return index == 2 || index == 5;
}

/**
 * Gets the current speech recognition mode.
 * @return The speech recognition mode.
 */
-(SpeechRecognitionMode)mode {
    auto index = self.modeIndex;
    if (index == 1 || index == 4) {
        return SpeechRecognitionMode_LongDictation;
    }

    return SpeechRecognitionMode_ShortPhrase;
}

/**
 * Gets the default locale.
 * @return The default locale.
 */
-(NSString*)defaultLocale {
    return @"en-us";
}

/**
 * Gets the short wave file path.
 * @return The short wave file.
 */
-(NSString*)shortWaveFile {
    return @"whatstheweatherlike";
}

/**
 * Gets the long wave file path.
 * @return The long wave file.
 */
-(NSString*)longWaveFile {
    return @"batman";
}

/**
 * Gets the current bundle settings.
 * @return The settings dictionary.
 */
-(NSDictionary*)settings {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"settings" ofType:@"plist"];
    NSDictionary* settings = [[NSDictionary alloc] initWithContentsOfFile:path];
    return settings;
}


/**
 * Initialization to be done when app starts.
 */ 
-(void)viewDidLoad {
    [super viewDidLoad];

//    self.buttonGroup = [[NSArray alloc] initWithObjects:micRadioButton,
//                                                        micDictationRadioButton,
//                                                        micIntentRadioButton,
//                                                        dataShortRadioButton,
//                                                        dataLongRadioButton,
//                                                        dataShortIntentRadioButton,
//                                                            nil];
    [self.quoteText setHidden:false];
    textOnScreen = [NSMutableString stringWithCapacity: 1000];
}


/**
 * Handles the Click event of the startButton control.
 * @param sender The event sender
 */
-(IBAction)StartButton_Click:(id)sender {
    NSLog(@"StartButton_Click!!!");
    [textOnScreen setString:(@"")];
    [self setText: textOnScreen];
    [[self startButton] setEnabled:NO];
    

    [self logRecognitionStart];

    if (self.useMicrophone) {
        if (micClient == nil) {
            if (!self.wantIntent) {
                micClient = [SpeechRecognitionServiceFactory createMicrophoneClient:(self.mode)
                                                                       withLanguage:(self.defaultLocale)
                                                                            withKey:(self.subscriptionKey)
                                                                       withProtocol:(self)];
            }
            else {
                micClient = [SpeechRecognitionServiceFactory createMicrophoneClientWithIntent:(self.defaultLocale)
                                                                                      withKey:(self.subscriptionKey)
                                                                                withLUISAppID:(self.luisAppId)
                                                                               withLUISSecret:(self.luisSubscriptionID)
                                                                                 withProtocol:(self)];
            }

            micClient.AuthenticationUri = self.authenticationUri;
        }

        OSStatus status = [micClient startMicAndRecognition];
        if (status) {
            [self WriteLine:[[NSString alloc] initWithFormat:(@"Error starting audio. %@"), ConvertSpeechErrorToString(status)]];
        }
    }
    else {
        if (nil == dataClient) {
            if (!self.wantIntent) { 
                dataClient = [SpeechRecognitionServiceFactory createDataClient:(self.mode)
                                                                  withLanguage:(self.defaultLocale)
                                                                       withKey:(self.subscriptionKey)
                                                                  withProtocol:(self)];
            }
            else {
                dataClient = [SpeechRecognitionServiceFactory createDataClientWithIntent:(self.defaultLocale)
                                                                                 withKey:(self.subscriptionKey)
                                                                           withLUISAppID:(self.luisAppId)
                                                                          withLUISSecret:(self.luisSubscriptionID)
                                                                            withProtocol:(self)];
            }

            dataClient.AuthenticationUri = self.authenticationUri;
        }

    }
}

/**
 * Logs the recognition start.
 */
-(void)logRecognitionStart {
    NSString* recoSource;
    if (self.useMicrophone) {
        recoSource = @"microphone";
    } else if (self.mode == SpeechRecognitionMode_ShortPhrase) {
        recoSource = @"short wav file";
    } else {
        recoSource = @"long wav file";
    }

}


/**
 * Called when a final response is received.
 * @param response The final result.
 */
-(void)onFinalResponseReceived:(RecognitionResult*)response {
    bool isFinalDicationMessage = self.mode == SpeechRecognitionMode_LongDictation &&
                                                (response.RecognitionStatus == RecognitionStatus_EndOfDictation ||
                                                 response.RecognitionStatus == RecognitionStatus_DictationEndSilenceTimeout);
    if (nil != micClient && self.useMicrophone && ((self.mode == SpeechRecognitionMode_ShortPhrase) || isFinalDicationMessage)) {
        // we got the final result, so it we can end the mic reco.  No need to do this
        // for dataReco, since we already called endAudio on it as soon as we were done
        // sending all the data.
        [micClient endMicAndRecognition];
    }

    if ((self.mode == SpeechRecognitionMode_ShortPhrase) || isFinalDicationMessage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self startButton] setEnabled:YES];
        });
    }
    
    if (!isFinalDicationMessage) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            [self WriteLine:(response.RecognizedPhrase[0])];
            RecognizedPhrase* phrase = response.RecognizedPhrase[0];
            
            NSDictionary *dataToSend = [NSDictionary dictionaryWithObjectsAndKeys:
                                        phrase.DisplayText, @"query", nil];
            
            [self placePostRequestWithURL:@"https://40cb4d46.ngrok.io/api/intent"
                                 withData:dataToSend
                              withHandler:^(NSURLResponse *response, NSData *rawData, NSError *error) {
                                  NSString *string = [[NSString alloc] initWithData:rawData
                                                                           encoding:NSUTF8StringEncoding];
                                  
                                  NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                                  NSInteger code = [httpResponse statusCode];
                                  NSLog(@"%ld", (long)code);
                                  
                                  if (!(code >= 200 && code < 300)) {
                                      NSLog(@"ERROR (%ld): %@", (long)code, string);
                                  } else {
                                      NSLog(@"OK");
                                      
                                      NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                                                              string, @"id", nil];
                                  }
                              }];

            [self WriteLine:(@"")];
        });
    }
}

/**
 * Called when a final response is received and its intent is parsed 
 * @param result The intent result.
 */
-(void)onIntentReceived:(IntentResult*) result {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self WriteLine:(@"--- Intent received by onIntentReceived ---")];
        [self WriteLine:(result.Body)];
        [self WriteLine:(@"")];
    });
}

-(void)placePostRequestWithURL:(NSString *)action withData:(NSDictionary *)dataToSend withHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *error))ourBlock {
    NSString *urlString = [NSString stringWithFormat:@"%@", action];
    NSLog(@"%@", urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataToSend options:0 error:&error];
    
    NSString *jsonString;
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        NSData *requestData = [NSData dataWithBytes:[jsonString UTF8String] length:[jsonString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
        
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody: requestData];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:ourBlock];
    }
}
- (NSString *) getDataFrom:(NSString *)url{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
    
    NSError *error = nil;
    NSHTTPURLResponse *responseCode = nil;
    
    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    
    if([responseCode statusCode] != 200){
        NSLog(@"Error getting %@, HTTP status code %i", url, [responseCode statusCode]);
        return nil;
    }
    
    return [[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding];
}

/**
 * Called when a partial response is received
 * @param response The partial result.
 */
-(void)onPartialResponseReceived:(NSString*) response {
}

/**
 * Called when an error is received
 * @param errorMessage The error message.
 * @param errorCode The error code.  Refer to SpeechClientStatus for details.
 */
-(void)onError:(NSString*)errorMessage withErrorCode:(int)errorCode {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self startButton] setEnabled:YES];
        [self WriteLine:(@"--- Error received by onError ---")];
        [self WriteLine:[[NSString alloc] initWithFormat:(@"%@ %@"), errorMessage, ConvertSpeechErrorToString(errorCode)]];
        [self WriteLine:@""];
    });
}

/**
 * Called when the microphone status has changed.
 * @param recording The current recording state
 */
-(void)onMicrophoneStatus:(Boolean)recording {
    if (!recording) {
        [micClient endMicAndRecognition];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!recording) {
            [[self startButton] setEnabled:YES];
        }
    });
}

/**
 * Callback invoked when the speaker status changes
 * @param speaking A flag indicating whether the speaker output is enabled
*/
-(void)onSpeakerStatus:(Boolean)speaking
{

}


/**
 * Writes the line.
 * @param text The line to write.
 */
-(void)WriteLine:(NSString*)text {
    [textOnScreen appendString:(text)];
    [textOnScreen appendString:(@"\n")];
    [self setText:textOnScreen];
}


/**
 * Converts an integer error code to an error string.
 * @param errorCode The error code
 * @return The string representation of the error code.
 */
NSString* ConvertSpeechErrorToString(int errorCode) {
    switch ((SpeechClientStatus)errorCode) {
        case SpeechClientStatus_SecurityFailed:         return @"SpeechClientStatus_SecurityFailed";
        case SpeechClientStatus_LoginFailed:            return @"SpeechClientStatus_LoginFailed";
        case SpeechClientStatus_Timeout:                return @"SpeechClientStatus_Timeout";
        case SpeechClientStatus_ConnectionFailed:       return @"SpeechClientStatus_ConnectionFailed";
        case SpeechClientStatus_NameNotFound:           return @"SpeechClientStatus_NameNotFound";
        case SpeechClientStatus_InvalidService:         return @"SpeechClientStatus_InvalidService";
        case SpeechClientStatus_InvalidProxy:           return @"SpeechClientStatus_InvalidProxy";
        case SpeechClientStatus_BadResponse:            return @"SpeechClientStatus_BadResponse";
        case SpeechClientStatus_InternalError:          return @"SpeechClientStatus_InternalError";
        case SpeechClientStatus_AuthenticationError:    return @"SpeechClientStatus_AuthenticationError";
        case SpeechClientStatus_AuthenticationExpired:  return @"SpeechClientStatus_AuthenticationExpired";
        case SpeechClientStatus_LimitsExceeded:         return @"SpeechClientStatus_LimitsExceeded";
        case SpeechClientStatus_AudioOutputFailed:      return @"SpeechClientStatus_AudioOutputFailed";
        case SpeechClientStatus_MicrophoneInUse:        return @"SpeechClientStatus_MicrophoneInUse";
        case SpeechClientStatus_MicrophoneUnavailable:  return @"SpeechClientStatus_MicrophoneUnavailable";
        case SpeechClientStatus_MicrophoneStatusUnknown:return @"SpeechClientStatus_MicrophoneStatusUnknown";
        case SpeechClientStatus_InvalidArgument:        return @"SpeechClientStatus_InvalidArgument";
    }

    return [[NSString alloc] initWithFormat:@"Unknown error: %d\n", errorCode];
}

/**
 * Converts a Confidence value to a string
 * @param confidence The confidence value.
 * @return The string representation of the confidence enumeration.
 */
NSString* ConvertSpeechRecoConfidenceEnumToString(Confidence confidence) {
    switch (confidence) {
        case SpeechRecoConfidence_None:
            return @"None";

        case SpeechRecoConfidence_Low:
            return @"Low";

        case SpeechRecoConfidence_Normal:
            return @"Normal";

        case SpeechRecoConfidence_High:
            return @"High";
    }
}


/**
 * Action for low memory
 */
-(void)didReceiveMemoryWarning {
#if !defined(TARGET_OS_MAC)
    [super didReceiveMemoryWarning];
#endif
}

/**
 * Appends text to the edit control.
 * @param text The text to set.
 */
- (void)setText:(NSString*)text {
    UNIVERSAL_TEXTVIEW_SETTEXT(self.quoteText, text);
    [self.quoteText scrollRangeToVisible:NSMakeRange([text length] - 1, 1)]; 
}

@end
