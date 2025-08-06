//
//  Smart_HealthMateApp.swift
//  Smart HealthMate
//
//  Created by Moin on 6/18/25.
//

import SwiftUI
import SwiftData

import FirebaseCore

import SwiftData
import FirebaseAuth

import UIKit
import FirebaseCore
import SwiftData

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 Foreground notification received: \(notification.request.content.title) (ID: \(notification.request.identifier))")
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 User interacted with notification: \(response.notification.request.content.title) (ID: \(response.notification.request.identifier))")
        if response.notification.request.identifier.contains("MissedReminderReport"), let modelContext = modelContext {
            let missedReminderService = MissedReminderService(authManager: AuthManager())
            missedReminderService.setModelContext(modelContext)
            Task {
                await missedReminderService.checkAndSendMissedReminderEmail()
            }
        }
        completionHandler()
    }
}

@main
struct Smart_HealthMateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .modelContainer(for: [UserSettings.self, VitalReading.self, Medicine.self, Reminder.self, ChatMessages.self,PersistedMedicinePattern.self,PersistedVitalPattern.self, PersistedSpike.self, PersistedRecommendation.self, PersistedInsight.self ])
                .onAppear {
                    if let container = try? ModelContainer(for: UserSettings.self, VitalReading.self, Medicine.self, Reminder.self, ChatMessages.self,PersistedMedicinePattern.self,PersistedVitalPattern.self, PersistedSpike.self, PersistedRecommendation.self, PersistedInsight.self) {
                        appDelegate.setModelContext(container.mainContext)
                    }
                }
        }
    }
}
