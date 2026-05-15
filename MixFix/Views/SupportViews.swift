//
//  SupportViews.swift
//  MixFix
//
//  Support options and resources screens for low mood support
//

import SwiftUI

// MARK: - Support Options Screen
struct SupportOptionsScreen: View {
    @Environment(\.dismiss) private var dismiss
    let moodName: String
    let onOpenResources: () -> Void
    let onContinueToStudy: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.pink, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("You're Not Alone")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Feeling \(moodName.lowercased()) is completely normal. Take a moment to care for yourself.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)
                
                // Options
                VStack(spacing: 16) {
                    // Support Resources Button
                    Button {
                        onOpenResources()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "heart.text.square.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [Color.pink, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Open Support Resources")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Quick relief tools and coping strategies")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.pink.opacity(0.2), radius: 12, x: 0, y: 6)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.pink.opacity(0.5), Color.purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Continue to Study Button
                    Button {
                        onContinueToStudy()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "book.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Continue to Study Options")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Choose between soft or push study modes")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.blue.opacity(0.2), radius: 12, x: 0, y: 6)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.5), Color.cyan.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Support Resources Browser
struct SupportResourcesView: View {
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Support Toolkit")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Choose what feels right for you right now")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Categories
                    ForEach(SupportToolkit.categories) { category in
                        NavigationLink {
                            SupportCategoryDetailView(category: category)
                        } label: {
                            SupportCategoryCard(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onComplete()
                    }
                }
            }
        }
    }
}

// MARK: - Support Category Card
struct SupportCategoryCard: View {
    let category: SupportCategory
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Color(hex: category.color))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(category.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color(hex: category.color).opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    Color(hex: category.color).opacity(0.3),
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - Support Category Detail View
struct SupportCategoryDetailView: View {
    let category: SupportCategory
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: category.icon)
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(Color(hex: category.color))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(category.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Items
                VStack(spacing: 16) {
                    ForEach(Array(category.items.enumerated()), id: \.offset) { index, item in
                        SupportItemCard(item: item, color: category.color, index: index + 1)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Support Item Card
struct SupportItemCard: View {
    let item: String
    let color: String
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Number badge
            Text("\(index)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color(hex: color))
                .clipShape(Circle())
            
            // Item text
            Text(item)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    Color(hex: color).opacity(0.2),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Preview
#Preview("Support Options") {
    SupportOptionsScreen(
        moodName: "Overwhelmed",
        onOpenResources: { print("Open resources") },
        onContinueToStudy: { print("Continue to study") }
    )
}

#Preview("Support Resources") {
    SupportResourcesView(onComplete: { print("Complete") })
}

#Preview("Category Detail") {
    NavigationStack {
        SupportCategoryDetailView(category: SupportToolkit.categories[0])
    }
}
