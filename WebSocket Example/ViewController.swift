//
//  ViewController.swift
//  WebSocket Example
//
//  Created by Nishant Taneja on 07/08/23.
//

import UIKit
import WhatsNew

final class ViewController: UIViewController, URLSessionWebSocketDelegate, UITextFieldDelegate {
    // MARK: - Properties
    private let url = URL(string: "wss://free.blr1.piesocket.com/v3/1?api_key=3crxmv1bqayw5mtS4hRTeyic3bwnp4UTrsaOPOU5&notify_self=1")!
    private var webSocket: URLSessionWebSocketTask? = nil
    private var responses: [String] = []
    private var connectionIsEstablished: Bool = false
    
    
    // MARK: - Views
    @IBOutlet private weak var connectionStatusLabel: UILabel!
    @IBOutlet private weak var responseTextView: UITextView!
    @IBOutlet private weak var newMessageTextField: UITextField!
    @IBOutlet weak var sendNewMessageButton: UIButton!
    @IBOutlet weak var openConnectionButton: UIButton!
    @IBOutlet weak var closeConnectionButton: UIButton!
    
    private func insertResponse(_ text: String) {
        DispatchQueue.main.async {
            self.responses.insert("[Response \(self.responses.count)]: " + text, at: .zero)
            self.responseTextView.text = self.responses.joined(separator: "\n")
        }
    }
    private func setConnectionIsEstablished(_ value: Bool) {
        DispatchQueue.main.async {
            self.connectionIsEstablished = value
            self.sendNewMessageButton.isEnabled = value && (self.newMessageTextField.text?.replacingOccurrences(of: " ", with: "").isEmpty == false)
            self.closeConnectionButton.isEnabled = value
            self.openConnectionButton.isEnabled = !value
            self.connectionStatusLabel.text = "Connection is \(value ? "Open" : "Closed")."
        }
    }
    
    // MARK: UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text ?? "") + string
        sendNewMessageButton.isEnabled = (text.replacingOccurrences(of: " ", with: "").isEmpty == false) && connectionIsEstablished
        return true
    }
    
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setConnectionIsEstablished(false)
        newMessageTextField.delegate = self
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        displayWhatsNew()
    }


    // MARK: - Interactions
    @IBAction private func handleActionForSendNewMessage(_ sender: UIButton) {
        guard let newMessage = newMessageTextField.text, newMessage.replacingOccurrences(of: " ", with: "").isEmpty == false else { return }
        newMessageTextField.text = nil
        sendNewMessageButton.isEnabled = false
        webSocket?.send(.string(newMessage), completionHandler: { error in
            guard let error else { return }
            DispatchQueue.main.async {
                self.connectionStatusLabel.text = "Unable to send message"
            }
            debugPrint(error)
            DispatchQueue.main.asyncAfter(deadline: .now()+4) {
                self.connectionStatusLabel.text = "Connection is \(self.connectionIsEstablished ? "Open" : "Closed")."
            }
        })
    }
    @IBAction private func handleActionForOpenConnection(_ sender: UIButton) {
        createWebSocket()
    }
    @IBAction private func handleActionForCloseConnection(_ sender: UIButton) {
        webSocket?.cancel(with: .normalClosure, reason: nil)
    }
    
    
    // MARK: - WebSocket
    private func createWebSocket() {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .init())
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
    }
    private func receiveData() {
        debugPrint(#function)
        webSocket?.receive(completionHandler: { result in
            debugPrint(#function, result)
            self.receiveData()

            switch result {
            case .success(let success):
                switch success {
                case .string(let message):
                    self.insertResponse(message)
                case .data(let data):
                    debugPrint(data)
                @unknown default: break
                }
            case .failure(let failure):
                DispatchQueue.main.async {
                    self.connectionStatusLabel.text = "Unable to send message"
                }
                debugPrint(failure)
                DispatchQueue.main.asyncAfter(deadline: .now()+4) {
                    self.connectionStatusLabel.text = "Connection is \(self.connectionIsEstablished ? "Open" : "Closed")."
                }
            }
        })
    }
    
    // MARK: URLSessionDelegate
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        webSocket?.sendPing(pongReceiveHandler: { error in
            self.setConnectionIsEstablished(error == nil)
            guard let error else { return }
            DispatchQueue.main.async {
                self.connectionStatusLabel.text = "Unable to send ping"
            }
            debugPrint(error)
            DispatchQueue.main.asyncAfter(deadline: .now()+4) {
                self.connectionStatusLabel.text = "Connection is \(self.connectionIsEstablished ? "Open" : "Closed")."
            }
        })
        receiveData()
    }
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        setConnectionIsEstablished(false)
    }
}


// MARK: - What's New
extension ViewController: WNViewControllerDataSource, WNViewControllerDelegate {
    private func displayWhatsNew() {
        let controller = WNViewController()
        controller.dataSource = self
        controller.delegate = self
        present(controller, animated: true)
    }
    
    // MARK: DataSource
    func itemsForWhatsNewViewController() -> [WNItem] {
        [
            WNItem(image: .init(systemName: "pencil.tip.crop.circle")!, title: "UI Improvements", description: "Basic UI improvements including background colors and paddings."),
            WNItem(image: .init(systemName: "newspaper")!, title: "What's New", description: "Discover new features. When new features are added, they will be displayed here."),
            WNItem(image: .init(systemName: "lasso.badge.sparkles")!, title: "WebSocket Implementation", description: "Open a connection and start sending messages. Received messages will be displayed under Responses.")
        ]
    }
    
    // MARK: Delegate
    func whatsNewViewControllerDidSelectContinue() {
        
    }
}
