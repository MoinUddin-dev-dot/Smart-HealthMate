import SwiftUI
import Firebase
import FirebaseAuth
import SwiftData
import PhotosUI // For Photo Library access
import UIKit // For UIImagePickerController
import Observation


// MARK: - 2. SwiftData Models
// Har SwiftData entity mein user ki uid field hogi

// New SwiftData Model for User Settings (Profile, Alert Settings)
@Model
final class UserSettings: Identifiable {
    //    let id: UUID
    @Attribute var userID: String // Link to Firebase user UID
    var userName: String? // User's display name
    @Attribute(.externalStorage) var profileImageData: Data? // For profile picture
    
    // Stores SMAAlertSettings as Data, using Codable conformance
    var alertSettingsData: Data?
    
    // MARK: - Relationships to other user-specific data
    // Delete rule .cascade means if UserSettings is deleted, all associated records are also deleted.
    @Relationship(deleteRule: .cascade, inverse: \Medicine.userSettings)
    var medicines: [Medicine]? = [] // One-to-many relationship with Medicine
    
    @Relationship(deleteRule: .cascade, inverse: \VitalReading.userSettings)
    var vitalReadings: [VitalReading]? = [] // One-to-many relationship with VitalReading
    
    @Relationship(deleteRule: .cascade, inverse: \Reminder.userSettings)
    var reminders: [Reminder]? = [] // One-to-many relationship with Reminder
    
    @Relationship(deleteRule: .cascade, inverse: \ChatMessages.userSettings)
    var chatMessages: [ChatMessages]? = [] // One-to-many relationship with ChatMessages
    
    
    init(userID: String, userName: String? = nil, profileImageData: Data? = nil, alertSettings: SMAAlertSettings? = nil) {
        //        self.id = UUID()
        self.userID = userID
        self.userName = userName
        self.profileImageData = profileImageData
        if let alertSettings = alertSettings {
            self.alertSettingsData = try? JSONEncoder().encode(alertSettings)
        } else {
            // Set default settings if none provided
            self.alertSettingsData = try? JSONEncoder().encode(SMAAlertSettings.defaultSettings)
        }
    }
    
    // Computed property to access SMAAlertSettings
    var alertSettings: SMAAlertSettings {
        get {
            if let data = alertSettingsData,
               let settings = try? JSONDecoder().decode(SMAAlertSettings.self, from: data) {
                return settings
            }
            return SMAAlertSettings.defaultSettings // Provide a default if data is missing or invalid
        }
        set {
            alertSettingsData = try? JSONEncoder().encode(newValue)
            print("alertSettings setter triggered. Data size: \(alertSettingsData?.count ?? 0) bytes")
        }
    }
}

// MARK: - UserDataItem Model (No changes needed, already fine)
@Model
final class UserDataItem: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    var userID: String // This will store Auth.auth().currentUser?.uid
    var title: String
    var timestamp: Date
    
    init(userID: String, title: String, timestamp: Date) {
        //        self.id = UUID()
        self.userID = userID
        self.title = title
        self.timestamp = timestamp
    }
}



// MARK: - SMAAlertSettings Structs (Codable for SwiftData Storage)
struct SMABPThreshold: Codable, Hashable {
    var minSystolic: Int
    var maxSystolic: Int
    var minDiastolic: Int
    var maxDiastolic: Int
}

struct SMASugarThreshold: Codable, Hashable {
    var min: Int
    var max: Int
}

struct SMAAlertSettings: Codable, Hashable {
    var emergencyContacts: [String]
    var bpThreshold: SMABPThreshold
    var fastingSugarThreshold: SMASugarThreshold
    var afterMealSugarThreshold: SMASugarThreshold
    
    // Removed enableEmergencyAlerts, enableReminderAlerts, enableReportAlerts
    
    // Default settings
    static var defaultSettings: SMAAlertSettings {
        SMAAlertSettings(
            emergencyContacts: ["attendant1@example.com", "attendant2@example.com"], // Added default contacts for visibility
            bpThreshold: SMABPThreshold(minSystolic: 90, maxSystolic: 120, minDiastolic: 60, maxDiastolic: 80),
            fastingSugarThreshold: SMASugarThreshold(min: 70, max: 100),
            afterMealSugarThreshold: SMASugarThreshold(min: 70, max: 140)
        )
    }
}



