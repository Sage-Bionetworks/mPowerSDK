//
//  APHAppDelegate.swift
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

import Foundation
import BridgeAppSDK
import APCAppCore

extension APHAppDelegate : SBASharedAppDelegate {
    
    public var currentUser: SBAUserWrapper {
        return self.dataSubstrate.currentUser
    }
    
    public var bridgeInfo: SBABridgeInfo {
        return self.bridgeInfoPList
    }
    
    public var requiredPermissions: [SBAPermissionsType] {
        return self.signUpPermissionsTypes().mapAndFilter({ SBAPermissionsType(rawValue: $0.unsignedLongValue) })
    }
    
    public func showAppropriateViewController(animated: Bool) {
        showAppropriateVC()
    }
    
    public func createLocalNotifications() -> [UILocalNotification] {
        // TODO: syoung 05/23/2016 Notification handling needs to be reworked to allow for a more flexible
        // design that is applicable to mPower.
        assertionFailure("Not implemented")
        return []
    }
    
}

extension APCUser : SBAConsentSignatureWrapper {
    
    public var signatureBirthdate: NSDate? {
        get { return birthDate }
        set(newValue) { birthDate = newValue }
    }
    
    public var signatureName: String? {
        get { return consentSignatureName }
        set(newValue) { consentSignatureName = newValue }
    }
    
    public var signatureImage: UIImage?  {
        get {
            guard let data = consentSignatureImage else { return nil }
            return UIImage(data: data)
        }
        set(newValue) {
            guard let image = newValue else { return }
            consentSignatureImage = UIImagePNGRepresentation(image)
        }
    }
    
    public var signatureDate: NSDate? {
        get { return consentSignatureDate }
        set(newValue) { consentSignatureDate = newValue }
    }
    
}

extension APCUser : SBAUserWrapper {
    
    public var bridgeInfo: SBABridgeInfo? {
        return APHAppDelegate.sharedAppDelegate().bridgeInfoPList
    }
    
    public var consentSignature: SBAConsentSignatureWrapper? {
        get {
            guard userConsented else { return nil }
            return self
        }
        set(newValue) {
            if let signature = newValue {
                userConsented = true
                self.signatureName = signature.signatureName
                self.signatureImage = signature.signatureImage
                self.signatureDate = signature.signatureDate
                self.signatureBirthdate = signature.signatureBirthdate
            }
            else {
                userConsented = false
                self.signatureName = nil
                self.signatureImage = nil
                self.signatureDate = nil
                self.signatureBirthdate = nil
            }
        }
    }

    public var hasRegistered: Bool {   // signedUp
        get { return signedUp }
        set(newValue) { signedUp = newValue }
    }
    
    public var loginVerified: Bool {    // signedIn
        get { return signedIn }
        set(newValue) { signedIn = newValue }
    }

    public var consentVerified: Bool {    // consented
        get { return consented }
        set(newValue) { consented = newValue }
    }
    
    public var dataSharingEnabled: Bool {
        get {
            // Sharing is enabled if the saved sharing scope is nil
            return (savedSharingScope == nil)
        }
        set (enabled) {
            if enabled {
                savedSharingScope = nil
            }
            else {
                savedSharingScope = NSNumber(long:APCUserConsentSharingScope.None.rawValue)
            }
        }
    }
    
    public var dataSharingScope: SBBUserDataSharingScope {
        get {
            switch self.sharingScope {
            case .All:
                return .All
            case .Study:
                return .Study
            default:
                return .None
            }
        }
        set (newValue) {
            switch newValue {
            case .All:
                sharedOptionSelection = NSNumber(long:APCUserConsentSharingScope.All.rawValue)
            case .Study:
                sharedOptionSelection = NSNumber(long:APCUserConsentSharingScope.Study.rawValue)
            default:
                sharedOptionSelection = NSNumber(long:APCUserConsentSharingScope.None.rawValue)
            }
        }
    }

    // syoung 05/23/2016 This is not implemented for APCUser. Included for compatibility.
    public var onboardingStepIdentifier: String? {
        get {
            assertionFailure("Not implemented")
            return nil
        }
        set(newValue) {
            assertionFailure("Not implemented")
        }
    }
    
    public func logout() {
        signedUp = false
        signedIn = false
        APCKeychainStore.removeValueForKey(kPasswordKey);
    }
    
}
