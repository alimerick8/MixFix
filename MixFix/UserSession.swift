import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

struct UserProfile: Identifiable, Codable {
    var id: String { uid }
    let uid: String
    let name: String?
    let email: String?
    
    init(uid: String, name: String? = nil, email: String? = nil) {
        self.uid = uid
        self.name = name
        self.email = email
    }
    
    init(uid: String, data: [String: Any]) {
        self.uid = uid
        self.name = data["userName"] as? String ?? data["name"] as? String
        self.email = data["email"] as? String
    }
}

final class UserSession: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isLoggedIn: Bool = false
    @Published var uid: String?
    
    private var authListener: AuthStateDidChangeListenerHandle?
    private var profileListener: ListenerRegistration?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        listenToAuthChanges()
    }
    
    deinit {
        removeListeners()
    }
    
    func listenToAuthChanges() {
        // Remove any existing listener first
        authListener.map { auth.removeStateDidChangeListener($0) }
        
        authListener = auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                let newUid = user.uid
                
                // Set auth state immediately (but don't load data yet)
                DispatchQueue.main.async {
                    self.uid = newUid
                    self.isLoggedIn = true
                }
                
                // Verify the token is still valid by refreshing it in background
                Task {
                    do {
                        // Force token refresh to validate authentication
                        _ = try await user.getIDTokenResult(forcingRefresh: true)
                        
                        // Token is valid, now safe to load user data from Firestore
                        self.loadUserData(for: newUid)
                        print("✅ Auth state restored successfully with valid token")
                    } catch {
                        // Token is expired or invalid, sign user out
                        print("❌ Auth token invalid or expired: \(error.localizedDescription)")
                        print("🔐 Signing user out to force fresh login")
                        
                        await MainActor.run {
                            self.isLoggedIn = false
                            self.uid = nil
                        }
                        self.clearUserData()
                        
                        // Sign out from Firebase to clear the expired session
                        try? self.auth.signOut()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoggedIn = false
                    self.uid = nil
                }
                self.clearUserData()
            }
        }
    }
    
    func loadUserData(for uid: String) {
        // Tear down any existing profile listener
        profileListener?.remove()
        
        // Add a small delay to allow Firebase Auth token to propagate to Firestore
        // This prevents "Missing or insufficient permissions" errors on sign-in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            self.profileListener = self.db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    // Check if it's a permissions error
                    let errorMessage = error.localizedDescription
                    if errorMessage.contains("permission") || errorMessage.contains("PERMISSION_DENIED") {
                        print("⚠️ Firestore permissions error (likely still authenticating): \(errorMessage)")
                        // Don't clear user data - just wait for next update when token is ready
                    } else {
                        print("❌ Failed to listen to user profile: \(errorMessage)")
                    }
                    return
                }
                guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                    // Document doesn't exist yet (new user) - create empty profile
                    DispatchQueue.main.async {
                        self.currentUser = UserProfile(uid: uid)
                    }
                    return
                }
                let profile = UserProfile(uid: uid, data: data)
                DispatchQueue.main.async {
                    self.currentUser = profile
                }
            }
        }
    }
    
    func clearUserData() {
        removeListeners()
        DispatchQueue.main.async {
            self.currentUser = nil
            self.uid = nil
            
            // Also clear AppStorage flags to force re-authentication
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            print("🧹 Cleared user session and AppStorage flags")
        }
    }
    
    private func removeListeners() {
        if let handle = authListener {
            auth.removeStateDidChangeListener(handle)
            authListener = nil
        }
        profileListener?.remove()
        profileListener = nil
    }
}
