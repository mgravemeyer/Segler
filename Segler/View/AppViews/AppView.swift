import SwiftUI
import ProgressHUD
import Photos
import AVKit

struct AppView: View {
    
    @EnvironmentObject var settingsVM : SettingsViewModel
    @EnvironmentObject var userVM : UserViewModel
    @EnvironmentObject var mediaVM : MediaViewModel
    @EnvironmentObject var remarksVM : RemarksViewModel
    @EnvironmentObject var orderVM : OrderViewModel

    @State var keyboardIsShown = false
    
    var body: some View {
            ZStack {
                NavigationView {
                    ZStack {
                        Group {
                            ZStack {
                                if mediaVM.showVideo {
                                    VideoDetail()
                                        .onAppear {
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        }
                                }
                                if mediaVM.showImage {
                                    if mediaVM.selectedImageNeedsAjustment {
                                        PhotoDetail()
                                            .onAppear {
                                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                            }
                                    }
                                }
                                List {
                                    SectionOrder()
                                        .frame(height: 34)
                                    SectionRemarks()
                                        .frame(height: 34)
                                    SectionFreeTextField()
                                    SectionBilder()
                                    if !(settingsVM.errorsJSON.isEmpty) {
                                        Image("Warning").resizable().frame(width: 50, height: 50)
                                        ForEach(settingsVM.errorsJSON, id: \.self) { error in
                                            Text(error).foregroundColor(Color.red)
                                        }
                                    }
                                }.environment(\.defaultMinListRowHeight, 8).zIndex(0)
                                VStack {
                                    Spacer()
                                    SaveButton().zIndex(100)
                                }
                            }
                        .navigationBarItems(leading:(
                        HStack {
                            NavigationLink(destination: Settings_View()) {
                                Image(systemName: "gear").font(.system(size: 25))
                            }
                            if !settingsVM.useFixedUser {
                                NavigationLink(destination: Webview(url: "\(settingsVM.helpURL)").navigationBarTitle("Hilfe")) {
                                    Image(systemName: "questionmark.circle").font(.system(size: 25))
                                }
                            }
                        }
                        ), trailing:
                            (
                        HStack {
                            Button(action: {
                            self.userVM.username = ""
                            self.userVM.loggedIn = false
                            self.orderVM.machineName = ""
                            self.orderVM.orderNr = ""
                            self.orderVM.orderPosition = ""
                            self.mediaVM.images.removeAll()
                            self.remarksVM.selectedComment = ""
                            self.remarksVM.additionalComment = ""
                            self.orderVM.orderNrIsOk = true
                            self.remarksVM.commentIsOk = true
                            self.mediaVM.imagesIsOk = true
                            }, label: {
                                if settingsVM.useFixedUser {
                                    Text("")
                                } else {
                                    Image(systemName: "xmark").font(.system(size: 25))
                                }
                            })
                            if settingsVM.useFixedUser {
                                NavigationLink(destination: Webview(url: "\(settingsVM.helpURL)").navigationBarTitle("Hilfe")) {
                                    Image(systemName: "questionmark.circle").font(.system(size: 25))
                                }
                            }
                        }
                        )
                        ).navigationBarTitle(settingsVM.useFixedUser ? Text("\(settingsVM.userUsername)") : Text("\(userVM.username)"), displayMode: .inline)
                        }
                    }
                }
                .sheet(isPresented: self.$mediaVM.showImagePickerNew) {
                    ImageSelectionModal()
                    .onAppear {
                        mediaVM.fetchMedia()
                    }
                }
                .onAppear {
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (noti) in
                        self.keyboardIsShown = true
                    }
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { (noti) in
                        self.keyboardIsShown = false
                    }
                }.accentColor(Color.white).navigationViewStyle(StackNavigationViewStyle())
                if self.mediaVM.showImagePicker {
                    ImagePicker()
                }
                if self.mediaVM.showImageScanner {
                    BarcodeScannerSegler(sourceType: 0)
                }
            }
            .onAppear() {
            self.remarksVM.getJSON(session: self.settingsVM.ip, username: self.settingsVM.serverUsername, password: self.settingsVM.serverPassword)
        }
    }
}

