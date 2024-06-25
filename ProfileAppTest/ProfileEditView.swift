import SwiftUI

struct ProfileEditView: View {
    @ObservedObject var multipeerManager: MultipeerManager
    @State private var editedProfile: Profile
    @State private var image: UIImage?
    @State private var showingImagePicker = false
    @Environment(\.presentationMode) var presentationMode
    
    init(multipeerManager: MultipeerManager) {
        self._multipeerManager = ObservedObject(wrappedValue: multipeerManager)
        self._editedProfile = State(initialValue: multipeerManager.myProfile)
        if let imageData = multipeerManager.myProfile.imageData {
            self._image = State(initialValue: UIImage(data: imageData))
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("プロフィール画像")) {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    Button("画像を選択") {
                        showingImagePicker = true
                    }
                }
                
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
                    if let image = image {
                        editedProfile.imageData = image.jpegData(compressionQuality: 0.8)
                    }
                    multipeerManager.updateProfile(editedProfile)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("プロフィール編集")
            .navigationBarItems(trailing: Button("閉じる") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $image)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
