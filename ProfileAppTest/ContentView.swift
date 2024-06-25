import SwiftUI

struct ContentView: View {
    @StateObject private var multipeerManager: MultipeerManager
    @State private var isSharing = false
    @State private var showingProfileEdit = false
    
    init() {
        let initialProfile = Profile(name: "", bio: "", interests: [])
        _multipeerManager = StateObject(wrappedValue: MultipeerManager(myProfile: initialProfile))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    isSharing.toggle()
                    if isSharing {
                        multipeerManager.startSharing()
                    } else {
                        multipeerManager.stopSharing()
                    }
                }) {
                    HStack {
                        Image(systemName: isSharing ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                        Text(isSharing ? "共有中" : "共有開始")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(isSharing ? Color.green : Color.blue)
                    .cornerRadius(8)
                }
                
                Button("プロフィール編集") {
                    showingProfileEdit = true
                }
                .padding()
                
                List(multipeerManager.receivedProfiles) { profile in
                    VStack(alignment: .leading) {
                        Text(profile.name).font(.headline)
                        Text(profile.bio).font(.subheadline)
                        ForEach(profile.interests, id: \.self) { interest in
                            Text("・ \(interest)")
                        }
                    }
                }
            }
            .navigationTitle("プロフィール交換")
            .sheet(isPresented: $showingProfileEdit) {
                ProfileEditView(multipeerManager: multipeerManager)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