struct SaveButton: View {
    
    @EnvironmentObject var settingsVM : SettingsViewModel
    @EnvironmentObject var mediaVM : MediaViewModel
    @EnvironmentObject var orderVM : OrderViewModel
    @EnvironmentObject var remarksVM : RemarksViewModel
    @EnvironmentObject var userVM : UserViewModel
    @State var showReport = false
    
    let colors = ColorSeglerViewModel()
    
    @State var isInProgress = false
//    lazy var connection = FTPUploadController(mediaVM: self.mediaVM)
    
    var connection: FTPUploadController {
        return FTPUploadController()
    }
    
    @State var keyboardIsShown = false

    var body: some View {
        HStack {
            Button(action: {
                typealias ThrowableCallback = () throws -> Bool
                self.connection.someAsyncFunction(true) { (error) -> Void in
                    if error != nil {
                        ProgressHUD.showError(error)
                        return
                    } else {
                        ProgressHUD.showSuccess("Hochgeladen")
                        self.showReport = true
                        return
                    }
                }
            }) {
                Text("Abschicken  ")
                    .font(.headline)
                    .foregroundColor(Color.white)
            }.padding(.leading, 14)
            Spacer()
            if keyboardIsShown {
                Button(action: {
                    UIApplication.shared.endEditing()
                }) {
                    Image(systemName: "keyboard.chevron.compact.down")
    //                Text("Abschicken")
                        .font(.headline)
                        .foregroundColor(Color.white)
                }.padding(.trailing, 14)
            }
        }.onAppear {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (noti) in
                self.keyboardIsShown = true
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { (noti) in
                self.keyboardIsShown = false
            }
    }.frame(height: 50).background(colors.color)
        .sheet(isPresented: $showReport) {
            reportModal(showReport: self.$showReport)
        }
    }
}

struct reportModal: View {
    
    @Binding var showReport : Bool
    @EnvironmentObject var settingsVM : SettingsViewModel
    @EnvironmentObject var mediaVM : MediaViewModel
    @EnvironmentObject var orderVM : OrderViewModel
    @EnvironmentObject var remarksVM : RemarksViewModel
    
    var body: some View {
            List {
                Text("Abgeschickt!").foregroundColor(Color.black).fontWeight(.bold).font(.largeTitle)
                Text("Auftrags-Nr: \(orderVM.orderNr)").frame(height: 34)
                Text("Auftrags-Position: \(orderVM.orderPosition)").frame(height: 34)
                if remarksVM.selectedComment != "" && settingsVM.savedPDF.name == "" {
                    Text("Kommentar: \(remarksVM.selectedComment)").frame(height: 34)
                }
                if remarksVM.additionalComment != "" {
                    Text("Freitext: \(remarksVM.additionalComment)").frame(height: 34)
                }
                if settingsVM.savedPDF.name != "" {
                    Text("Protokoll: \(settingsVM.savedPDF.name)")
                }
                if !mediaVM.images.isEmpty || !mediaVM.imagesCamera.isEmpty || !mediaVM.videos.isEmpty || !mediaVM.videosCamera.isEmpty {
                    HStack {
                        ForEach((0...mediaVM.highestOrderNumber).reversed(), id:\.self) { i in
                            ForEach(mediaVM.images, id:\.self) { image in
                                if image.selected && image.order == i {
                                    Image(uiImage: image.thumbnail).renderingMode(.original).resizable().frame(width: 80, height: 80)
                                }
                            }
                            ForEach(mediaVM.imagesCamera, id:\.self) { image in
                                if image.order == i {
                                    Image(uiImage: image.image).renderingMode(.original).resizable().frame(width: 80, height: 80)
                                }
                            }
                            ForEach(mediaVM.videos, id:\.self) { video in
                                if video.selected && video.order == i {
                                    Image(uiImage: video.thumbnail).renderingMode(.original).resizable().frame(width: 80, height: 80)
                                }
                            }
                            ForEach(mediaVM.videosCamera, id:\.self) { video in
                                if video.order == i {
                                    Image(uiImage: video.thumbnail).renderingMode(.original).resizable().frame(width: 80, height: 80)
                                }
                            }
                        }
                    }
                }
                Button(action: {
                    deleteMedia()
                }) {
                    Text("Schließen").frame(height: 34).foregroundColor(Color.blue)
                }
            }.padding(.top, 40).onDisappear {
                deleteMedia()
            }
    }
    
