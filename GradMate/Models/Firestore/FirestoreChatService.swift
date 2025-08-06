import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirestoreChatService: ChatServiceProtocol, ObservableObject {
    private var chatListener: ListenerRegistration?
    private var messageListener: ListenerRegistration?
    private var db: Firestore {
        Firestore.firestore()
    }
    
    func loadChats(for userId: String, completion: @escaping ([Chat], Error?) -> Void) {
        print("[DEBUG] Loading chats for userId: \(userId)")
        print("[DEBUG] FirestoreChatService - Firestore instance: \(db)")
        chatListener?.remove()
        
        chatListener = db.collection("chats")
            .whereField("participants", arrayContains: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("[DEBUG] Error loading chats: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion([], error)
                    }
                    return
                }
                guard let documents = snapshot?.documents else {
                    print("[DEBUG] No chat documents found")
                    DispatchQueue.main.async {
                        completion([], nil)
                    }
                    return
                }
                
                print("[DEBUG] Found \(documents.count) chat documents")
                let chats = documents.compactMap { doc -> Chat? in
                    let data = doc.data() 
                    let id = doc.documentID
                    let participants = data["participants"] as? [String] ?? []
                    print("[DEBUG] Chat \(id) participants: \(participants)")
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
                
                print("[DEBUG] Returning \(chats.count) chats")
                DispatchQueue.main.async {
                    completion(chats, nil)
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
        print("[DEBUG] Sending message to chat \(chatId): \(text)")
        print("[DEBUG] Sender ID: \(senderId)")
        
        // First, let's verify the chat exists and user is a participant
        db.collection("chats").document(chatId).getDocument { [weak self] doc, error in
            if let error = error {
                print("[DEBUG] Error fetching chat: \(error.localizedDescription)")
                completion?(error)
                return
            }
            
            guard let doc = doc, doc.exists, let data = doc.data() else {
                print("[DEBUG] Chat document not found")
                completion?(NSError(domain: "ChatError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Chat not found"]))
                return
            }
            
            let participants = data["participants"] as? [String] ?? []
            print("[DEBUG] Chat participants: \(participants)")
            print("[DEBUG] Is sender in participants: \(participants.contains(senderId))")
            
            guard participants.contains(senderId) else {
                print("[DEBUG] Sender is not a participant in this chat")
                completion?(NSError(domain: "ChatError", code: 403, userInfo: [NSLocalizedDescriptionKey: "Not a participant in this chat"]))
                return
            }
            
            let messageData: [String: Any] = [
                "senderId": senderId,
                "text": text,
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            self?.db.collection("chats").document(chatId).collection("messages").addDocument(data: messageData) { error in
                if let error = error {
                    print("[DEBUG] Error sending message: \(error.localizedDescription)")
                    completion?(error)
                } else {
                    print("[DEBUG] Message sent successfully")
                    completion?(nil)
                }
            }
        }
        
        // Update lastMessage in chat doc
        db.collection("chats").document(chatId).updateData([
            "lastMessage": [
                "text": text,
                "senderId": senderId,
                "timestamp": FieldValue.serverTimestamp()
            ]
        ]) { error in
            if let error = error {
                print("[DEBUG] Error updating lastMessage: \(error.localizedDescription)")
            } else {
                print("[DEBUG] LastMessage updated successfully")
            }
        }
    }
    
    func createChat(participants: [String], isGroup: Bool, name: String?, completion: @escaping (String?) -> Void) {
        print("[DEBUG] Creating chat with participants: \(participants), isGroup: \(isGroup)")
        var data: [String: Any] = [
            "participants": participants,
            "createdAt": FieldValue.serverTimestamp(),
            "isGroup": isGroup
        ]
        if let name = name { data["name"] = name }
        
        print("[DEBUG] Chat data to save: \(data)")
        let ref = db.collection("chats").document()
        ref.setData(data) { error in
            if let error = error {
                print("[DEBUG] Error creating chat: \(error.localizedDescription)")
                completion(nil)
            } else {
                print("[DEBUG] Chat created successfully with ID: \(ref.documentID)")
                completion(ref.documentID)
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
        print("[DEBUG] Stopping chat listeners")
        chatListener?.remove()
        messageListener?.remove()
        chatListener = nil
        messageListener = nil
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
    
    // Find an existing 1-1 chat between two users (by UIDs)
    func findDirectChat(between user1: String, and user2: String, completion: @escaping (Chat?) -> Void) {
        db.collection("chats")
            .whereField("isGroup", isEqualTo: false)
            .whereField("participants", arrayContains: user1)
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else {
                    completion(nil)
                    return
                }
                for doc in docs {
                    let data = doc.data()
                    let participants = data["participants"] as? [String] ?? []
                    if Set(participants) == Set([user1, user2]) {
                        let id = doc.documentID
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
                        return
                    }
                }
                completion(nil)
            }
    }
    
    // MARK: - Chat Request System
    // Only create chat request document, do NOT create chat here
    func sendChatRequest(from senderId: String, to recipientId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let requestId = "\(senderId)_\(recipientId)"
        
        // First get the sender's user information
        db.collection("users").document(senderId).getDocument { doc, error in
            guard let userData = doc?.data() else {
                completion(false)
                return
            }
            
            let data: [String: Any] = [
                "fromUserId": senderId,
                "toUserId": recipientId,
                "fromDisplayName": userData["name"] as? String ?? "",
                "fromUsername": userData["username"] as? String ?? "",
                "fromPhotoURL": userData["photoURL"] as? String ?? "",
                "status": "pending",
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            db.collection("chatRequests").document(requestId).setData(data) { error in
                completion(error == nil)
            }
        }
    }

    // Only create chat when request is accepted
    func acceptChatRequest(from senderId: String, to recipientId: String, completion: @escaping (Bool) -> Void) {
        print("[DEBUG] Accepting chat request from \(senderId) to \(recipientId)")
        let db = Firestore.firestore()
        let requestId = "\(senderId)_\(recipientId)"
        
        db.collection("chatRequests").document(requestId).updateData(["status": "accepted"]) { error in
            if let error = error {
                print("[DEBUG] Error updating chat request status: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            print("[DEBUG] Chat request status updated to accepted, creating chat...")
            // Create chat document only now
            self.createChat(participants: [senderId, recipientId], isGroup: false, name: nil) { chatId in
                if let chatId = chatId {
                    print("[DEBUG] Chat created successfully with ID: \(chatId)")
                    completion(true)
                } else {
                    print("[DEBUG] Failed to create chat")
                    completion(false)
                }
            }
        }
    }

    func declineChatRequest(from senderId: String, to recipientId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let requestId = "\(senderId)_\(recipientId)"
        db.collection("chatRequests").document(requestId).updateData(["status": "declined"]) { error in
            completion(error == nil)
        }
    }

    func checkChatRequestStatus(from senderId: String, to recipientId: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        let requestId = "\(senderId)_\(recipientId)"
        db.collection("chatRequests").document(requestId).getDocument { doc, error in
            if let data = doc?.data(), let status = data["status"] as? String {
                completion(status)
            } else {
                completion(nil)
            }
        }
    }

    func fetchIncomingChatRequests(for userId: String, completion: @escaping ([DocumentSnapshot]) -> Void) {
        let db = Firestore.firestore()
        db.collection("chatRequests")
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                completion(snapshot?.documents ?? [])
            }
    }
    
    deinit {
        stopListening()
    }
} 
