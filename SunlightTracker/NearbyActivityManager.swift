import Foundation
import MultipeerConnectivity
import Combine

#if canImport(NearbyInteraction)
import NearbyInteraction
#endif

@MainActor
class NearbyActivityManager: NSObject, ObservableObject {

    // MARK: - Published
    @Published var isSharedActivityActive = false
    @Published var sharedColorTheme: SharedColorTheme?
    @Published var connectedPeerCount = 0
    @Published var nearbyPeerDistance: Float?

    // MARK: - MultipeerConnectivity
    private let serviceType = "suntracker-ni"
    private let myPeerID: MCPeerID
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!

    // MARK: - NearbyInteraction
    #if canImport(NearbyInteraction)
    private var niSession: NISession?
    #endif

    // MARK: - State
    private var localTrackingPhase: String = "idle"
    private var peerTrackingPhases: [MCPeerID: String] = [:]
    private var colorSeed: UInt64?

    override init() {
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
    }

    // MARK: - Discovery Control

    func startDiscovery() {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self

        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()

        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
    }

    func stopDiscovery() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()

        #if canImport(NearbyInteraction)
        niSession?.invalidate()
        niSession = nil
        #endif

        peerTrackingPhases.removeAll()
        isSharedActivityActive = false
        sharedColorTheme = nil
        connectedPeerCount = 0
        nearbyPeerDistance = nil
        colorSeed = nil
    }

    // MARK: - Tracking State

    func updateTrackingPhase(_ phase: String) {
        localTrackingPhase = phase
        sendTrackingState(phase)
        evaluateSharedActivity()
    }

    // MARK: - Message Sending

    private func sendTrackingState(_ phase: String) {
        let msg = PeerMessage(type: .trackingState, trackingPhase: phase, tokenData: nil, colorSeed: nil)
        sendMessage(msg)
    }

    private func sendColorSeed(_ seed: UInt64) {
        let msg = PeerMessage(type: .colorSeed, trackingPhase: nil, tokenData: nil, colorSeed: seed)
        sendMessage(msg)
    }

    private func sendMessage(_ message: PeerMessage) {
        guard let data = try? JSONEncoder().encode(message),
              !session.connectedPeers.isEmpty else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }

    #if canImport(NearbyInteraction)
    private func sendDiscoveryToken(_ token: NIDiscoveryToken) {
        guard let tokenData = try? NSKeyedArchiver.archivedData(
            withRootObject: token, requiringSecureCoding: true
        ) else { return }
        let msg = PeerMessage(type: .discoveryToken, trackingPhase: nil, tokenData: tokenData, colorSeed: nil)
        sendMessage(msg)
    }
    #endif

    // MARK: - Shared Activity Evaluation

    private func evaluateSharedActivity() {
        let peerConfirmed = peerTrackingPhases.values.contains("confirmed")
        let localConfirmed = localTrackingPhase == "confirmed"
        let newActive = localConfirmed && peerConfirmed

        if newActive && !isSharedActivityActive {
            isSharedActivityActive = true
            negotiateColorSeed()
        } else if !newActive && isSharedActivityActive {
            isSharedActivityActive = false
        }
    }

    private func negotiateColorSeed() {
        guard let firstPeer = session.connectedPeers.first else { return }
        let localName = myPeerID.displayName
        let peerName = firstPeer.displayName

        // 사전순 작은 쪽이 시드 생성
        if localName < peerName {
            let seed = UInt64.random(in: 1...UInt64.max)
            self.colorSeed = seed
            let isLocalA = true
            self.sharedColorTheme = SharedColorTheme(seed: seed, isLocalVariantA: isLocalA)
            sendColorSeed(seed)
        }
        // 큰 쪽은 시드 수신 대기
    }

    // MARK: - Handle Received Message

    nonisolated private func handleReceivedData(_ data: Data, from peer: MCPeerID) {
        guard let msg = try? JSONDecoder().decode(PeerMessage.self, from: data) else { return }

        Task { @MainActor in
            switch msg.type {
            case .trackingState:
                if let phase = msg.trackingPhase {
                    peerTrackingPhases[peer] = phase
                    evaluateSharedActivity()
                }

            case .colorSeed:
                if let seed = msg.colorSeed {
                    self.colorSeed = seed
                    let localName = self.myPeerID.displayName
                    let peerName = peer.displayName
                    let isLocalA = localName < peerName
                    self.sharedColorTheme = SharedColorTheme(seed: seed, isLocalVariantA: isLocalA)
                }

            case .discoveryToken:
                #if canImport(NearbyInteraction)
                if let tokenData = msg.tokenData,
                   let token = try? NSKeyedUnarchiver.unarchivedObject(
                       ofClass: NIDiscoveryToken.self, from: tokenData
                   ) {
                    self.startNISession(with: token)
                }
                #endif
                break
            }
        }
    }

    // MARK: - NearbyInteraction Session

    #if canImport(NearbyInteraction)
    private func startNISession(with peerToken: NIDiscoveryToken) {
        guard NISession.isSupported else { return }

        if niSession == nil {
            niSession = NISession()
            niSession?.delegate = self
        }

        let config = NINearbyPeerConfiguration(peerToken: peerToken)
        niSession?.run(config)
    }

    private func shareMyDiscoveryToken() {
        guard let token = niSession?.discoveryToken else { return }
        sendDiscoveryToken(token)
    }
    #endif
}

// MARK: - MCSessionDelegate
extension NearbyActivityManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            self.connectedPeerCount = session.connectedPeers.count

            switch state {
            case .connected:
                // 연결 후 트래킹 상태 교환
                self.sendTrackingState(self.localTrackingPhase)

                // NI 토큰 교환
                #if canImport(NearbyInteraction)
                if NISession.isSupported {
                    if self.niSession == nil {
                        self.niSession = NISession()
                        self.niSession?.delegate = self
                    }
                    self.shareMyDiscoveryToken()
                }
                #endif

            case .notConnected:
                self.peerTrackingPhases.removeValue(forKey: peerID)
                self.evaluateSharedActivity()
                if session.connectedPeers.isEmpty {
                    self.nearbyPeerDistance = nil
                }

            default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        handleReceivedData(data, from: peerID)
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName: String, fromPeer: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension NearbyActivityManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Advertiser failed: \(error.localizedDescription)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension NearbyActivityManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Browser failed: \(error.localizedDescription)")
    }
}

// MARK: - NISessionDelegate
#if canImport(NearbyInteraction)
extension NearbyActivityManager: NISessionDelegate {
    nonisolated func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let nearest = nearbyObjects.first else { return }
        Task { @MainActor in
            self.nearbyPeerDistance = nearest.distance
        }
    }

    nonisolated func session(_ session: NISession, didInvalidateWith error: Error) {
        Task { @MainActor in
            self.niSession = nil
            self.nearbyPeerDistance = nil
        }
    }

    nonisolated func sessionWasSuspended(_ session: NISession) {}
    nonisolated func sessionSuspensionEnded(_ session: NISession) {}
}
#endif
