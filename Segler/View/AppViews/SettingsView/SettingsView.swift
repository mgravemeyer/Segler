import SwiftUI
import ProgressHUD

struct Settings_View: View {
    
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var mediaVM : MediaViewModel
    @EnvironmentObject var remarksVM : RemarksViewModel
    @EnvironmentObject var orderVM : OrderViewModel
    
    @State var adminMenueUnlocked : Bool = false
    @State private var showModal = false
    let deviceUser = UIDevice.current.name
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    var body: some View {
            List {
                Section(header: Text("Benutzer")) {
                        Text("Angemeldet: \(userVM.username)")
                }
                Section(header: Text("App Version")) {
                    Text(version)
                }
                if adminMenueUnlocked {
                    Button(action: {
                        self.adminMenueUnlocked = false
                    }) {
                        Text("Erweiterte Einstellungen schließen").foregroundColor(Color.red)
                    }
                } else {
                    Button(action: {
                        self.showModal = !self.showModal
                    }) {
                        Text("Erweiterte Einstellungen").foregroundColor(Color.red)
                    }
                }
                
                if adminMenueUnlocked {
                    Section(header: Text("Standard Benutzer")) {
                        Toggle("Standard Benutzer", isOn: self.$settingsVM.useFixedUserTemp)
                        TextField("Benutzername", text: self.$settingsVM.fixedUserName).accentColor(Color.seglerRed)
                    }
                    Section(header: Text("Server")) {
                        TextField("Server / Hostname", text: $settingsVM.ip).accentColor(Color.seglerRed)
                        TextField("Benutzername", text: $settingsVM.serverUsername).accentColor(Color.seglerRed)
                        SecureField("Passwort:", text: $settingsVM.serverPassword).accentColor(Color.seglerRed)
                        Button(action: {
                            let connection = FTPUploadController()
                            if connection.authenticate() {
                                ProgressHUD.showSuccess("Erfolgreich")
                            } else {
                                ProgressHUD.showError("Zugangsdaten falsch")
                            }
                        }) {
                            Text("Verbindung Testen").foregroundColor(Color.gray)
                        }
                    }
                    
                    Section(header: Text("Medienqualität")) {
                        Text("Foto: " + String(describing: mediaVM.qualityPicture))
                        Text("Video: " + String(describing: mediaVM.qualityVideo))
                    }
                    
                    Section(header: Text("Einstellungen speichern")) {
                        Button(action: {
                            ProgressHUD.showSuccess("Erfolgreich")
                            self.settingsVM.saveServerSettings()
                            adminMenueUnlocked.toggle()
                        }) {
                            Text("Speichern").foregroundColor(Color.red)
                        }
                    }
                }
                if !settingsVM.useFixedUser {
                    Button(action: {
                        self.userVM.username = ""
                        self.orderVM.orderNr = ""
                        self.orderVM.orderPosition = ""
                        self.mediaVM.images.removeAll()
                        self.remarksVM.selectedComment = ""
                        self.remarksVM.additionalComment = ""
                        self.userVM.loggedIn = false
                    }) {
                        Text("Abmelden").foregroundColor(Color.red)
                    }
                }
                
                
            }.navigationBarTitle("Einstellungen").listStyle(GroupedListStyle()).sheet(isPresented: $showModal) {
                ModalView(showModal: self.$showModal, adminMenueUnlocked: self.$adminMenueUnlocked)
            }
    }
}

struct ModalView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Binding var showModal : Bool
    @Binding var adminMenueUnlocked : Bool
    @State var password : String = ""
    @State var value : CGFloat = -30
    var body: some View {
        VStack {
            Image("Segler")
            .resizable()
            .aspectRatio(contentMode: ContentMode.fit)
            .frame(width: 280)
            .padding(Edge.Set.bottom, 20)
//            Text("Admin Anmelden").bold().font(.title)
            SecureField("Admin Passwort", text: $password).accentColor(Color.seglerRed)
            .padding()
            .background(Color(red: 241/255, green: 241/255, blue: 241/255))
            .cornerRadius(4.0)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 15, trailing: 0))
            Button(action: {
                if self.password == "\(self.settingsVM.adminMenuePassword)" {
                    ProgressHUD.showSuccess("Angemeldet")
                    self.adminMenueUnlocked = true
                    self.showModal = false
                } else {
                    ProgressHUD.showError("Falsches Passwort")
                    self.adminMenueUnlocked = false
                }
            }) {
                HStack(alignment: .center) {
                    Spacer()
                    Text("Anmelden").foregroundColor(Color.white).bold()
                    Spacer()
                }
            }.padding().background(Color.green).cornerRadius(4.0)
        }.padding().onAppear{
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (noti) in
                        let value = noti.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
                        let height = -value.height+300
                        self.value = height
                    }
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { (noti) in
                        _ = noti.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
                        let height : CGFloat = -30
                        self.value = height
                    }
        }.offset(y: self.value).animation(.spring())
    }
}
