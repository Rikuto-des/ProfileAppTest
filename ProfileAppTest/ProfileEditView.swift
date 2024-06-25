import SwiftUI

struct ProfileEditView: View {
    @ObservedObject var multipeerManager: MultipeerManager
    @State private var editedProfile: Profile
    @Environment(\.presentationMode) var presentationMode
    
    init(multipeerManager: MultipeerManager) {
        self._multipeerManager = ObservedObject(wrappedValue: multipeerManager)
        self._editedProfile = State(initialValue: multipeerManager.myProfile)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("名前", text: $editedProfile.name)
                    TextEditor(text: $editedProfile.bio)
                        .frame(height: 100)
                }
                
                Section(header: Text("興味・関心")) {
                    ForEach(editedProfile.interests.indices, id: \.self) { index in
                        TextField("興味 \(index + 1)", text: $editedProfile.interests[index])
                    }
                    Button("興味を追加") {
                        editedProfile.interests.append("")
                    }
                }
                
                Button("プロフィールを更新") {
                    multipeerManager.updateProfile(editedProfile)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("プロフィール編集")
            .navigationBarItems(trailing: Button("閉じる") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
