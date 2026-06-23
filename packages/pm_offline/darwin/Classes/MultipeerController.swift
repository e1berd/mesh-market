#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif
import MultipeerConnectivity

private let serviceType = "mesh-market"

class MultipeerController: NSObject, FlutterStreamHandler {
    private var sink: FlutterEventSink?
    private var localPeerId = ""
    private var localPeer: MCPeerID?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    private var sessions: [String: MCSession] = [:]
    private var sessionPeers: [String: MCPeerID] = [:]
    private var sessionMeta: [String: (peerId: String, folderId: String)] = [:]
    private var outbound: Set<String> = []
    private var foundPeers: [MCPeerID: [String: String]] = [:]

    func onListen(withArguments _: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        sink = eventSink
        return nil
    }

    func onCancel(withArguments _: Any?) -> FlutterError? {
        sink = nil
        return nil
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isSupported":
            result(true)
        case "start":
            let args = call.arguments as? [String: Any]
            start(deviceId: args?["deviceId"] as? String ?? "")
            result(nil)
        case "open":
            let args = call.arguments as? [String: Any]
            result(open(
                peerId: args?["peerId"] as? String ?? "",
                folderId: args?["folderId"] as? String ?? ""))
        case "send":
            let args = call.arguments as? [String: Any]
            send(
                sessionId: args?["sessionId"] as? String ?? "",
                data: args?["data"] as? FlutterStandardTypedData)
            result(nil)
        case "close":
            let args = call.arguments as? [String: Any]
            closeSession(args?["sessionId"] as? String ?? "")
            result(nil)
        case "stop":
            stop()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func start(deviceId: String) {
        stop()
        localPeerId = deviceId
        let displayName = String(deviceId.prefix(20))
        let peer = MCPeerID(displayName: displayName.isEmpty ? "peer" : displayName)
        localPeer = peer
        let adv = MCNearbyServiceAdvertiser(
            peer: peer, discoveryInfo: ["id": deviceId], serviceType: serviceType)
        adv.delegate = self
        adv.startAdvertisingPeer()
        advertiser = adv
        let brw = MCNearbyServiceBrowser(peer: peer, serviceType: serviceType)
        brw.delegate = self
        brw.startBrowsingForPeers()
        browser = brw
    }

    private func open(peerId: String, folderId: String) -> String {
        guard let local = localPeer else { return "" }
        let sessionId = UUID().uuidString
        let session = MCSession(
            peer: local, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        sessions[sessionId] = session
        sessionMeta[sessionId] = (peerId, folderId)
        outbound.insert(sessionId)
        if let entry = foundPeers.first(where: { $0.value["id"] == peerId }) {
            sessionPeers[sessionId] = entry.key
            browser?.invitePeer(
                entry.key, to: session, withContext: inviteContext(folderId),
                timeout: 30)
        }
        return sessionId
    }

    private func send(sessionId: String, data: FlutterStandardTypedData?) {
        guard let session = sessions[sessionId], let peer = sessionPeers[sessionId],
            let payload = data?.data else { return }
        try? session.send(payload, toPeers: [peer], with: .reliable)
    }

    private func closeSession(_ sessionId: String) {
        sessions[sessionId]?.disconnect()
        sessions[sessionId] = nil
        sessionPeers[sessionId] = nil
        sessionMeta[sessionId] = nil
        outbound.remove(sessionId)
    }

    private func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
        for id in Array(sessions.keys) { closeSession(id) }
        foundPeers.removeAll()
    }

    private func inviteContext(_ folderId: String) -> Data {
        return "\(localPeerId)|\(folderId)".data(using: .utf8) ?? Data()
    }

    private func emit(_ payload: [String: Any?]) {
        DispatchQueue.main.async { self.sink?(payload) }
    }

    private func sessionId(for session: MCSession) -> String? {
        return sessions.first(where: { $0.value === session })?.key
    }
}

extension MultipeerController: MCNearbyServiceBrowserDelegate {
    func browser(
        _: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        foundPeers[peerID] = info ?? [:]
    }

    func browser(_: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        foundPeers[peerID] = nil
    }
}

extension MultipeerController: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        guard let local = localPeer else {
            invitationHandler(false, nil)
            return
        }
        let sessionId = UUID().uuidString
        let session = MCSession(
            peer: local, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        sessions[sessionId] = session
        sessionPeers[sessionId] = peerID
        let decoded = context.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let parts = decoded.split(separator: "|", maxSplits: 1).map(String.init)
        let remoteId = parts.count > 0 ? parts[0] : peerID.displayName
        let folderId = parts.count > 1 ? parts[1] : ""
        sessionMeta[sessionId] = (remoteId, folderId)
        invitationHandler(true, session)
    }
}

extension MultipeerController: MCSessionDelegate {
    func session(
        _ session: MCSession, peer _: MCPeerID, didChange state: MCSessionState
    ) {
        guard let id = sessionId(for: session), let meta = sessionMeta[id] else { return }
        switch state {
        case .connected:
            emit([
                "type": outbound.contains(id) ? "connected" : "incoming",
                "sessionId": id, "peerId": meta.peerId, "folderId": meta.folderId,
            ])
        case .notConnected:
            emit(["type": "closed", "sessionId": id])
            closeSession(id)
        default:
            break
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer _: MCPeerID) {
        guard let id = sessionId(for: session) else { return }
        emit(["type": "data", "sessionId": id, "data": FlutterStandardTypedData(bytes: data)])
    }

    func session(
        _: MCSession, didReceive _: InputStream, withName _: String, fromPeer _: MCPeerID
    ) {}
    func session(
        _: MCSession, didStartReceivingResourceWithName _: String, fromPeer _: MCPeerID,
        with _: Progress
    ) {}
    func session(
        _: MCSession, didFinishReceivingResourceWithName _: String, fromPeer _: MCPeerID,
        at _: URL?, withError _: Error?
    ) {}
}
