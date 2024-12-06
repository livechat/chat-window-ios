//
//  ContentView.swift
//  Example-SwiftUI
//
//  Created by Kamil Szostakowski on 06/12/2024.
//

import LiveChat
import SwiftUI
import MapKit

struct ContentView: View {
    @State var shouldPresentSheet = false
    @State var shouldPresentAlert = false
    @State var alertMessage: String = ""
        
    let chatWindowDelegate = ChatWindow.Delegate()
    var body: some View {
        ZStack {
            Map().mapStyle(.standard)
            VStack {
                Spacer()
                OptionButton(label: "Open Chat", action: openChatWithStandardPresentation)
                OptionButton(label: "Open Chat (Custom presentation)", action: openChatWithCustomPresentation)
                    .sheet(isPresented: $shouldPresentSheet) {
                        Chat()
                    }
                OptionButton(label: "Clear Session") {
                    LiveChat.clearSession()
                }
            }
            .frame(alignment: .bottom)
            .padding(.horizontal, 20)
            .alert(isPresented: $shouldPresentAlert) {
                Alert(
                    title: Text("Support"),
                    message: Text(alertMessage),
                    primaryButton: .cancel(),
                    secondaryButton: .default(Text("Go to chat"), action: {
                        if !LiveChat.isChatPresented {
                            openChatWithStandardPresentation()
                        }
                    })
                )
            }
        }
        .onAppear(perform: setupChatWindow)
    }
    
    private func setupChatWindow() {
        chatWindowDelegate.onDismiss = dismissChat
        chatWindowDelegate.onAlert = displayAlert
        ChatWindow.setup(with: chatWindowDelegate)
    }
    
    private func openChatWithStandardPresentation() {
        LiveChat.customPresentationStyleEnabled = false
        LiveChat.presentChat()
    }
    
    private func openChatWithCustomPresentation() {
        LiveChat.customPresentationStyleEnabled = true
        shouldPresentSheet = true
    }
    
    private func dismissChat() {
        if LiveChat.customPresentationStyleEnabled {
            shouldPresentSheet = false
        } else {
            LiveChat.dismissChat()
        }
    }
    
    private func displayAlert(_ message: String) {
        alertMessage = message
        shouldPresentAlert = true
    }
}

struct OptionButton: View {
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label).frame(maxWidth: .infinity)
        }
            .buttonStyle(.borderedProminent)
    }
}

struct Chat: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController
    
    func makeUIViewController(context: Context) -> UIViewController {
        LiveChat.chatViewController ?? UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

#Preview {
    ContentView()
}
