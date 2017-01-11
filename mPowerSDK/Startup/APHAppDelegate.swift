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

extension APHAppDelegate : SBABridgeAppSDKDelegate {
    
    public var currentUser: SBAUserWrapper {
        return self.dataSubstrate.currentUser
    }
    
    public var bridgeInfo: SBABridgeInfo {
        return self.bridgeInfoPList
    }
    
    public func showAppropriateViewController(animated: Bool) {
        assertionFailure("Not implemented")
    }
    
    public func presentViewController(_ viewController: UIViewController,
                               animated: Bool,
                               completion: (() -> Void)?){
        assertionFailure("Not implemented")
    }
    
}

extension APCUser : SBAConsentSignatureWrapper {
    
    public var signatureBirthdate: Date? {
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
    
    public var signatureDate: Date? {
        get { return consentSignatureDate }
        set(newValue) { consentSignatureDate = newValue }
    }
    
}

extension APCUser : SBAUserWrapper {

    public var bridgeInfo: SBABridgeInfo? {
        return APHAppDelegate.shared().bridgeInfoPList
    }
    
    public var consentSignature: SBAConsentSignatureWrapper? {
        get {
            guard isUserConsented else { return nil }
            return self
        }
        set(newValue) {
            if let signature = newValue {
                isUserConsented = true
                self.signatureName = signature.signatureName
                self.signatureImage = signature.signatureImage
                self.signatureDate = signature.signatureDate
                self.signatureBirthdate = signature.signatureBirthdate
            }
            else {
                isUserConsented = false
                self.signatureName = nil
                self.signatureImage = nil
                self.signatureDate = nil
                self.signatureBirthdate = nil
            }
        }
    }

    public var isRegistered: Bool {   // signedUp
        get { return isSignedUp }
        set(newValue) { isSignedUp = newValue }
    }
    
    public var isLoginVerified: Bool {    // signedIn
        get { return isSignedIn }
        set(newValue) { isSignedIn = newValue }
    }

    public var isConsentVerified: Bool {    // consented
        get { return isConsented }
        set(newValue) { isConsented = newValue }
    }
    
    public var isDataSharingEnabled: Bool {
        get {
            // Sharing is enabled if the saved sharing scope is nil
            return (savedSharingScope == nil)
        }
        set (enabled) {
            if enabled {
                savedSharingScope = nil
            }
            else {
                savedSharingScope = NSNumber(value: APCUserConsentSharingScope.none.rawValue as Int)
            }
        }
    }
    
    public var dataSharingScope: SBBParticipantDataSharingScope {
        get {
            switch self.sharingScope {
            case .all:
                return .all
            case .study:
                return .study
            default:
                return .none
            }
        }
        set (newValue) {
            switch newValue {
            case .all:
                sharedOptionSelection = NSNumber(value: APCUserConsentSharingScope.all.rawValue as Int)
            case .study:
                sharedOptionSelection = NSNumber(value: APCUserConsentSharingScope.study.rawValue as Int)
            default:
                sharedOptionSelection = NSNumber(value: APCUserConsentSharingScope.none.rawValue as Int)
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
    
    public var gender: HKBiologicalSex {
        get {
            return self.biologicalSex
        }
        set(newValue) {
            self.biologicalSex = newValue
        }
    }
    
    public var birthdate: Date? {
        get {
            return self.consentSignature?.signatureBirthdate
        }
        set(newValue) {
            self.consentSignature?.signatureBirthdate = newValue
        }
    }
    
    public func resetStoredUserData() {
        logout()
    }

    public func logout() {
        isSignedUp = false
        isSignedIn = false
        APCKeychainStore.removeValue(forKey: kPasswordKey);
    }
    
}