// MARK: - 3. AuthManager (ViewModel for Authentication)
// Yeh class saare Firebase authentication logic ko handle karegi
class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isEmailVerified: Bool = false
    @Published var currentUserUID: String?
    @Published var currentUserDisplayName: String? // New: User's display name
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var resendCooldownActive: Bool = false
    @Published var resendCountdown: Int = 0 // New: Countdown for resend email
    private var lastResendTime: Date?
    private let resendCooldownDuration: TimeInterval = 30 // 30 seconds cooldown (changed from 60)
    private var countdownTimer: Timer?
    
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateDidChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        countdownTimer?.invalidate()
    }
    
    private func setupAuthStateListener() {
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoggedIn = user != nil
                self.isEmailVerified = user?.isEmailVerified ?? false
                self.currentUserUID = user?.uid
                self.currentUserDisplayName = user?.displayName // Get display name
                // If user logs out, reset cooldown and countdown
                if user == nil {
                    self.resendCooldownActive = false
                    self.lastResendTime = nil
                    self.countdownTimer?.invalidate()
                    self.resendCountdown = 0
                }
                print("Auth State Changed: LoggedIn=\(self.isLoggedIn), Verified=\(self.isEmailVerified), UID=\(self.currentUserUID ?? "nil"), DisplayName=\(self.currentUserDisplayName ?? "nil")")
            }
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, username: String) { // Added username
        isLoading = true
        errorMessage = nil
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                if let error = error {
                    // Handle specific error for email already in use
                    if let errorCode = AuthErrorCode(rawValue: error._code) {
                        switch errorCode {
                        case .emailAlreadyInUse:
                            self.errorMessage = "An account with this email already exists. Please try logging in. If your email is not yet verified, you'll be prompted to do so after logging in."
                            print("Signup Error: Email already in use. Guiding user to login.")
                        default:
                            self.errorMessage = error.localizedDescription
                            print("Signup Error: \(error.localizedDescription)")
                        }
                    } else {
                        self.errorMessage = error.localizedDescription
                        print("Signup Error: \(error.localizedDescription)")
                    }
                    return
                }
                
                // If user is created successfully, set display name
                if let user = authResult?.user {
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = username
                    changeRequest.commitChanges { error in
                        DispatchQueue.main.async {
                            if let error = error {
                                print("Error setting display name: \(error.localizedDescription)")
                                self.errorMessage = "Account created, but failed to set username: \(error.localizedDescription)"
                            } else {
                                print("User display name set to: \(username). Sending verification email.")
                                self.errorMessage = "Account created successfully! A verification email has been sent."
                                // After successful signup and display name set, send verification email
                                self.sendVerificationEmail()
                                // User is now logged in but unverified, ContentView will direct to VerifyEmailView
                                self.isLoggedIn = true // Ensure this is set to true
                            }
                        }
                    }
                } else {
                    // This case should ideally not happen if authResult is not nil and error is nil.
                    self.errorMessage = "Account creation successful, but no user object found. Please try logging in."
                    print("Signup successful, but user object was nil.")
                    // Fallback to send verification email if user is somehow nil, and ensure logged in state
                    self.sendVerificationEmail()
                    self.isLoggedIn = true
                }
            }
        }
    }
    
    // MARK: - Send Verification Email
    func sendVerificationEmail() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user logged in to send verification email."
            return
        }
        
        // Check cooldown
        if let lastSend = lastResendTime, Date().timeIntervalSince(lastSend) < resendCooldownDuration {
            let remainingTime = Int(resendCooldownDuration - Date().timeIntervalSince(lastSend))
            errorMessage = "Please wait \(remainingTime) seconds before resending."
            return
        }
        
        isLoading = true
        errorMessage = nil
        user.sendEmailVerification { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("Send Verification Email Error: \(error.localizedDescription)")
                    return
                }
                self.lastResendTime = Date()
                self.resendCooldownActive = true
                self.errorMessage = "Verification email sent! Please check your inbox."
                print("Verification email sent to \(user.email ?? "N/A")")
                
                // Start cooldown timer
                self.resendCountdown = Int(self.resendCooldownDuration)
                self.countdownTimer?.invalidate() // Invalidate any existing timer
                self.countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                    DispatchQueue.main.async {
                        guard let self = self else {
                            timer.invalidate()
                            return
                        }
                        if self.resendCountdown > 0 {
                            self.resendCountdown -= 1
                        } else {
                            self.resendCooldownActive = false
                            timer.invalidate()
                        }
                    }
                }
            }
        }
    }
    
    // New: Send Password Reset Email
        func sendPasswordReset(email: String) {
            isLoading = true
            errorMessage = nil
            Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isLoading = false
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        print("Password Reset Error: \(error.localizedDescription)")
                        return
                    }
                    
                    self.errorMessage = "Password reset email sent! Please check your inbox and spam folder."
                    print("Password reset email sent to \(email)")
                }
            }
        }
    
    // MARK: - Reload User
    // Yeh function user ke latest verification status ko Firebase se fetch karta hai
    func reloadUser() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user logged in to reload."
            return
        }
        isLoading = true
        errorMessage = nil
        user.reload { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("Reload User Error: \(error.localizedDescription)")
                    return
                }
                // Update published properties after reload
                self.isEmailVerified = user.isEmailVerified
                self.currentUserUID = user.uid
                self.currentUserDisplayName = user.displayName // Update display name on reload
                print("User reloaded. isEmailVerified: \(user.isEmailVerified)")
                
                if user.isEmailVerified {
                    self.errorMessage = "Email successfully verified! Please log in again."
                    print("Email verified. Signing out to redirect to login.")
                    self.signOut() // Sign out to force redirect to LoginView
                } else {
                    self.errorMessage = "Email is not yet verified. Please check your inbox."
                }
            }
        }
    }
    
    // MARK: Update User Profile (Display Name)
    func updateDisplayName(newName: String) {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user logged in to update name."
            return
        }
        isLoading = true
        errorMessage = nil
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = newName
        changeRequest.commitChanges { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to update name: \(error.localizedDescription)"
                    print("Error updating display name: \(error.localizedDescription)")
                    return
                }
                self.currentUserDisplayName = newName
                self.errorMessage = "Name updated successfully!"
                print("Display name updated to: \(newName)")
            }
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("Sign In Error: \(error.localizedDescription)")
                    return
                }
                
                guard let user = authResult?.user else {
                    self.errorMessage = "Login failed: No user found."
                    return
                }
                
                // Do NOT sign out if email is not verified.
                // Instead, ContentView will check isEmailVerified and navigate accordingly.
                self.isLoggedIn = true
                self.isEmailVerified = user.isEmailVerified
                self.currentUserUID = user.uid
                self.currentUserDisplayName = user.displayName // Set display name on login
                
                if user.isEmailVerified {
//                    self.errorMessage = "Login successful!"
                    print("User logged in and email verified: \(user.email ?? "N/A")")
                } else {
//                    self.errorMessage = "Login successful, but email is not yet verified. Please check your inbox."
                    print("User logged in but email not verified: \(user.email ?? "N/A")")
                }
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        isLoading = true
        errorMessage = nil
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.isEmailVerified = false
                self.currentUserUID = nil
                self.currentUserDisplayName = nil
                self.isLoading = false
                print("User signed out.")
                
                // MARK: - Call to cancel all notifications
                UNUserNotificationCenter.current().cancelAllScheduledNotifications()
            }
        } catch let signOutError as NSError {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = signOutError.localizedDescription
                print("Error signing out: \(signOutError.localizedDescription)")
            }
        }
    }
}

import UserNotifications

extension UNUserNotificationCenter {
    /// Cancels all pending local notifications scheduled by the app.
    func cancelAllScheduledNotifications() {
        self.removeAllPendingNotificationRequests()
        print("🔔 All pending notifications cleared from UNUserNotificationCenter.")
    }
}

// MARK: - 4. SwiftUI Views

