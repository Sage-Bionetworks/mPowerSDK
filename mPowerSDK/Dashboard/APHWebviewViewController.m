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

    // load the viewable webivew
    [self.webview loadRequest:self.displayURLRequest];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // stop loading and disconnect
    [self.webview stopLoading];
    self.webview.delegate = nil;
    [self.pdfWebView stopLoading];
    self.pdfWebView.delegate = nil;
    
    // remove the temp file
    self.cancelled = YES;
    if (!self.printing) {
        [self deleteTempPDFFile];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    // Wait until webview is done loading before continuing to next step
    if (webView.isLoading) {
        return;
    }
    
    if ([self hasPrintableWebView] && (self.pdfWebView != webView)) {
        // If there is a printable url (that is different from the main view)
        // then need to load the PDF URL request.
        [self loadPDFToPage];
    }
    else if (!self.printing && !self.isCancelled) {
        // Otherwise, if not already printing and not cancelled, then save the PDF
        [self savePDFFromWebView:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    // TODO: handle error syoung 03/01/2016
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
    return (self.pdfURLRequest != nil) && ![self.pdfURLRequest.URL isEqual:self.displayURLRequest.URL];
}

- (void)loadPDFToPage {
    // If the pdf URL is different from the display URL then add a hidden webview for the printing
    self.pdfWebView = [[UIWebView alloc] init];
    self.pdfWebView.delegate = self;
    [self.pdfWebView loadRequest:self.pdfURLRequest];
}

- (void)savePDFFromWebView:(UIWebView*)webView {
    
    if (self.printing || self.isCancelled || (self.pdfURL != nil)) {
        return;
    }
    self.printing = YES;
    
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
    self.pdfURL = [NSURL fileURLWithPath:filepath];
    
    
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
    
    // Cleanup
    if (self.isCancelled) {
        [self deleteTempPDFFile];
    }
    self.printing = NO;
    
    // Finish webview handling
    self.shareButton.enabled = true;
    self.pdfWebView.delegate = nil;
    self.pdfWebView = nil;
}

- (void)deleteTempPDFFile {
    @synchronized(self) {
        if (self.pdfURL) {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtURL:self.pdfURL error:&error];
            if (error) {
                NSLog(@"Error deleting temp file: %@", error);
            }
            self.pdfURL = nil;
        }
    }
}

@end
