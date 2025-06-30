import SwiftUI

// MARK: - Custom Shape for Specific Corner Radius
// Yeh struct aapko khaas konon (corners) par golai (radius) lagane ki ijazat deta hai.
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Extension to View for convenience
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}



// MARK: - Reminder Struct (Updated to match React interface)
struct Reminder: Identifiable, Equatable {
    let id = UUID() // UUID for Identifiable
    var title: String
    var type: ReminderType
    var time: Date // Use Date for easier time manipulation
    var frequency: ReminderFrequency // Enum for frequency
    var active: Bool // Corresponds to React's 'active'
    var nextDue: Date // Corresponds to React's 'nextDue'
    
    // SF Symbol icon name based on type
    var iconName: String {
        switch type {
        case .medicine: return "pill.fill" // Changed from bell to pill.fill for medicine
        case .checkup: return "stethoscope" // Changed from alert.circle to stethoscope for checkup
        case .appointment: return "calendar.badge.clock" // Changed from clock to calendar.badge.clock for appointment
        }
    }

    enum ReminderType: String, CaseIterable, Identifiable {
        case medicine
        case checkup
        case appointment

        var id: String { self.rawValue }
        var displayName: String {
            switch self {
            case .medicine: return "Medicine"
            case .checkup: return "Health Checkup"
            case .appointment: return "Appointment"
            }
        }
    }

    enum ReminderFrequency: String, CaseIterable, Identifiable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"

        var id: String { self.rawValue }
    }
    
    // Helper to determine if a reminder is overdue
    var isOverdue: Bool {
        return nextDue < Date() && active // Only overdue if active and time has passed
    }
}

// MARK: - ReminderDetailRow View (Redesigned to match React Card Style)
struct ReminderDetailRow: View {
    let reminder: Reminder
    var onToggle: (UUID) -> Void // Callback for toggle active/disable
    var onDelete: (UUID) -> Void // Callback for delete

    // Date formatters for consistent display
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()

    var body: some View {
        ZStack(alignment: .leading) {
            // Inner background card for tint and rounded corners
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundTint)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2) // Subtle shadow
            
            // Left Border Line
            Rectangle()
                .fill(borderTint)
                .frame(width: 4)
                .cornerRadius(12, corners: [.topLeft, .bottomLeft]) // FIX APPLIED HERE
                // The extension `cornerRadius(_:corners:)` is used here.

            VStack(alignment: .leading, spacing: 12) { // Adjusted spacing for tighter look
                // Header Section: Icon, Title, Time, Status Badges
                HStack(alignment: .top) {
                    // Icon with tinted background
                    Image(systemName: reminder.iconName)
                        .font(.body)
                        .foregroundColor(iconColor)
                        .frame(width: 36, height: 36) // Slightly smaller icon background
                        .background(iconBackgroundColor)
                        .clipShape(Circle()) // Circular background for icon
                    
                    VStack(alignment: .leading) {
                        Text(reminder.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("\(Self.timeFormatter.string(from: reminder.time)) • \(reminder.frequency.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Badges (Overdue, Active/Disabled)
                    HStack(spacing: 8) {
                        if reminder.isOverdue { // Use computed property
                            Text("Overdue")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.15))
                                .foregroundColor(.red.opacity(0.9))
                                .cornerRadius(6)
                        }
                        
                        Text(reminder.active ? "Active" : "Disabled")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(reminder.active ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                            .foregroundColor(reminder.active ? Color.green.opacity(0.9) : Color.gray.opacity(0.8))
                            .cornerRadius(6)
                    }
                }
                
                // Next Due and Type Tag Section
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.7))
                        Text("Next: \(Self.dateFormatter.string(from: reminder.nextDue)) at \(Self.timeFormatter.string(from: reminder.nextDue))")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    Text(reminder.type.displayName) // Use displayName from enum
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(Color.gray.opacity(0.8))
                        .cornerRadius(6)
                }
                .padding(.top, 4) // Small padding after header content
                
                // Action Buttons
                Divider() // A subtle divider between content and actions
                    .padding(.vertical, 4)