// MARK: - Root View (ContentView)
// Yeh app ka main entry point hoga, jo authentication state ke hisaab se views dikhayega
import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email: String = ""
    @State private var emailError: String? = nil
    @State private var showSuccessModal: Bool = false // New state for success modal
    @Environment(\.dismiss) var dismiss

    // Email validation regex
    private var isValidEmail: Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.7), Color.white.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer()

                VStack(spacing: 5) {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                    Text("HEALTHMATE")
                        .font(.custom("HelveticaNeue-Bold", size: 24))
                        .foregroundColor(.black)
                    Text("YOUR WELLNESS COMPANION")
                        .font(.custom("HelveticaNeue-Light", size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)

                Text("Reset Your Password")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)

                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: email) { _ in
                            emailError = isValidEmail ? nil : "Please enter a valid email address"
                            if authManager.errorMessage != nil {
                                authManager.errorMessage = nil // Clear previous errors
                            }
                            showSuccessModal = false // Reset modal when typing
                        }

                    // Display local email validation error
                    if let emailError = emailError {
                        Text(emailError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    // Display Firebase errors (but not success message)
                    if let errorMessage = authManager.errorMessage, !errorMessage.contains("sent") {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal)

                Button("Send Password Reset Email") {
                    if isValidEmail {
                        authManager.sendPasswordReset(email: email)
                    } else {
                        emailError = "Invalid email format. Please enter a valid email address."
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isValidEmail ? Color.orange : Color.gray)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(!isValidEmail || authManager.isLoading)
                .opacity(authManager.isLoading ? 0.7 : 1.0)

                Button("Back to Login") {
                    dismiss()
                }
                .font(.footnote)
                .foregroundColor(.green)
                .padding(.top, 10)

                Spacer()
            }

            // Custom Success Modal
            if showSuccessModal {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        // Prevent dismissing by tapping outside
                    }

                VStack(spacing: 20) {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)

                    Text("HEALTHMATE")
                        .font(.custom("HelveticaNeue-Bold", size: 20))
                        .foregroundColor(.black)

                    Text("Password Reset Email Sent!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    Text("A password reset email has been sent to \(email). Please check your inbox and spam folder.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("OK") {
                        withAnimation {
                            showSuccessModal = false
                            dismiss() // Return to LoginView
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding()
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(15)
                .shadow(radius: 10)
                .frame(maxWidth: 300)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("Reset Password")
        .navigationBarHidden(true)
        .onChange(of: authManager.errorMessage) { _, newValue in
            if let message = newValue, message.contains("sent") {
                withAnimation {
                    showSuccessModal = true
                    authManager.errorMessage = nil // Clear the message after showing modal
                }
            }
        }
    }
}

// MARK: - SignUpView
struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @Environment(\.dismiss) var dismiss
    
    // Email validation regex
    private var isValidEmail: Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
    
    // Password validation: min 6 chars, 1 number, 1 capital letter
    private var isValidPassword: Bool {
        let passwordRegex = "^(?=.*[A-Z])(?=.*\\d)[A-Za-z\\d]{6,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return predicate.evaluate(with: password)
    }
    
    // Check if form is valid
    private var isFormValid: Bool {
        isValidEmail && isValidPassword && !username.isEmpty
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.7), Color.white.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Spacer()
                
                VStack(spacing: 5) {
                                    // Assuming the image name is "healthmate_logo"
                                    Image("logo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 120, height: 120) // Adjust size as needed

                                    Text("HEALTHMATE")
                                        .font(.custom("HelveticaNeue-Bold", size: 24))
                                        .foregroundColor(.black)

                                    Text("YOUR WELLNESS COMPANION")
                                        .font(.custom("HelveticaNeue-Light", size: 14))
                                        .foregroundColor(.gray)
                                }
                                .padding(.top, 50)
                
                Text("Create New Account")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
//                    .shadow(radius: 5)
                
                VStack(spacing: 15) {
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocapitalization(.words)
//                        .shadow(radius: 3)
                        .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                )
                    
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
//                        .shadow(radius: 3)
                        .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                )
                        .onChange(of: email) { _ in
                            emailError = isValidEmail ? nil : "Please enter a valid email address"
                        }
                    
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
//                        .shadow(radius: 3)
                        .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                )
                        .onChange(of: password) { _ in
                            passwordError = isValidPassword ? nil : "Password must be 6+ characters with 1 number and 1 capital letter"
                        }
                    
                    // Error messages
                    if let emailError = emailError {
                        Text(emailError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    if let passwordError = passwordError {
                        Text(passwordError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    
                }
                .padding(.horizontal)
                
                
                
                Button("Sign Up") {
                    authManager.signUp(email: email, password: password, username: username)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isFormValid ? Color.orange : Color.gray)
                .cornerRadius(10)
                .padding(.horizontal)
//                .shadow(radius: 5)
                .disabled(!isFormValid || authManager.isLoading)
                .opacity(authManager.isLoading ? 0.7 : 1.0)
                
                Button("Already have an account? Log In") {
                    dismiss()
                }
                .font(.footnote)
                .foregroundColor(.green)
                .padding(.top, 10)
                
                Spacer()
                Spacer()
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarHidden(true)
    }
}

// MARK: - VerifyEmailView
struct VerifyEmailView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.7), Color.white.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                Spacer()
                
                Text("Verify Your Email")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
//                    .shadow(radius: 5)
                
                Text("A verification email has been sent to \(Auth.auth().currentUser?.email ?? "your email address"). Please check your inbox and spam folder.")
                    .font(.body)
                    .foregroundColor(.black.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("I've Verified") {
                    authManager.reloadUser()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange)
                .cornerRadius(10)
                .padding(.horizontal)
//                .shadow(radius: 5)
                .disabled(authManager.isLoading)
                .opacity(authManager.isLoading ? 0.7 : 1.0)
                
                Button {
                    authManager.sendVerificationEmail()
                } label: {
                    if authManager.resendCooldownActive {
                        Text("Resend Email in \(authManager.resendCountdown)s")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.7))
                            .cornerRadius(10)
                            .padding(.horizontal)
//                            .shadow(radius: 5)
                    } else {
                        Text("Resend Verification Email")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                            .padding(.horizontal)
//                            .shadow(radius: 5)
                    }
                }
                .disabled(authManager.isLoading || authManager.resendCooldownActive)
                .opacity(authManager.isLoading || authManager.resendCooldownActive ? 0.7 : 1.0)
                
                if authManager.resendCooldownActive {
                    Text("Please wait before resending...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Button("Sign Out") {
                    authManager.signOut()
                }
                .font(.footnote)
                .foregroundColor(.green)
                .padding(.top, 20)
                
                Spacer()
            }
        }
    }
}

