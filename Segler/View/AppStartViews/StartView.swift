import SwiftUI

struct AppStart: View {
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().barTintColor = UIColor.seglerRed
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        if(
            UserDefaults.standard.string(forKey: "ip") != nil &&
            UserDefaults.standard.string(forKey: "serverUsername") != nil &&
            UserDefaults.standard.string(forKey: "serverPassword") != nil
        ){
            self.appIsReady = NetworkDataManager.shared.connect(
                host: UserDefaults.standard.string(forKey: "ip")!,
                username: UserDefaults.standard.string(forKey: "serverUsername")!,
                password: UserDefaults.standard.string(forKey: "serverPassword")!,
                isInit: true)
        } else {
            self.appIsReady = false
        }
    }
    
    @State var appIsReady: Bool
    
    //CREATING ALL DATA MODULES FOR THE VIEWS
    @StateObject var userVM = UserViewModel()
    @StateObject var settingsVM = SettingsViewModel()
    @StateObject var mediaVM = MediaViewModel()
    @StateObject var orderVM = OrderViewModel()
    @StateObject var remarksVM = RemarksViewModel()
    
    var body: some View {
        Group {
            if self.appIsReady && userVM.loggedIn {
                ZStack {
                    AppView()
                    .zIndex(2)

                }
                    .onAppear {
                        self.settingsVM.loadJSON()
                        self.remarksVM.loadJSON()
                        self.mediaVM.loadPDFs()
                        self.mediaVM.loadQuality()
                    }
            } else if self.appIsReady {
                LoginView()
            } else {
                SetupView(appIsReady: $appIsReady)
            }
        }
        .accentColor(Color.seglerRed)
        .environmentObject(userVM)
        .environmentObject(settingsVM)
        .environmentObject(mediaVM)
        .environmentObject(orderVM)
        .environmentObject(remarksVM)
    }
}
