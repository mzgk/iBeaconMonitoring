//
//  ViewController.swift
//  iBeaconMonitoring
//
//  Created by mzgk on 2018/03/05.
//  Copyright © 2018年 mzgk. All rights reserved.
//

/**
 事前にプロジェクトに以下の設定が必要
 - Info -> Custom iOS Target Properties
    - Privacy - Location Always and When In Use Usage Description
    - Privacy - Location When In Use Usage Description
 - Capabilities Background Mode -> Location Update
*/
import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    // MARK: - アウトレット
    @IBOutlet weak var uuidValue: UILabel!
    @IBOutlet weak var majorValue: UILabel!
    @IBOutlet weak var minorValue: UILabel!
    @IBOutlet weak var proximityValue: UILabel!

    // MARK: - プロパティ
    let UUID_VALUE = "92CEC608-0C60-4DCD-98C4-8EF57C09EBDE"
    let MAJOR_VALUE: CLBeaconMajorValue = 1
    let MINOR_VALUE: CLBeaconMinorValue = 1
    let IDENTIFIER_VALUE = "com.mzgkworks"
    var ADVERTISE_DATA: (UUID, CLBeaconMajorValue, CLBeaconMinorValue)!

    let manager = CLLocationManager()

    // MARK: - ライフサイクル
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        allClear()

        manager.delegate = self

        // 認証状態確認
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            break
        case .restricted, .denied:
            print("自分で許可してのダイアログを表示させる")
            // 設定　→　プライバシー　→　位置情報サービス　→　アプリ名
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: - CLLocationManagerDelegate
    // 許可ステータスが更新された
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            startMonitoring()
        }
    }

    // モニタリンングが正常に開始された
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("[iBeacon 手順２] 正常に開始された：locationManager(_:didStartMonitoringFor:)")
        print("[iBeacon 手順３] 問い合わせ：requestState(for:)")
        manager.requestState(for: region)
    }

    // iBeaconが存在するか
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        print("[iBeacon 手順４] Region内にiBeaconがいるか：locationManager(_:didDetermineState:for:)")
        switch state {
        case .inside:
            print("iBeaconが存在")
            print("[iBeacon 手順５] レンジングスタート：startRangingBeacons(in:)")
            manager.startRangingBeacons(in: region as! CLBeaconRegion)
        case .outside:
            print("iBeaconが圏外")
        case .unknown:
            print("iBeaconが不明")
        }
    }

    // iBeaconの情報を取得
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        print("[iBeacon 手順６] 取得：locationManager(_:didRangeBeacons:in:)");
        var proximity = ""
        for beacon in beacons {
            print("UUID : \(beacon.proximityUUID)")
            print("MAJOR : \(beacon.major)")
            print("MINOR : \(beacon.minor)")
            print("RSSI : \(beacon.rssi)")

            switch beacon.proximity {
            case .immediate:
                print("Proximity: Immediate")
                proximity = "Immediate"
            case .far:
                print("Proximity: far")
            case .near:
                print("Proximity: near")
                proximity = "Near"
            case .unknown:
                print("Proximity: unknown")
            }

            // 登録してあるUUID-Major-MinorのiBeaconかを判断（タプル？配列の比較）
            // 距離がimmediate or nearであることも条件か？
            let recieveData = (beacon.proximityUUID, beacon.major as! CLBeaconMajorValue, beacon.minor as! CLBeaconMinorValue)
            if ADVERTISE_DATA == recieveData {
                if beacon.proximity == .immediate || beacon.proximity == .near {
                    uuidValue.text = String(describing: beacon.proximityUUID)
                    majorValue.text = String(describing: beacon.major)
                    minorValue.text = String(describing: beacon.minor)
                    proximityValue.text = proximity
                    // 実際は停止すると次回に検知されないので止めない？
                    manager.stopMonitoring(for: region)
                    manager.stopRangingBeacons(in: region)
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("didEnterRegion: iBeaconが圏内に発見されました。")
        print("[iBeacon 手順５] レンジングスタート：startRangingBeacons(in:)")
        manager.startRangingBeacons(in: region as! CLBeaconRegion)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("didExitRegion: iBeaconが圏外に喪失されました。")
        manager.stopRangingBeacons(in: region as! CLBeaconRegion)
    }


    // MARK: - メソッド
    func startMonitoring() {
        let uuid = UUID(uuidString: UUID_VALUE)
        let beaconRegion = CLBeaconRegion(proximityUUID: uuid!,
                                          major: MAJOR_VALUE,
                                          minor: MINOR_VALUE,
                                          identifier: IDENTIFIER_VALUE)
        beaconRegion.notifyEntryStateOnDisplay = false  // ディスプレイがOFFでも通知
        beaconRegion.notifyOnEntry = true   // 入域の通知
        beaconRegion.notifyOnExit = true    // 出域の通知

        ADVERTISE_DATA = (uuid!, MAJOR_VALUE, MINOR_VALUE)

        // モニタリングのスタート
        print("[iBeacon 手順１] モニタリング開始：startMonitoring(for:)")
        manager.startMonitoring(for: beaconRegion)
    }

    func allClear() {
        uuidValue.text = ""
        majorValue.text = ""
        minorValue.text = ""
        proximityValue.text = ""
    }

    @IBAction func clearButtonTapped(_ sender: UIButton) {
        allClear()
    }
    
}