// MARK: - LoginView
struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var showForgot = false
    
    // Email validation regex
    private var isValidEmail: Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
    
    // Password validation: min 6 chars, 1 number, 1 capital letter
    private var isValidPassword: Bool {
        let passwordRegex = "^(?=.*[A-Z])(?=.*\\d)[A-Za-z\\d]{6,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return predicate.evaluate(with: password)
    }
    
    // Check if form is valid
    private var isFormValid: Bool {
        isValidEmail && isValidPassword
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.7), Color.white.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    
                    
                    VStack(spacing: 5) {
//                        Text("Hello You")
//                            .font(.largeTitle)
//                            .fontWeight(.bold)
//                            .foregroundColor(.black)
//                            .shadow(radius: 5)
                                        // Assuming the image name is "healthmate_logo"
                                        Image("logo")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 120, height: 120) // Adjust size as needed

                                        Text("HEALTHMATE")
                                            .font(.custom("HelveticaNeue-Bold", size: 24))
                                            .foregroundColor(.black)

                                        Text("YOUR WELLNESS COMPANION")
                                            .font(.custom("HelveticaNeue-Light", size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.top, 50)
                    Text("Login You")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 15) {
                        TextField("Email", text: $email)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
//                            .shadow(radius: 3)
                            .accessibilityIdentifier("usernameField")
                            .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                    )
                            .onChange(of: email) { _ in
                                emailError = isValidEmail ? nil : "Please enter a valid email address"
                            }
                        
                        SecureField("Password", text: $password)
                            .accessibilityIdentifier("passwordField")
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
//                            .shadow(radius: 3)
                            .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                    )
                            .onChange(of: password) { _ in
                                passwordError = isValidPassword ? nil : "Password must be 6+ characters with 1 number and 1 capital letter"
                            }
                        
                        // Error messages
                        if let emailError = emailError {
                            Text(emailError)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        if let passwordError = passwordError {
                            Text(passwordError)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        HStack {
                                                    Spacer()
                                                    NavigationLink(destination: ForgotPasswordView(), isActive: $showForgot) {
                                                        EmptyView()
                                                    }
                                                    Button(action: {
                                                        showForgot = true
                                                    }) {
                                                        Text("Forgot Password?")
                                                            .font(.footnote)
                                                            .foregroundColor(.green)
                                                    }
                                                }
                    }
                    .padding(.horizontal,20)
                    
                    Button("Log In") {
                        authManager.signIn(email: email, password: password)
                    }
                    .accessibilityIdentifier("loginButton")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isFormValid ? Color.orange : Color.gray)
                    .cornerRadius(10)
                    .padding(.horizontal,20)
//                    .shadow(radius: 5)
                    .disabled(!isFormValid || authManager.isLoading)
                    .opacity(authManager.isLoading ? 0.7 : 1.0)
                    
                    NavigationLink(destination: SignUpView(), isActive: $showSignUp) {
                        EmptyView()
                    }
                    Button("Don't have an account? Sign Up") {
                        showSignUp = true
                    }
                    .font(.footnote)
                    .foregroundColor(.green)
                    .padding(.top, 10)
                    
                    Spacer()
                    Spacer()
                }
            }
            .navigationTitle("Login")
            .navigationBarHidden(true)
        }
    }
}

// MARK: - MainContentView (After Successful Login & Verification)
struct MainContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext // SwiftData context
    
    // SwiftData Query for UserDataItem
    @Query private var userItems: [UserDataItem]
    
    // SwiftData Query for UserSettings
    @Query private var userSettingsQuery: [UserSettings]
    
    @State private var newItemTitle: String = ""
    @State private var isShowingProfilePanel: Bool = false // State for side panel visibility
    
    // Computed property for current user's settings, with default if not found
    private var currentUserSettings: UserSettings {
        print("DEBUG: currentUserUID = \(authManager.currentUserUID ?? "nil")")
        
        if let settings = userSettingsQuery.first(where: { $0.userID == authManager.currentUserUID }) {
            print("DEBUG: Found existing settings for userID: \(settings.userID)")
            return settings
        } else {
            let newUID = authManager.currentUserUID ?? "unknown"
            print("DEBUG: Creating new UserSettings with userID: \(newUID)")
            
            let newSettings = UserSettings(userID: newUID, userName: authManager.currentUserDisplayName)
            modelContext.insert(newSettings)
            return newSettings
        }
    }
    
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .leading) { // Use ZStack for side panel
                VStack {
                    HStack {
                        Button {
                            withAnimation(.easeInOut) {
                                isShowingProfilePanel.toggle()
                            }
                        } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.title)
                                .padding(.leading)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        Text("Welcome, \(authManager.currentUserDisplayName ?? Auth.auth().currentUser?.email ?? "User")!")
                            .font(.title)
                            .padding()
                        Spacer()
                    }
                    
                    Text("Your User ID: \(authManager.currentUserUID ?? "N/A")")
                        .font(.subheadline)
                        .padding(.bottom)
                    
                    HStack {
                        TextField("New item title", text: $newItemTitle)
                            .textFieldStyle(.roundedBorder)
                        Button("Add Item") {
                            addItem()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal)
                    
                    List {
                        // Filter SwiftData items based on the current user's UID
                        ForEach(userItems.filter { $0.userID == authManager.currentUserUID }) { item in
                            HStack {
                                Text(item.title)
                                Spacer()
                                Text(item.timestamp, format: .dateTime)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
                .navigationTitle("") // Hide default navigation title
                .navigationBarHidden(true) // Hide default navigation bar
                
                // Profile Side Panel
                if isShowingProfilePanel {
                    UserProfileView(
                        isShowingProfilePanel: $isShowingProfilePanel,
                        authManager: authManager,
                        userSettings: currentUserSettings // Pass the current user's settings
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.75) // 75% of screen width
                    .transition(.move(edge: .leading)) // Slide from left
                    .background(Color.white)
                    .edgesIgnoringSafeArea(.vertical) // Extend to safe area
                    .shadow(radius: 10)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                // Swipe left to dismiss (if dragging from right to left)
                                if value.translation.width < -50 { // Changed to < -50 for left drag
                                    withAnimation(.easeInOut) {
                                        isShowingProfilePanel = false
                                    }
                                }
                            }
                    )
                }
            }
        }
    }
    
    private func addItem() {
        guard !newItemTitle.isEmpty, let uid = authManager.currentUserUID else { return }
        let newItem = UserDataItem(userID: uid, title: newItemTitle, timestamp: Date())
        modelContext.insert(newItem)
        newItemTitle = ""
    }
    
    private func deleteItems(offsets: IndexSet) {
        // Ensure you delete from the filtered list correctly
        let itemsToDelete = offsets.map { userItems.filter { $0.userID == authManager.currentUserUID }[$0] }
        for item in itemsToDelete {
            modelContext.delete(item)
        }
    }
}

// MARK: - UserProfileView (Side Panel)
struct UserProfileView: View {
    @Binding var isShowingProfilePanel: Bool
    @ObservedObject var authManager: AuthManager // Use ObservedObject for AuthManager
    @Bindable var userSettings: UserSettings // Use @Bindable for SwiftData object
    @Environment(\.modelContext) private var modelContext // Inject modelContext here
    @Environment(\.dismiss) private var dismiss // For dismissing the sheet/panel
    