    func deleteMedia() {
        self.showReport = false
        self.orderVM.machineName = ""
        self.orderVM.orderNr = ""
        self.orderVM.orderPosition = ""
        self.mediaVM.images.removeAll()
        self.mediaVM.videos.removeAll()
        self.mediaVM.imagesCamera.removeAll()
        self.mediaVM.videosCamera.removeAll()
        self.remarksVM.selectedComment = ""
        self.remarksVM.additionalComment = ""
        self.orderVM.orderNrIsOk = true
        self.remarksVM.commentIsOk = true
        self.mediaVM.imagesIsOk = true
        self.showReport = false
        self.settingsVM.savedPDF = PDF(name: "", data: Data())
    }

}

struct SectionBilder: View {
    
    let colors = ColorSeglerViewModel()
    @EnvironmentObject var mediaVM : MediaViewModel
    
    var body: some View {

            ScrollView(.horizontal) {
                HStack {
                        EmptyImgButton().accentColor(self.colors.color).padding(.leading, 15)
                        if mediaVM.getNumberOfImages()>0 {
                            ForEach((0...mediaVM.highestOrderNumber).reversed(), id:\.self) { i in
                                ForEach(mediaVM.images, id:\.self) { image in
                                    if image.selected && image.order == i {
                                        ImagePreviewView(imageObject: image,id: image.id)
                                    }
                                }
                                ForEach(mediaVM.imagesCamera, id:\.self) { image in
                                    if image.order == i  {
                                        ImageCameraPreviewView(imageObject: image,id: image.id)
                                    }
                                }
                                ForEach(mediaVM.videos, id:\.self) { video in
                                    if video.selected && video.order == i {
                                        testVideoView(videoObject: video, id: video.id)
                                    }
                                }
                                ForEach(mediaVM.videosCamera, id:\.self) { video in
                                    if video.order == i {
                                        testVideoCameraView(videoObject: video, id: video.id)
                                    }
                                }
                            }
                        } else {
                                ForEach(mediaVM.images, id:\.self) { image in
                                    ImagePreviewView(imageObject: image,id: image.id)
                                }
                                ForEach(mediaVM.imagesCamera, id:\.self) { image in
                                    ImageCameraPreviewView(imageObject: image,id: image.id)
                                }
                                ForEach(mediaVM.videos, id:\.self) { video in
                                    testVideoView(videoObject: video, id: video.id)
                                }
                                ForEach(mediaVM.videosCamera, id:\.self) { video in
                                    testVideoCameraView(videoObject: video, id: video.id)
                                }
                        }
                }
            }.padding(.horizontal, -15).listRowBackground(self.mediaVM.imagesIsOk ? colors.correctRowColor : colors.warningRowColor)
    }
}

struct testVideoCameraView: View {
    
    @EnvironmentObject var mediaVM: MediaViewModel
    @State var videoObject : VideoModelCamera
    @State var showSheet = false
    @State var id : UUID
    
    var body: some View {
        Button(action: {
            self.showSheet = !self.showSheet
        }) {
            ZStack {
                Rectangle().frame(width: 100, height: 100).background(Color.black).opacity(0.3).zIndex(2)
                Text("Video").fontWeight(.bold).zIndex(1)
                Image(uiImage: videoObject.thumbnail).renderingMode(.original).resizable().frame(width: 100, height: 100).scaledToFill().zIndex(0)
            }
            .actionSheet(isPresented: self.$showSheet) { () -> ActionSheet in
                ActionSheet(title: Text("Anzeigen - Löschen"), buttons: [
                    ActionSheet.Button.default(Text("Video anzeigen"), action: {
                        self.toggleShowImage()
                    }),
                    ActionSheet.Button.destructive(Text("Video löschen"), action: {
                        self.deleto(id: self.id)
                    }),
                    ActionSheet.Button.cancel()
                ])
            }
        }
    }
    func toggleShowImage() {
        mediaVM.selectedVideo = videoObject.url
        mediaVM.showVideo.toggle()
    }
    func deleto(id: UUID) {
        if let index = mediaVM.videosCamera.firstIndex(where: {$0.id == id}) {
            mediaVM.videosCamera.remove(at: index)
        }
    }
}