                HStack(spacing: 12) { // Increased spacing between buttons
                    // Toggle Active/Disable Button
                    Button(action: {
                        onToggle(reminder.id)
                    }) {
                        HStack {
                            Image(systemName: reminder.active ? "slash.circle" : "checkmark.circle") // Icon changes based on active state
                                .font(.subheadline)
                            Text(reminder.active ? "Disable" : "Enable")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 8) // Reduced vertical padding
                        .padding(.horizontal, 12) // Reduced horizontal padding
                        .background(reminder.active ? Color.gray.opacity(0.1) : Color.green.opacity(0.15))
                        .foregroundColor(reminder.active ? Color.gray.opacity(0.8) : Color.green.opacity(0.9))
                        .cornerRadius(8) // Slightly more rounded
                    }
                    
                    // Delete Button
                    Button(action: {
                        onDelete(reminder.id)
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .font(.subheadline)
                            Text("Delete")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red.opacity(0.9))
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading) // Ensure buttons align left
            }
            .padding(.vertical, 16) // Vertical padding for content
            .padding(.horizontal, 16 + 4) // Horizontal padding adjusted for left border
            // The background color is applied to the ZStack, so no separate background needed here.
        }
        .cornerRadius(12) // Overall card corner radius
        .padding(.horizontal, 5) // Small horizontal padding from screen edges
        .padding(.vertical, 4) // Vertical spacing between reminder rows
    }

    // Helper computed properties for styling based on reminder type and status
    private var backgroundTint: Color {
        if reminder.isOverdue {
            return Color.red.opacity(0.05)
        } else if reminder.active {
            return Color.blue.opacity(0.05) // Active but not overdue
        } else {
            return Color.gray.opacity(0.05) // Disabled
        }
    }

    private var borderTint: Color {
        if reminder.isOverdue {
            return Color.red
        } else if reminder.active {
            return Color.blue
        } else {
            return Color.gray.opacity(0.5) // Less prominent border for disabled
        }
    }

    private var iconColor: Color {
        switch reminder.type {
        case .medicine: return Color.blue.opacity(0.7)
        case .checkup: return Color.green.opacity(0.7)
        case .appointment: return Color.purple.opacity(0.7)
        }
    }

    private var iconBackgroundColor: Color {
        switch reminder.type {
        case .medicine: return Color.blue.opacity(0.15)
        case .checkup: return Color.green.opacity(0.15)
        case .appointment: return Color.purple.opacity(0.15)
        }
    }
}


// MARK: - ReminderSummaryCard (New View for the top summary cards)
struct ReminderSummaryCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let tintColor: Color
    let gradientStart: Color
    let gradientEnd: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [gradientStart, gradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tintColor.opacity(0.2), lineWidth: 1) // Subtle border
            )
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2) // Consistent shadow
            .frame(maxWidth: .infinity) // Ensures card expands horizontally
            .aspectRatio(4/1, contentMode: .fit) // Adjusted aspect ratio for smaller cards
            .overlay( // Content goes inside the overlay
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(tintColor.opacity(0.8))
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(tintColor.opacity(0.6))
                    }
                    Spacer()
                    Image(systemName: iconName)
                        .font(.title2)
                        .padding(8)
                        .background(tintColor.opacity(0.2)) // Icon background tint
                        .clipShape(Circle())
                        .foregroundColor(tintColor.opacity(0.7))
                }
                .padding(10) // Slightly reduced padding inside the card content
            )
    }
}

// MARK: - AddNewReminderSheetView (New View for the Add Reminder Dialog/Sheet)
struct AddNewReminderSheetView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (Reminder) -> Void

    @State private var title: String = ""
    @State private var type: Reminder.ReminderType = .medicine
    @State private var time: Date = Date() // DatePicker returns a full Date
    @State private var frequency: Reminder.ReminderFrequency = .daily

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reminder Details")) {
                    TextField("Reminder Title (e.g., Take Medicine)", text: $title)
                    Picker("Type", selection: $type) {
                        ForEach(Reminder.ReminderType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu) // Or .segmented for fewer options
                }

                Section(header: Text("Timing and Frequency")) {
                    DatePicker("Select Time", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact) // Compact style for better UX
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Reminder.ReminderFrequency.allCases) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    .pickerStyle(.segmented) // Segmented for fewer frequency options
                }
            }
            .navigationTitle("Add New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Calculate nextDue based on current date and selected time/frequency
                        let calendar = Calendar.current
                        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
                        let selectedTimeComponents = calendar.dateComponents([.hour, .minute], from: time)
                        
                        components.hour = selectedTimeComponents.hour
                        components.minute = selectedTimeComponents.minute
                        
                        let calculatedNextDue = calendar.date(from: components) ?? Date()

                        let newReminder = Reminder(title: title, type: type, time: time, frequency: frequency, active: true, nextDue: calculatedNextDue)
                        onSave(newReminder)
                        dismiss()
                    }
                    .disabled(title.isEmpty) // Disable save if title is empty
                }
            }
        }
    }
}