    @State private var selectedPhotosPickerItem: PhotosPickerItem? // For PhotosPicker
    @State private var profileImage: Image?
    @State private var showingImageSourceActionSheet = false // For choosing Camera/Library
    @State private var showingUIImagePicker = false // For UIImagePickerController
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary // Default to photo library
    
    @State private var newUserName: String = ""
    @State private var showingEditNameAlert = false
    
    // State for emergency contact input
    @State private var newContact: String = ""
    
    // Hardcoded absolute min/max limits (to prevent completely unreasonable user inputs)
    private let absoluteMinBP: Int = 40
    private let absoluteMaxBP: Int = 250
    private let absoluteMinSugar: Int = 0
    private let absoluteMaxSugar: Int = 600
    
    // State variables for TextField input (String) for MIN/MAX in SMAEmailAlertsSettingsView
    // These are now directly bound to the userSettings properties, but kept as @State for initial load and validation.
    @State private var minSystolicInput: String = ""
    @State private var maxSystolicInput: String = ""
    @State private var minDiastolicInput: String = ""
    @State private var maxDiastolicInput: String = ""
    @State private var minFastingSugarInput: String = ""
    @State private var maxFastingSugarInput: String = ""
    @State private var minAfterMealSugarInput: String = ""
    @State private var maxAfterMealSugarInput: String = ""
    
    
    // Focus states for each TextField
    public enum Field: Hashable {
        case minSystolic, maxSystolic
        case minDiastolic, maxDiastolic
        case minFastingSugar, maxFastingSugar
        case minAfterMealSugar, maxAfterMealSugar
        case newContactField
    }
    @FocusState public var focusedField: Field?
    
    
    var body: some View {
        NavigationView { // <--- Wrapped in NavigationView for proper safe area handling and toolbar
            ScrollView(showsIndicators: false) { // Use ScrollView for the entire content
                VStack(spacing: 20) { // Add spacing between sections
                    ProfileHeaderView(
                        profileImage: $profileImage,
                        selectedPhotosPickerItem: $selectedPhotosPickerItem,
                        showingImageSourceActionSheet: $showingImageSourceActionSheet,
                        showingUIImagePicker: $showingUIImagePicker,
                        imagePickerSourceType: $imagePickerSourceType,
                        newUserName: $newUserName,
                        showingEditNameAlert: $showingEditNameAlert,
                        authManager: authManager,
                        userSettings: userSettings
                    )
                    // Removed .padding(.top, 80) here as NavigationView handles it
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Replaced Form with a custom VStack for better control and styling
                    VStack(spacing: 20) { // Add spacing between sections
                        // Emergency Contacts Section (Integrated directly)
                        EmergencyContactsContent(
                            userSettings: userSettings,
                            newContact: $newContact,
                            showingEditContactAlert: $showingEditContactAlert,
                            contactToEdit: $contactToEdit,
                            editedContactValue: $editedContactValue,
                            focusedField: _focusedField,
                            authManager: authManager,
                            addEmergencyContact: addEmergencyContact,
                            removeEmergencyContact: removeEmergencyContact,
                            updateEmergencyContact: updateEmergencyContact
                        )
                        .padding(.horizontal) // Apply horizontal padding to the section
                        
                        
                        // BP Thresholds Section (Integrated directly)
                        BPThresholdsContent(
                            userSettings: userSettings,
                            minSystolicInput: $minSystolicInput,
                            maxSystolicInput: $maxSystolicInput,
                            minDiastolicInput: $minDiastolicInput,
                            maxDiastolicInput: $maxDiastolicInput,
                            focusedField: _focusedField,
                            absoluteMinBP: absoluteMinBP,
                            absoluteMaxBP: absoluteMaxBP,
                            validateAndClamp: validateAndClamp
                        )
                        .padding(.horizontal) // Apply horizontal padding to the section
                        
                        // Sugar Thresholds Section (Integrated directly)
                        SugarThresholdsContent(
                            userSettings: userSettings,
                            minFastingSugarInput: $minFastingSugarInput,
                            maxFastingSugarInput: $maxFastingSugarInput,
                            minAfterMealSugarInput: $minAfterMealSugarInput,
                            maxAfterMealSugarInput: $maxAfterMealSugarInput,
                            focusedField: _focusedField,
                            absoluteMinSugar: absoluteMinSugar,
                            absoluteMaxSugar: absoluteMaxSugar,
                            validateAndClamp: validateAndClamp
                        )
                        .padding(.horizontal) // Apply horizontal padding to the section
                        
                    }
                    .padding(.vertical) // Add vertical padding around the entire content block
                    
                    // Sign Out Button (placed outside the custom VStack for better control)
                    Button("Sign Out") {
                        authManager.signOut()
                        withAnimation(.easeInOut) {
                            isShowingProfilePanel = false // Close panel after sign out
                        }
                    }
                    .buttonStyle(.bordered)
                    .padding(.vertical, 20) // Add vertical padding
                } // End VStack
                .padding(.bottom, 20) // Add some padding at the bottom of the scroll view
            } // End ScrollView
            .navigationTitle("Profile") // Set a title for the navigation bar
            .navigationBarTitleDisplayMode(.inline) // Make title smaller
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { // <--- Close button in toolbar
                    Button {
                        withAnimation(.easeInOut) {
                            isShowingProfilePanel = false // Dismiss the panel
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
        } // End NavigationView
        .onAppear {
            // Load existing profile image if available
            if let imageData = userSettings.profileImageData, let uiImage = UIImage(data: imageData) {
                profileImage = Image(uiImage: uiImage)
            }
            // Initialize newUserName from userSettings
            newUserName = userSettings.userName ?? ""
            
            // --- NEW: Ensure default contacts are loaded if the array is empty ---
            if userSettings.alertSettings.emergencyContacts.isEmpty {
                userSettings.alertSettings.emergencyContacts = SMAAlertSettings.defaultSettings.emergencyContacts
                print("UserProfileView: Populated empty contacts with defaults.")
            }
            // --- END NEW ---
            
            loadSettingsToInputFields() // Ensure initial load of thresholds and contacts
        }
        .alert("Edit Contact", isPresented: $showingEditContactAlert) {
            TextField("Email", text: $editedContactValue)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            Button("Update") {
                if !editedContactValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && editedContactValue.contains("@") {
                    updateEmergencyContact(contactToEdit, editedContactValue)
                } else {
                    // Optionally, show an error for invalid email
                    print("Invalid email for update")
                    authManager.errorMessage = "Invalid email format. Please enter a valid email address."
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter the new email address for \(contactToEdit).")
        }
    }
    
    // Helper function for consistent validation logic
    private func validateAndClamp(
        valueString: String,
        currentSetting: Int,
        absoluteMin: Int,
        absoluteMax: Int
    ) -> Int {
        if let doubleValue = Double(valueString) {
            let roundedInt = Int(round(doubleValue))
            // Clamp within absolute bounds
            return max(absoluteMin, min(absoluteMax, roundedInt))
        } else {
            // If input is empty or invalid, return the current valid setting
            return currentSetting
        }
    }
    
    // MARK: Emergency Contact Actions
    @State private var showingEditContactAlert = false
    @State private var contactToEdit: String = ""
    @State private var editedContactValue: String = ""
    
    private func addEmergencyContact() {
        var currentSettings = userSettings.alertSettings // Get a mutable copy
        if !newContact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && newContact.contains("@") {
            currentSettings.emergencyContacts.append(newContact)
            userSettings.alertSettings = currentSettings // Reassign to trigger persistence
            do {
                try modelContext.save() // Explicitly save changes
                print("Emergency contacts saved successfully.")
            } catch {
                print("Error saving emergency contacts: \(error.localizedDescription)")
            }
            newContact = ""
            focusedField = nil // Dismiss keyboard
        } else {
            // Optionally, show an alert for invalid email format
            authManager.errorMessage = "Please enter a valid email address for emergency contact."
        }
    }
    
    private func removeEmergencyContact(_ contact: String) {
        var currentSettings = userSettings.alertSettings // Get a mutable copy
        currentSettings.emergencyContacts.removeAll { $0 == contact }
        userSettings.alertSettings = currentSettings // Reassign to trigger persistence
        do {
            try modelContext.save() // Explicitly save changes
            print("Emergency contacts removed and saved successfully.")
        } catch {
            print("Error removing emergency contacts: \(error.localizedDescription)")
        }
    }
    
    private func updateEmergencyContact(_ oldContact: String, _ newContact: String) {
        var currentSettings = userSettings.alertSettings // Get a mutable copy
        if let index = currentSettings.emergencyContacts.firstIndex(of: oldContact) {
            currentSettings.emergencyContacts[index] = newContact
            userSettings.alertSettings = currentSettings // Reassign to trigger persistence
            do {
                //                try modelContext.save() // Explicitly save changes
                print("Emergency contact updated and saved successfully.")
            } catch {
                print("Error updating emergency contact: \(error.localizedDescription)")
            }
        }
    }
    
    // Function to load settings into TextField states
    private func loadSettingsToInputFields() {
        print("🔍 userSettings.userID: \(userSettings.id)")
        print("🔍 userSettings.userName: \(userSettings.userName)")
        print("🔍 alertSettings: \(userSettings.alertSettings)")
        print("🔍 BP Threshold: \(userSettings.alertSettings.bpThreshold)")
        print("🔍 Sugar Thresholds (fasting/after meal): \(userSettings.alertSettings.fastingSugarThreshold), \(userSettings.alertSettings.afterMealSugarThreshold)")
        print("🔍 Emergency Contacts: \(userSettings.alertSettings.emergencyContacts)")
        
        minSystolicInput = String(userSettings.alertSettings.bpThreshold.minSystolic)
        maxSystolicInput = String(userSettings.alertSettings.bpThreshold.maxSystolic)
        minDiastolicInput = String(userSettings.alertSettings.bpThreshold.minDiastolic)
        maxDiastolicInput = String(userSettings.alertSettings.bpThreshold.maxDiastolic)
        minFastingSugarInput = String(userSettings.alertSettings.fastingSugarThreshold.min)
        maxFastingSugarInput = String(userSettings.alertSettings.fastingSugarThreshold.max)
        minAfterMealSugarInput = String(userSettings.alertSettings.afterMealSugarThreshold.min)
        maxAfterMealSugarInput = String(userSettings.alertSettings.afterMealSugarThreshold.max)
        
        print("✅ Loaded BP: \(minSystolicInput)-\(maxSystolicInput), \(minDiastolicInput)-\(maxDiastolicInput)")
        print("✅ Loaded Sugar: \(minFastingSugarInput)-\(maxFastingSugarInput), \(minAfterMealSugarInput)-\(maxAfterMealSugarInput)")
        print("✅ Loaded Contacts: \(userSettings.alertSettings.emergencyContacts)")
    }
    
}

// MARK: - Sub-Views for UserProfileView Refactoring

struct ProfileHeaderView: View {
    @Binding var profileImage: Image?
    @Binding var selectedPhotosPickerItem: PhotosPickerItem?
    @Binding var showingImageSourceActionSheet: Bool
    @Binding var showingUIImagePicker: Bool
    @Binding var imagePickerSourceType: UIImagePickerController.SourceType
    
    @Binding var newUserName: String
    @Binding var showingEditNameAlert: Bool
    
    @ObservedObject var authManager: AuthManager
    @Bindable var userSettings: UserSettings
    
    // New state to control PhotosPicker presentation directly
    @State private var isPhotosPickerPresented: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Picture
            if let profileImage = profileImage {
                profileImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 2))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }
            
            Button("Change Profile Picture") {
                showingImageSourceActionSheet = true
            }
            .font(.caption)
            .foregroundColor(.blue)
            .confirmationDialog("Select Image Source", isPresented: $showingImageSourceActionSheet) {
                Button("Photo Library") {
                    // PhotosPicker ko is new state variable se control karein
                    isPhotosPickerPresented = true
                }
                Button("Camera") {
                    imagePickerSourceType = .camera
                    showingUIImagePicker = true
                }
            }
            // PhotosPicker tab dikhega jab isPhotosPickerPresented true hoga
            .photosPicker(isPresented: $isPhotosPickerPresented, selection: $selectedPhotosPickerItem, matching: .images)
            .onChange(of: selectedPhotosPickerItem) { oldItem, newItem in // Naye onChange syntax ka upyog
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            profileImage = Image(uiImage: uiImage)
                            userSettings.profileImageData = data // SwiftData mein save karein
                            print("Image selected from PhotosPicker and displayed.")
                        } else {
                            print("Failed to create UIImage from data.")
                        }
                    } else {
                        print("Failed to load transferable data from PhotosPickerItem. newItem: \(String(describing: newItem))")
                    }
                }
            }
            .sheet(isPresented: $showingUIImagePicker) {
                ImagePicker(selectedImage: Binding(
                    get: { nil }, // UIImage ko coordinator mein handle kiya jayega
                    set: { uiImage in
                        if let uiImage = uiImage {
                            profileImage = Image(uiImage: uiImage)
                            userSettings.profileImageData = uiImage.jpegData(compressionQuality: 0.8) // SwiftData mein save karein
                            print("Image selected from Camera and displayed.")
                        } else {
                            print("Failed to get UIImage from camera.")
                        }
                    }
                ), sourceType: imagePickerSourceType)
            }
            
