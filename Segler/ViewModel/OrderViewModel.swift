import SwiftUI

class OrderViewModel : ObservableObject {
    @Published var orderNr = ""
    @Published var orderPosition = ""
    @Published var orderNrIsOk = true
    @Published var orderPositionIsOk = true
}