struct testVideoView: View {

    @EnvironmentObject var mediaVM: MediaViewModel
    @State var videoObject : VideoModel
    @State var showSheet = false
    @State var id : UUID
    
    var body: some View {
        Button(action: {
            self.showSheet = !self.showSheet
        }) {
            ZStack {
                Rectangle().frame(width: 100, height: 100).background(Color.black).opacity(0.3).zIndex(2)
                Text("Video").fontWeight(.bold).zIndex(1)
                Image(uiImage: videoObject.thumbnail).renderingMode(.original).resizable().frame(width: 100, height: 100).scaledToFill().zIndex(0)
            }
            .actionSheet(isPresented: self.$showSheet) { () -> ActionSheet in
                ActionSheet(title: Text("Anzeigen - Löschen"), buttons: [
                    ActionSheet.Button.default(Text("Video anzeigen"), action: {
                        self.toggleShowImage()
                    }),
                    ActionSheet.Button.destructive(Text("Video löschen"), action: {
                        self.toggle(id: self.id)
                    }),
                    ActionSheet.Button.cancel()
                ])
            }
        }
    }
    func toggleShowImage() {
        mediaVM.showVideo.toggle()
        mediaVM.selectedVideo = videoObject.assetURL
    }
    func toggle(id: UUID) {
        if let index = mediaVM.videos.firstIndex(where: {$0.id == id}) {
            mediaVM.videos[index].selected.toggle()
        }
    }
}

struct ImageView: View {
    
    @EnvironmentObject var mediaVM : MediaViewModel
    @State var index: Int
    @State var showSheet = false
    
    var body: some View {
        Button(action: {
            self.showSheet = !self.showSheet
        }) {
            Image(uiImage: self.mediaVM.images[self.index].thumbnail).renderingMode(.original).scaledToFit().frame(width: 120, height: 120)
            .actionSheet(isPresented: self.$showSheet) { () -> ActionSheet in
                    ActionSheet(title: Text("Bild löschen"), message: Text("Wirklich Bild löschen?"), buttons: [
                        ActionSheet.Button.default(Text("Ja"), action: {
                        }),
                        ActionSheet.Button.cancel()
                    ])
            }
        }
    }
    func delete(at index: Int) {
        self.mediaVM.images.remove(at: index)
    }
}

struct EmptyImgButton: View {
    
    @EnvironmentObject var mediaVM : MediaViewModel
    
    @State var showSheet = false
    
    var color = ColorSeglerViewModel()
    
    var body: some View {
        Group {
            if !UIDevice.current.name.contains("iPod touch") {
                Button(action: {
                    UIApplication.shared.endEditing()
                    self.showSheet = !self.showSheet
                }) {
                    

                    ZStack {
                        Image("Camera")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(color.color)
                            .frame(width: 40, height: 40)
                            .zIndex(1)
                        RoundedRectangle(cornerRadius: CGFloat(3))
                            .foregroundColor(Color.clear)
                            .frame(width: 40, height: 145)
                            .zIndex(0)
                    }
                }
            } else {
                Button(action: {
                    UIApplication.shared.endEditing()
                    self.mediaVM.sourceType = 0
                    self.mediaVM.showImagePicker = !self.mediaVM.showImagePicker
                }) {
                    ZStack {
                        Image("Camera")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(color.color)
                            .frame(width: 40, height: 40)
                            .zIndex(1)
                        RoundedRectangle(cornerRadius: CGFloat(3))
                            .foregroundColor(Color.clear)
                            .frame(width: 40, height: 145)
                            .zIndex(0)
                    }
                }
            }
        }

            .actionSheet(isPresented: self.$showSheet) { () -> ActionSheet in
                ActionSheet(title: Text("Bild/Video hinzufügen"), message: Text("Kamera oder Galerie auswählen"), buttons: [
                    ActionSheet.Button.default(Text("Kamera"), action: {
                        self.mediaVM.sourceType = 0
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