            // User Name
            Text(userSettings.userName ?? "No Name Set")
                .font(.headline)
                .padding(.top, 5)
            
            Button("Edit Name") {
                newUserName = userSettings.userName ?? ""
                showingEditNameAlert = true
            }
            .font(.caption)
            .foregroundColor(.blue)
            .alert("Edit Username", isPresented: $showingEditNameAlert) {
                TextField("Username", text: $newUserName)
                    .autocapitalization(.words)
                Button("Update") {
                    if !newUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        authManager.updateDisplayName(newName: newUserName)
                        userSettings.userName = newUserName
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter your new username.")
            }
        }
    }
}

// MARK: - Dedicated Subviews for Sections (to break down complex views)

import SwiftUI

struct EmergencyContactsContent: View {
    @Bindable var userSettings: UserSettings
    @Binding var newContact: String
    @Binding var showingEditContactAlert: Bool
    @Binding var contactToEdit: String
    @Binding var editedContactValue: String
    @FocusState var focusedField: UserProfileView.Field?
    
    @ObservedObject var authManager: AuthManager
    
    let addEmergencyContact: () -> Void
    let removeEmergencyContact: (String) -> Void
    let updateEmergencyContact: (String, String) -> Void
    
    @State private var emailError: String? = nil
    
    // Email validation regex
    private var isValidEmail: Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: newContact)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Emergency Contacts")
                .font(.headline)
                .padding(.bottom, 5)
            
            // Display existing contacts with interactive elements
            ForEach(userSettings.alertSettings.emergencyContacts, id: \.self) { contact in
                HStack {
                    Text(contact)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Button {
                        contactToEdit = contact
                        editedContactValue = contact
                        showingEditContactAlert = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        removeEmergencyContact(contact)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 5)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        removeEmergencyContact(contact)
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    TextField("Add new contact email", text: $newContact)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: .newContactField)
                        .onChange(of: newContact) { _ in
                            emailError = newContact.isEmpty || isValidEmail ? nil : "Please enter a valid email address"
                        }
                    
                    Button("Add") {
                        addEmergencyContact()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValidEmail || newContact.isEmpty || authManager.isLoading)
                    .opacity((!isValidEmail || newContact.isEmpty || authManager.isLoading) ? 0.7 : 1.0)
                }
                
                // Error message
                if let emailError = emailError {
                    Text(emailError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
            }
        }
        .padding()
    }
}

