import MultipeerConnectivity
import Combine

class MultipeerManager: NSObject, ObservableObject {
    private let serviceType = "profile-share"
    private let myPeerId: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var receivedProfiles: [Profile] = []
    @Published var isAdvertising = false
    @Published var isBrowsing = false
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var myProfile: Profile {
        didSet {
            print("Profile updated: \(myProfile)")
            sendProfile()  // プロフィールが更新されたら自動的に送信
        }
    }
    
    init(myProfile: Profile) {
        self.myProfile = myProfile
        self.myPeerId = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        self.session.delegate = self
        setupPublishers()
    }
    
    private func setupPublishers() {
        $isAdvertising
            .sink { [weak self] isAdvertising in
                if isAdvertising {
                    self?.startAdvertising()
                } else {
                    self?.stopAdvertising()
                }
            }
            .store(in: &cancellables)
        
        $isBrowsing
            .sink { [weak self] isBrowsing in
                if isBrowsing {
                    self?.startBrowsing()
                } else {
                    self?.stopBrowsing()
                }
            }
            .store(in: &cancellables)
    }
    
    func startSharing() {
        isAdvertising = true
        isBrowsing = true
    }
    
    func stopSharing() {
        isAdvertising = false
        isBrowsing = false
    }
    
    private func startAdvertising() {
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        print("Started advertising")
    }
    
    private func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        print("Stopped advertising")
    }
    
    private func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        print("Started browsing")
    }
    
    private func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        print("Stopped browsing")
    }
    
    func sendProfile() {
        guard !myProfile.name.isEmpty else {
            print("Cannot send empty profile")
            return
        }
        
        guard let profileData = try? JSONEncoder().encode(myProfile) else {
            print("Failed to encode profile")
            return
        }
        
        print("Sending profile: \(myProfile)")
        
        do {
            try session.send(profileData, toPeers: session.connectedPeers, with: .reliable)
            print("Sent profile to \(session.connectedPeers.count) peers")
        } catch {
            print("Failed to send profile: \(error)")
        }
    }
    
    private func handleReceivedProfile(_ profileData: Data) {
        do {
            let profile = try JSONDecoder().decode(Profile.self, from: profileData)
            print("Received profile data: \(String(data: profileData, encoding: .utf8) ?? "Unable to convert to string")")
            print("Decoded profile: \(profile)")
            
            DispatchQueue.main.async {
                if !self.receivedProfiles.contains(where: { $0.id == profile.id }) {
                    self.receivedProfiles.append(profile)
                    print("Added new profile: \(profile.name)")
                } else {
                    print("Received duplicate profile: \(profile.name)")
                }
            }
        } catch {
            print("Failed to decode received profile: \(error)")
        }
    }
    
    func updateProfile(_ newProfile: Profile) {
        self.myProfile = newProfile
    }
}

extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("Peer \(peerID.displayName) changed state: \(state)")
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                    self.sendProfile()
                }
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
            case .connecting:
                break
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("Received data from peer: \(peerID.displayName)")
        handleReceivedProfile(data)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Received invitation from \(peerID.displayName)")
        invitationHandler(true, session)
    }
}

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
    }
}
