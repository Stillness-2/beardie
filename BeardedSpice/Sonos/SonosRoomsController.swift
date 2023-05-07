//
//  SonosRoomsController.swift
//  Beardie
//
//  Created by Roman Sokolov on 29.06.2021.
//  Copyright © 2021 GPL v3 http://www.gnu.org/licenses/gpl.html
//

import Cocoa
import CocoaLumberjack
import RxSwift
import RxSonosLib

extension UserDefaultsKeys {
    static let SonosSupport = "SonosSupport" //Bool
    static let DisabledSonosRooms = "DisabledSonosRooms" // [String]
}

@objc(SonosRoom) protocol SonosRoom {
    @objc var displayName: String {get}
    @objc var enabled: Bool {get set}
}

final class SonosRoomsController: NSObject {
    
    // MARK: Constants
    
    static let groupObtainTimeout: TimeInterval = 10
    static let requestTimeout: TimeInterval = 2
    
    @objc static let SonosRoomsChanged = Notification.Name("SonosRoomsChanged")
    
    // MARK: Public
    @objc static let singleton = SonosRoomsController()
    
    @objc var tabs = [SonosTabAdapter]()
    @objc var rooms = [SonosRoom]()
    
    override init() {
        
        super.init()
        
        SonosSettings.shared.renewGroupsTimer = Self.groupObtainTimeout
        SonosSettings.shared.requestTimeout = Self.requestTimeout

        if UserDefaults.standard.bool(forKey: UserDefaultsKeys.SonosSupport) {
            self.disabledRoomIds = Set(UserDefaults.standard.stringArray(forKey:UserDefaultsKeys.DisabledSonosRooms) ?? [])
            self.startMonitoringGroups()
        }
    }
    
    @objc func pause() {
        self.queue.sync {
            if self.paused == false {
                self.allGroupDisposable?.dispose()
                self.tabs = []
                self.rooms = []
                self.paused = true
            }
        }
    }
    
    @objc func resume() {
        self.queue.sync {
            if self.paused {
                self.startMonitoringGroups()
                self.paused = false
            }
        }
    }
    
    // MARK: File Private
    
    fileprivate func roomEnabled(_ room: Room) -> Bool {
        self.queue.sync {
            return !self.disabledRoomIds.contains(room.uuid)
        }
    }
    
    fileprivate func setRoom(_ room: Room, enabled: Bool) {
        self.queue.sync {
            var update = false
            if enabled {
                update = self.disabledRoomIds.remove(room.uuid) != nil
            }
            else {
                (update, _) = self.disabledRoomIds.insert(room.uuid)
            }
            if update {
                UserDefaults.standard.set(Array(self.disabledRoomIds), forKey: UserDefaultsKeys.DisabledSonosRooms)
            }
        }
    }
    
    // MARK: Private
    private var allGroupDisposable: Disposable?
    private let queue = DispatchQueue(label: "SonosRoomsControllerQueue")
    private var paused = false
    private var disabledRoomIds = Set<String>() {
        didSet {
            self.queue.async {
                self.startMonitoringGroups()
            }
        }
    }

    private func startMonitoringGroups() {
        
        self.allGroupDisposable?.dispose()
        self.allGroupDisposable = SonosInteractor.getAllGroups()
            .distinctUntilChanged()
            .subscribe(self.onGroups)

    }
    
    private lazy var onGroups: (Event<[Group]>) -> Void = { [weak self] event in
        guard let self = self else {
            return
        }
        DDLogDebug("New Sonos Group event: \(event)")
        switch event {
        case .next(let groups):
            self.rooms = groups.flatMap { group in
                return ([group.master] + group.slaves) as [SonosRoom]
            }
            
            self.tabs = groups
                .filter({ ([$0.master] + $0.slaves).reduce(false) { $0 || !self.disabledRoomIds.contains($1.uuid) } })
                .map { SonosTabAdapter($0) }
        case .error(let err):
            DDLogError("Error obtaing group: \(err)")
            fallthrough
        default:
            self.tabs = []
            self.rooms = []
            self.queue.asyncAfter(deadline: .now() + Self.groupObtainTimeout) {
                self.startMonitoringGroups()
            }
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.SonosRoomsChanged, object: nil)
        }
    }
}

// MARK: - SonosRoom extension for Room -

extension Room: SonosRoom {
    
    var displayName: String {
        "\(self.name)"
    }
    
    var enabled: Bool {
        get {
            SonosRoomsController.singleton.roomEnabled(self)
        }
        set {
            SonosRoomsController.singleton.setRoom(self, enabled: newValue)
        }
    }
    
    
}