struct BPThresholdsContent: View {
    @Bindable var userSettings: UserSettings
    @Binding var minSystolicInput: String
    @Binding var maxSystolicInput: String
    @Binding var minDiastolicInput: String
    @Binding var maxDiastolicInput: String
    @FocusState var focusedField: UserProfileView.Field?
    
    let absoluteMinBP: Int
    let absoluteMaxBP: Int
    let validateAndClamp: (String, Int, Int, Int) -> Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Blood Pressure Thresholds (mmHg)")
                .font(.headline)
                .padding(.bottom, 5)
            
            // Systolic Min/Max
            HStack {
                Text("Systolic:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Min", text: $minSystolicInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .minSystolic)
                    .onChange(of: focusedField) { oldValue, newValue in
                        if oldValue == .minSystolic && newValue == nil {
                            var currentSettings = userSettings.alertSettings // Get mutable copy
                            let validatedValue = validateAndClamp(
                                minSystolicInput,
                                currentSettings.bpThreshold.minSystolic,
                                absoluteMinBP,
                                absoluteMaxBP
                            )
                            currentSettings.bpThreshold.minSystolic = min(validatedValue, currentSettings.bpThreshold.maxSystolic)
                            userSettings.alertSettings = currentSettings // Reassign to trigger persistence
                            self.minSystolicInput = String(userSettings.alertSettings.bpThreshold.minSystolic)
                            do {
                                try userSettings.modelContext?.save() // Explicitly save changes
                                print("BP Systolic thresholds saved successfully.")
                            } catch {
                                print("Error saving BP Systolic thresholds: \(error.localizedDescription)")
                            }
                        }
                    }
                Text("-")
                TextField("Max", text: $maxSystolicInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .maxSystolic)
                    .onChange(of: focusedField) { oldValue, newValue in
                        if oldValue == .maxSystolic && newValue == nil {
                            var currentSettings = userSettings.alertSettings // Get mutable copy
                            let validatedValue = validateAndClamp(
                                maxSystolicInput,
                                currentSettings.bpThreshold.maxSystolic,
                                absoluteMinBP,
                                absoluteMaxBP
                            )
                            currentSettings.bpThreshold.maxSystolic = max(validatedValue, currentSettings.bpThreshold.minSystolic)
                            userSettings.alertSettings = currentSettings // Reassign to trigger persistence
                            self.maxSystolicInput = String(userSettings.alertSettings.bpThreshold.maxSystolic)
                            do {
                                try userSettings.modelContext?.save() // Explicitly save changes
                                print("BP Systolic thresholds saved successfully.")
                            } catch {
                                print("Error saving BP Systolic thresholds: \(error.localizedDescription)")
                            }
                        }
                    }
            }
            
            // Diastolic Min/Max
            HStack {
                Text("Diastolic:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Min", text: $minDiastolicInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .minDiastolic)
                    .onChange(of: focusedField) { oldValue, newValue in
                        if oldValue == .minDiastolic && newValue == nil {
                            var currentSettings = userSettings.alertSettings // Get mutable copy
                            let validatedValue = validateAndClamp(
                                minDiastolicInput,
                                currentSettings.bpThreshold.minDiastolic,
                                absoluteMinBP,
                                absoluteMaxBP
                            )
                            currentSettings.bpThreshold.minDiastolic = min(validatedValue, currentSettings.bpThreshold.maxDiastolic)
                            userSettings.alertSettings = currentSettings // Reassign to trigger persistence
                            self.minDiastolicInput = String(userSettings.alertSettings.bpThreshold.minDiastolic)
                            do {
                                try userSettings.modelContext?.save() // Explicitly save changes
                                print("BP Diastolic thresholds saved successfully.")
                            } catch {
                                print("Error saving BP Diastolic thresholds: \(error.localizedDescription)")
                            }
                        }
                    }
                Text("-")
                TextField("Max", text: $maxDiastolicInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .maxDiastolic)
                    .onChange(of: focusedField) { oldValue, newValue in
                        if oldValue == .maxDiastolic && newValue == nil {
                            var currentSettings = userSettings.alertSettings // Get mutable copy
                            let validatedValue = validateAndClamp(
                                maxDiastolicInput,
                                currentSettings.bpThreshold.maxDiastolic,
                                absoluteMinBP,
                                absoluteMaxBP
                            )
                            currentSettings.bpThreshold.maxDiastolic = max(validatedValue, currentSettings.bpThreshold.minDiastolic)
                            userSettings.alertSettings = currentSettings // Reassign to trigger persistence
                            self.maxDiastolicInput = String(userSettings.alertSettings.bpThreshold.maxDiastolic)
                            do {
                                try userSettings.modelContext?.save() // Explicitly save changes
                                print("BP Diastolic thresholds saved successfully.")
                            } catch {
                                print("Error saving BP Diastolic thresholds: \(error.localizedDescription)")
                            }
                        }
                    }
            }
        }
        .padding() // Add padding to the entire section
        // Removed background, cornerRadius, shadow to integrate into the panel
    }
}

