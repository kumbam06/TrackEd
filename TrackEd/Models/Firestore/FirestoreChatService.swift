import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirestoreChatService: ChatServiceProtocol, ObservableObject {
    private var chatListener: ListenerRegistration?
    private var messageListener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    func loadChats(for userId: String, completion: @escaping ([Chat]) -> Void) {
        chatListener?.remove()
        chatListener = db.collection("chats")
            .whereField("participants", arrayContains: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let chats = documents.compactMap { doc -> Chat? in
                    let data = doc.data()
                    let id = doc.documentID
                    let participants = data["participants"] as? [String] ?? []
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let isGroup = data["isGroup"] as? Bool ?? false
                    let name = data["name"] as? String
                    var lastMessage: Message? = nil
                    if let last = data["lastMessage"] as? [String: Any],
                       let text = last["text"] as? String,
                       let senderId = last["senderId"] as? String,
                       let ts = last["timestamp"] as? Timestamp {
                        lastMessage = Message(id: UUID().uuidString, senderId: senderId, text: text, timestamp: ts.dateValue())
                    }
                    return Chat(id: id, participants: participants, createdAt: createdAt, isGroup: isGroup, name: name, lastMessage: lastMessage)
                }
                DispatchQueue.main.async {
                    completion(chats)
                }
            }
    }
    
    func listenForMessages(chatId: String, onUpdate: @escaping ([Message]) -> Void) {
        messageListener?.remove()
        messageListener = db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    onUpdate([])
                    return
                }
                let messages = documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    let id = doc.documentID
                    let senderId = data["senderId"] as? String ?? ""
                    let text = data["text"] as? String ?? ""
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    return Message(id: id, senderId: senderId, text: text, timestamp: timestamp)
                }
                DispatchQueue.main.async {
                    onUpdate(messages)
                }
            }
    }
    
    func sendMessage(chatId: String, text: String, senderId: String, completion: ((Error?) -> Void)?) {
        let messageData: [String: Any] = [
            "senderId": senderId,
            "text": text,
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("chats").document(chatId).collection("messages").addDocument(data: messageData) { error in
            completion?(error)
        }
        // Update lastMessage in chat doc
        db.collection("chats").document(chatId).updateData([
            "lastMessage": [
                "text": text,
                "senderId": senderId,
                "timestamp": FieldValue.serverTimestamp()
            ]
        ])
    }
    
    func createChat(participants: [String], isGroup: Bool, name: String?, completion: @escaping (String?) -> Void) {
        var data: [String: Any] = [
            "participants": participants,
            "createdAt": FieldValue.serverTimestamp(),
            "isGroup": isGroup
        ]
        if let name = name { data["name"] = name }
        let ref = db.collection("chats").document()
        ref.setData(data) { error in
            if error == nil {
                completion(ref.documentID)
            } else {
                completion(nil)
            }
        }
    }
    
    func fetchChatById(_ chatId: String, completion: @escaping (Chat?) -> Void) {
        db.collection("chats").document(chatId).getDocument { doc, error in
            guard let doc = doc, doc.exists, let data = doc.data() else {
                completion(nil)
                return
            }
            let id = doc.documentID
            let participants = data["participants"] as? [String] ?? []
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            let isGroup = data["isGroup"] as? Bool ?? false
            let name = data["name"] as? String
            var lastMessage: Message? = nil
            if let last = data["lastMessage"] as? [String: Any],
               let text = last["text"] as? String,
               let senderId = last["senderId"] as? String,
               let ts = last["timestamp"] as? Timestamp {
                lastMessage = Message(id: UUID().uuidString, senderId: senderId, text: text, timestamp: ts.dateValue())
            }
            let chat = Chat(id: id, participants: participants, createdAt: createdAt, isGroup: isGroup, name: name, lastMessage: lastMessage)
            completion(chat)
        }
    }
    
    func stopListening() {
        chatListener?.remove()
        messageListener?.remove()
    }
    
    func lookupUserId(byUsername username: String, completion: @escaping (String?) -> Void) {
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let doc = snapshot?.documents.first {
                completion(doc.documentID)
            } else {
                completion(nil)
            }
        }
    }
    
    deinit {
        stopListening()
    }
} 