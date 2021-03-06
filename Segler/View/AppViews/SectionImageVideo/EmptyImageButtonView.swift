import SwiftUI

struct EmptyImageButtonView: View {
    
    @EnvironmentObject var mediaVM : MediaViewModel
    
    @State var showSheet = false
    
    var body: some View {
        Group {
            Button(action: {
                UIApplication.shared.endEditing()
                self.showSheet = !self.showSheet
            }) {
                ZStack {
                    Image("Camera")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color.seglerRed)
                        .frame(width: 40, height: 40)
                        .zIndex(1)
                    RoundedRectangle(cornerRadius: CGFloat(3))
                        .foregroundColor(Color.clear)
                        .frame(width: 40, height: 145)
                        .zIndex(0)
                }
            }
        }
            .actionSheet(isPresented: self.$showSheet) { () -> ActionSheet in
                ActionSheet(title: Text("Bild/Video hinzufügen"), message: Text("Kamera oder Galerie auswählen"), buttons: [
                    ActionSheet.Button.default(Text("Kamera"), action: {
                        self.mediaVM.showImagePicker = !self.mediaVM.showImagePicker
                    }),
                    ActionSheet.Button.default(Text("Galerie"), action: {
                        self.mediaVM.showImagePickerNew.toggle()
                    }),
                    ActionSheet.Button.cancel()
                ] )
        }
    }
}