struct SugarThresholdsContent: View {
    @Bindable var userSettings: UserSettings
    @Binding var minFastingSugarInput: String
    @Binding var maxFastingSugarInput: String
    @Binding var minAfterMealSugarInput: String
    @Binding var maxAfterMealSugarInput: String
    @FocusState var focusedField: UserProfileView.Field?
    
    let absoluteMinSugar: Int
    let absoluteMaxSugar: Int
    let validateAndClamp: (String, Int, Int, Int) -> Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Blood Sugar Thresholds (mg/dL)")
                .font(.headline)
                .padding(.bottom, 5)
            
            // Fasting Sugar Min/Max
            HStack {
                Text("Fasting:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Min", text: $minFastingSugarInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .minFastingSugar)
                    .onChange(of: focusedField) { oldValue, newValue in
                        if oldValue == .minFastingSugar && newValue == nil {
                            var currentSettings = userSettings.alertSettings // Get mutable copy
                            let validatedValue = validateAndClamp(
                                minFastingSugarInput,
                                currentSettings.fastingSugarThreshold.min,
                                absoluteMinSugar,
                                absoluteMaxSugar
                            )
                            currentSettings.fastingSugarThreshold.min = min(validatedValue, currentSettings.fastingSugarThreshold.max)
                            userSettings.alertSettings = currentSettings // Reassign to trigger persistence
                            self.minFastingSugarInput = String(userSettings.alertSettings.fastingSugarThreshold.min)
                            do {
                                try userSettings.modelContext?.save() // Explicitly save changes
                                print("Fasting sugar thresholds saved successfully.")
                            } catch {
                                print("Error saving fasting sugar thresholds: \(error.localizedDescription)")
                            }
                        }
                    }
                Text("-")
                TextField("Max", text: $maxFastingSugarInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .maxFastingSugar)
                    .onChange(of: focusedField) { oldValue, newValue in
                        if oldValue == .maxFastingSugar && newValue == nil {
                            var currentSettings = userSettings.alertSettings // Get mutable copy
                            let validatedValue = validateAndClamp(
                                maxFastingSugarInput,
                                currentSettings.fastingSugarThreshold.max,
                                absoluteMinSugar,
                                absoluteMaxSugar
                            )
                            currentSettings.fastingSugarThreshold.max = max(validatedValue, currentSettings.fastingSugarThreshold.min)
                            userSettings.alertSettings = currentSettings // Reassign to trigger persistence
                            self.maxFastingSugarInput = String(userSettings.alertSettings.fastingSugarThreshold.max)
                            do {
                                try userSettings.modelContext?.save() // Explicitly save changes
                                print("Fasting sugar thresholds saved successfully.")
                            } catch {
                                print("Error saving fasting sugar thresholds: \(error.localizedDescription)")
                            }
                        }
                    }
            }
            
            // After Meal Sugar Min/Max
            HStack {
                Text("After Meal:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Min", text: $minAfterMealSugarInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .minAfterMealSugar)
                    .onChange(of: focusedField) { oldValue, newValue in
                        if oldValue == .minAfterMealSugar && newValue == nil {
                            var currentSettings = userSettings.alertSettings // Get mutable copy
                            let validatedValue = validateAndClamp(
                                minAfterMealSugarInput,
                                currentSettings.afterMealSugarThreshold.min,
                                absoluteMinSugar,
                                absoluteMaxSugar
                            )
                            currentSettings.afterMealSugarThreshold.min = min(validatedValue, currentSettings.afterMealSugarThreshold.max)
                            userSettings.alertSettings = currentSettings // Reassign to trigger persistence
                            self.minAfterMealSugarInput = String(userSettings.alertSettings.afterMealSugarThreshold.min)
                            do {
                                try userSettings.modelContext?.save() // Explicitly save changes
                                print("After meal sugar thresholds saved successfully.")
                            } catch {
                                print("Error saving after meal sugar thresholds: \(error.localizedDescription)")
                            }
                        }
                    }
                Text("-")
                TextField("Max", text: $maxAfterMealSugarInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .maxAfterMealSugar)
                    .onChange(of: focusedField) { oldValue, newValue in
                        if oldValue == .maxAfterMealSugar && newValue == nil {
                            var currentSettings = userSettings.alertSettings // Get mutable copy
                            let validatedValue = validateAndClamp(
                                maxAfterMealSugarInput,
                                currentSettings.afterMealSugarThreshold.max,
                                absoluteMinSugar,
                                absoluteMaxSugar
                            )
                            currentSettings.afterMealSugarThreshold.max = max(validatedValue, currentSettings.afterMealSugarThreshold.min)
                            userSettings.alertSettings = currentSettings // Reassign to trigger persistence
                            self.maxAfterMealSugarInput = String(userSettings.alertSettings.afterMealSugarThreshold.max)
                            do {
                                try userSettings.modelContext?.save() // Explicitly save changes
                                print("After meal sugar thresholds saved successfully.")
                            } catch {
                                print("Error saving after meal sugar thresholds: \(error.localizedDescription)")
                            }
                        }
                    }
            }
        }
        .padding() // Add padding to the entire section
        // Removed background, cornerRadius, shadow to integrate into the panel
    }
}


// MARK: - Error Message Extension
// This makes String conform to Identifiable so it can be used with .alert(item:)
extension String: Identifiable {
    public var id: String { self }
}

// MARK: - UIImagePickerController (for Camera/Photo Library)
// This is a basic wrapper for UIImagePickerController to be used in SwiftUI
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