// MARK: - NoRemindersPlaceholderView (New View for when no reminders exist)
struct NoRemindersPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash.fill") // A bell with a slash, indicating no reminders
                .font(.largeTitle)
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 4) {
                Text("No reminders set up yet")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("Add your first reminder to get started")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

// MARK: - RemindersScreen (Second Tab Content)
struct RemindersScreen: View {
    let medicinesCount: Int // Added this property
    @Binding var reminders: [Reminder]
    @State private var showingAddReminderSheet = false

    private var activeRemindersCount: Int {
        reminders.filter { $0.active }.count
    }

    private var overdueRemindersCount: Int {
        reminders.filter { $0.isOverdue && $0.active }.count
    }

    private var onTrackPercentage: Int {
        guard activeRemindersCount > 0 else { return 100 }
        return Int(round(Double(activeRemindersCount - overdueRemindersCount) / Double(activeRemindersCount) * 100))
    }

    var body: some View {
        NavigationStack { // Provides its own navigation bar and full screen behavior
            GeometryReader { geometry in // Use GeometryReader to get safe area insets
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Reminders-specific subheading
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Manage your medication and health reminders") // Subheading
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        
                        SMAMedicineTrackerStats(medicinesCount: medicinesCount) // Use the passed count
                        
                        // Reminders Summary Stats Cards (Arranged Vertically, Smaller)
                        VStack(spacing: 12) { // Arranged vertically
                            ReminderSummaryCard(
                                title: "\(activeRemindersCount)", subtitle: "Active Reminders",
                                iconName: "bell.fill", tintColor: .blue,
                                gradientStart: .blue.opacity(0.05), gradientEnd: .blue.opacity(0.1)
                            )
                            ReminderSummaryCard(
                                title: "\(overdueRemindersCount)", subtitle: "Overdue",
                                iconName: "exclamationmark.triangle.fill", tintColor: .red,
                                gradientStart: .red.opacity(0.05), gradientEnd: .red.opacity(0.1)
                            )
                            ReminderSummaryCard(
                                title: "\(onTrackPercentage)%", subtitle: "On Track",
                                iconName: "checkmark.circle.fill", tintColor: .green,
                                gradientStart: .green.opacity(0.05), gradientEnd: .green.opacity(0.1)
                            )
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 5)

                        // All Reminders Section
                        Text("All Reminders")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top, 10)
                            .padding(.horizontal)

                        LazyVStack(spacing: 8) {
                            if reminders.isEmpty {
                                NoRemindersPlaceholderView()
                                    .padding(.horizontal)
                            } else {
                                ForEach(reminders.sorted(by: { $0.nextDue < $1.nextDue })) { reminder in
                                    ReminderDetailRow(reminder: reminder, onToggle: { id in
                                        if let index = reminders.firstIndex(where: { $0.id == id }) {
                                            reminders[index].active.toggle()
                                            print("Toggled reminder \(reminder.title) to active: \(reminders[index].active)")
                                        }
                                    }, onDelete: { id in
                                        if let index = reminders.firstIndex(where: { $0.id == id }) {
                                            let deletedTitle = reminders[index].title
                                            reminders.remove(at: index)
                                            print("Deleted reminder: \(deletedTitle)")
                                        }
                                    })
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    // Add padding to the bottom of the ScrollView to prevent collision with the fixed bottom bar
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 60) // Use geometry.safeAreaInsets
                }
            }
            .navigationTitle("Smart Reminders") // Changed navigation title to "Smart Reminders"
            .navigationBarTitleDisplayMode(.large) // Make the title large
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddReminderSheet = true
                    }) {
                        Label("Add Reminder", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddReminderSheet) {
                AddNewReminderSheetView { newReminder in
                    reminders.append(newReminder)
                    reminders.sort { $0.nextDue < $1.nextDue }
                }
            }
        }
    }
}
