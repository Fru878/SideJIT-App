//
//  ContentView.swift
//  SideJIT
//
//  Created by Hristos Sfikas on 3/4/2024.
//
import UserNotifications
import SwiftUI

struct ContentView: View {
    @State var isAuthenticating = false
    @AppStorage("allowednotification") var allowednotification = false
    @AppStorage("HASIPBEENSET") var HASIPBEENSET = false
    var body: some View {
        NavigationView {
            VStack {
                    NavigationLink(destination: SecondView()) {
                        Text("Enable JIT")
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .onAppear{
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                                    if success {
                                        print("yay")
                                        allowednotification = true
                                    } else if let error {
                                        print(error.localizedDescription)
                                        allowednotification = false
                                    }
                                }
                            }
                }
            }
            .navigationTitle("SideJIT")
            .navigationBarItems(leading: PopupButtonText())
        }
    }
    
}

struct SecondView: View {
    @State private var jsonData: [Item] = []
    @AppStorage("username") var username = ""
    @AppStorage("password") var password = ""
    @AppStorage("allowednotification") var allowednotification = false
    @AppStorage("HASIPBEENSET") var HASIPBEENSET = false
    @State var isAuthenticating = false
    @State var showAlert = false
    @State var pressedbutton = ""
    @State var showAlert2 = false
    @State private var navigate = false
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        if HASIPBEENSET {
            VStack {
                List {
                    ForEach(jsonData, id: \.self) { item in
                        Button(action: {
                            print("Button tapped for \(item.name)")
                            pressedbutton = "\(item.name)"
                            getrequest()
                        }) {
                            Text(item.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color.purple)
                        }
                    }
                }
                Text("")
                    .alert("Error", isPresented: $showAlert2) {
                        Button("OK", role: .cancel) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    } message: {
                        Text("Please check your IP, UDID, and SideJITServer Console")
                    }
            }
            .onAppear {
                fetchData()
            }
            .navigationTitle("Apps")
        } else {
            Text("")
                .alert("SideJITServer Details", isPresented: $showAlert) {
                    TextField("IP Address", text: $username)
                        .foregroundColor(Color.purple)
                        .textInputAutocapitalization(.never)
                    TextField("UDID", text: $password)
                        .foregroundColor(Color.purple)
                    Button("OK", role: .cancel) {
                    authenticate()
                    self.presentationMode.wrappedValue.dismiss()
                        if username.hasPrefix("https://") && username.hasSuffix(":8080") {
                            username = "http://" + username.replacingOccurrences(of: "https://", with: "")
                        }
                    }
                    .foregroundColor(Color.purple)
                } message: {
                    Text("Please enter your Details.")
                }.onAppear{
                    showAlert = true
                }
        }
        
    }
    func authenticate() {
        HASIPBEENSET = true
    }
    
    private func fetchData() {
        let combinedString = username + "/" + password + "/"
        guard let url = URL(string: combinedString) else {
            print("Invalid URL")
            showAlert2 = true
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                showAlert2 = true
                return
            }
            
            if let data = data {
                print(String(data: data, encoding: .utf8) ?? "Invalid data")
                do {
                    let decodedData = try JSONDecoder().decode([Item].self, from: data)
                    DispatchQueue.main.async {
                        self.jsonData = decodedData
                    }
                } catch {
                    print("Error decoding data: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        showAlert2 = true
                    }
                }
            }
        }.resume()
    }
    
    private func getrequest() {
        let combinedString = username + "/" + password + "/" + pressedbutton + "/"
        guard let url = URL(string: combinedString) else {
            print("Invalid URL")
            showAlert2 = true
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                showAlert2 = true
                return
            }
            
            if let data = data {
                if allowednotification {
                    if let dataString = String(data: data, encoding: .utf8), dataString == "Enabled JIT for '\(pressedbutton)'!" {
                        let content = UNMutableNotificationContent()
                        content.title = "JIT Succsessfully Enabled"
                        content.subtitle = "JIT Enabled For \(pressedbutton)"
                        content.sound = UNNotificationSound.default

                        // show this notification five seconds from now
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

                        // choose a random identifier
                        let request = UNNotificationRequest(identifier: "EnabledJIT", content: content, trigger: nil)

                        // add our notification request
                        UNUserNotificationCenter.current().add(request)
                    } else {
                        let content = UNMutableNotificationContent()
                        content.title = "An Error Occured"
                        content.subtitle = "Please check your SideJITServer Console"
                        content.sound = UNNotificationSound.default

                        // show this notification five seconds from now
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

                        // choose a random identifier
                        let request = UNNotificationRequest(identifier: "EnabledJITError", content: content, trigger: nil)

                        // add our notification request
                        UNUserNotificationCenter.current().add(request)
                    }
                }
            }
        }.resume()
    }
}


struct Item: Codable, Hashable {
    let bundle: String
    let name: String
    let pid: Int
}


struct ContinueButton: View {
    let text: String
    var body: some View{
        Text(text)
            .frame(width: 200, height: 50, alignment: .center)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(25)
    }
}

struct PopupButtonText: View {
    @State var isAuthenticating = false
    @AppStorage("username") var username = ""
    @AppStorage("password") var password = ""
    @AppStorage("HASIPBEENSET") var HASIPBEENSET = false
    @State private var jsonData = ""
    var body: some View {
        Button(action: {
            isAuthenticating.toggle()
            //fetchData2()
        }) {
            Image(systemName: "gearshape.fill")
        }
        .foregroundColor(Color.purple)
        .alert("SideJIT Settings", isPresented: $isAuthenticating) {
            TextField("IP Address", text: $username)
                .textInputAutocapitalization(.never)
            TextField("UDID", text: $password)
            Button("OK", role: .cancel) {
                authenticate()
                if username.hasPrefix("https://") && username.hasSuffix(":8080") {
                    username = "http://" + username.replacingOccurrences(of: "https://", with: "")
                }
            }
            Button("Refresh", action: refresh1)
        } message: {
            Text("You can edit your SideJITServer Details or Refresh")
        }
    }
    func authenticate() {
        HASIPBEENSET = true
    }
    func refresh1() {
        let combinedString2 = username + "/re/"
        guard let url = URL(string: combinedString2) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                print(String(data: data, encoding: .utf8) ?? "Invalid data")
                do {
                    let decodedData = try JSONDecoder().decode([Item].self, from: data)
                    print(decodedData)
                } catch {
                    print("Error decoding data: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    private func fetchData2() {
        let combinedString = username + "/ver/"
        guard let url = URL(string: combinedString) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                do {
                    let decodedData = try JSONDecoder().decode([String: String].self, from: data)
                    DispatchQueue.main.async {
                        self.jsonData = decodedData.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
                        print(jsonData)
                    }
                } catch {
                    print("Error decoding data: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}





#Preview {
    ContentView()
}
