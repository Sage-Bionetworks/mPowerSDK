//
//  APHWebviewViewController.m
//  mPowerSDK
//
// Copyright (c) 2015, Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "APHWebviewViewController.h"
@import BridgeAppSDK;

@interface APHWebviewViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webview;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarBottomConstraint;

@property (nonatomic) UIWebView *pdfWebView;
@property (nonatomic) NSURL *pdfURL;
@property (nonatomic, getter=isPrinting) BOOL printing;
@property (nonatomic, getter=isCancelled) BOOL cancelled;

@end

@implementation APHWebviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // set the share button to disabled until the PDF is saved
    self.shareButton.enabled = false;

    // load the viewable webview
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.displayURLString]];
    [self.webview loadRequest:request];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // stop loading and disconnect
    [self.webview stopLoading];
    self.webview.delegate = nil;
    [self.pdfWebView stopLoading];
    self.pdfWebView.delegate = nil;
    
    // cancel save PDF
    self.cancelled = YES;
}

- (void)dealloc {
    // Delete the temp file
    if (_pdfURL) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtURL:_pdfURL error:&error];
        if (error) {
            NSLog(@"Error deleting temp file: %@", error);
        }
    }
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
#if DEBUG
    NSLog(@"shouldStartLoadWithRequest:%@\nnavigationType:%@", request, @(navigationType));
#endif
    // Only should start loading the request if this is an http url.
    // Otherwise, it is intended for messaging
    BOOL isHTTP = [request.URL.absoluteString.lowercaseString hasPrefix:@"http"];
    return isHTTP;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    // Wait until webview is done loading before continuing to next step
    if (webView.isLoading) {
        return;
    }
    
    // If there is a javascript call used to actually load the view then call that
    if (self.javascriptCall) {
        [webView stringByEvaluatingJavaScriptFromString:self.javascriptCall];
    }
    
    // TODO: remove this line once callback is implemented syoung 03/01/2016
    [self webViewDidFinishLoadingData:webView delay:5.0];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    // TODO: handle error more cleanly syoung 03/01/2016
    if (webView ==self.webview) {
        NSString *html = [NSString stringWithFormat:@"<body><p></br>%@</br></p></body>", error.localizedDescription];
        [self.webview loadHTMLString:html baseURL:[NSURL URLWithString:@"http://sagebase.org/"]];
    }
}

#pragma mark - Sharing

- (IBAction)shareTapped:(id)sender {

    // Present an activity controller
    NSData *data = [NSData dataWithContentsOfURL:self.pdfURL];
    NSArray *activityItemsArray = @[data, [self sharePrintInfo]];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItemsArray
                                                                                         applicationActivities:nil];
    activityViewController.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (UIPrintInfo *)sharePrintInfo {
    // Create a print info
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.duplex = UIPrintInfoDuplexLongEdge;       // portrait
    NSString *title = self.step.title ?: self.title;
    if (title.length > 0) {
        printInfo.jobName = title;
    }
    return printInfo;
}

#pragma mark - load PDF to a temporary cache
        
- (BOOL)hasPrintableWebView {
    return (self.pdfURLSuffix != nil);
}

- (void)loadPDFToPage {
    // If the pdf URL is different from the display URL then add a hidden webview for the printing
    self.pdfWebView = [[UIWebView alloc] init];
    self.pdfWebView.delegate = self;
    NSString *urlString = [self.displayURLString stringByAppendingString:self.pdfURLSuffix];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    [self.pdfWebView loadRequest:request];
}

- (void)webViewDidFinishLoadingData:(UIWebView *)webView delay:(NSTimeInterval)timeInterval {
    
    if ([self hasPrintableWebView] && (self.pdfWebView != webView)) {
        // If there is a printable url (that is different from the main view)
        // then need to load the PDF URL request.
        [self loadPDFToPage];
    }
    else if (!self.printing && !self.isCancelled) {
        // Otherwise, if not already printing and not cancelled, then save the PDF
        // Note: Use a delay to load the data since otherwise the webview rendering will sometimes
        // crash due to a nil pointer. syoung 03/01/2016
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf savePDFFromWebView:webView];
        });
    }
}

- (void)savePDFFromWebView:(UIWebView*)webView {
    if (self.printing) {
        return;
    }
    self.printing = YES;
    [self trySavePDFFromWebView:webView retryCount:0];
}

- (void)trySavePDFFromWebView:(UIWebView*)webView retryCount:(NSUInteger)retryCount {
    
    if (self.isCancelled || (self.pdfURL != nil)) {
        return;
    }
    
    NSURL *savedPDF = nil;
    @try {
        
        // setup the temporary file
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSString *fileName = [NSString stringWithFormat:@"MonthlyReport_%@.pdf", [dateFormatter stringFromDate:[NSDate date]]];
        NSString *tempDir = NSTemporaryDirectory();
        NSString *filepath = [tempDir stringByAppendingPathComponent:fileName];
        if (![[NSFileManager defaultManager] fileExistsAtPath:tempDir]) {
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:&error];
        }
        savedPDF = [NSURL fileURLWithPath:filepath];
        
        // setup the renderer
        SBAPDFPrintPageRenderer *renderer = [[SBAPDFPrintPageRenderer alloc] init];
        [renderer addPrintFormatter:webView.viewPrintFormatter startingAtPageAtIndex:0];
        
        // Draw to a file
        CGSize pageSize = [renderer pageSize];
        CGRect pageRect = CGRectMake(0, 0, pageSize.width, pageSize.height);
        
        UIGraphicsBeginPDFContextToFile(filepath, pageRect, nil);
        
        NSInteger pages = [renderer numberOfPages];
        [renderer prepareForDrawingPages:NSMakeRange(0, pages)];
        
        for (NSInteger i = 0; i < pages && !self.isCancelled; i++) {
            UIGraphicsBeginPDFPage();
            [renderer drawPageAtIndex:i inRect:renderer.printableRect];
        }
        
        UIGraphicsEndPDFContext();
        
    }
    @catch (NSException *exception) {
        NSLog(@"Error printing: %@", exception);
        
        // retry once
        if (retryCount < 1) {
            __weak typeof(self) weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf trySavePDFFromWebView:webView retryCount:retryCount + 1];
            });
        }
        return;
    }
    
    // Cleanup
    self.pdfURL = savedPDF;
    self.pdfWebView.delegate = nil;
    self.pdfWebView = nil;
    self.printing = NO;
    self.shareButton.enabled = YES;
}

@end
