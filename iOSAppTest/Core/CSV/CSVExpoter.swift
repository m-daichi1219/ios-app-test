import CoreLocation
import CoreMotion
import Foundation

/// CSV形式でデータをエクスポートするユーティリティ
enum CSVExporter {
    // MARK: - Public Methods

    /// CLLocation の配列を CSV ファイルとして保存
    /// - Parameter locations: 保存する位置情報の配列
    /// - Returns: 保存したファイルの URL（成功時）
    /// - Throws: ファイル書き込みエラー
    static func exportLocations(_ locations: [CLLocation]) throws -> URL {
        // 1) CSV文字列を生成
        let csvString = generateLocationCSV(from: locations)

        // 2) 保存先のファイルURLを生成
        let fileURL = try generateFileURL(prefix: "location")

        // 3) ファイルに書き込み
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    /// CMDeviceMotion の配列を CSV ファイルとして保存
    /// - Parameter motions: 保存するモーションデータの配列
    /// - Returns: 保存したファイルの URL（成功時）
    /// - Throws: ファイル書き込みエラー
    static func exportMotions(_ motions: [CMDeviceMotion]) throws -> URL {
        let csvString = generateMotionCSV(from: motions)
        let fileURL = try generateFileURL(prefix: "motion")
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    // MARK: - Private Methods

    /// CLLocation の配列を CSV 文字列に変換
    /// - Parameter locations: 位置情報の配列
    /// - Returns: CSV形式の文字列
    private static func generateLocationCSV(from locations: [CLLocation]) -> String {
        // ヘッダー行（列名）
        var csv = "timestamp,latitude,longitude,altitude,horizontalAccuracy,verticalAccuracy,speed,course\n"

        // ISO8601形式の日時フォーマッター（例: 2025-11-03T10:30:45Z）
        let dateFormatter = ISO8601DateFormatter()

        // 各位置情報を1行ずつ追加
        for location in locations {
            let timestamp = dateFormatter.string(from: location.timestamp)
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let altitude = location.altitude
            let hAccuracy = location.horizontalAccuracy
            let vAccuracy = location.verticalAccuracy
            let speed = location.speed
            let course = location.course

            // CSV行を組み立て（カンマ区切り）
            let row = "\(timestamp),\(latitude),\(longitude),\(altitude),\(hAccuracy),\(vAccuracy),\(speed),\(course)\n"
            csv.append(row)
        }

        return csv
    }

    /// CMDeviceMotion の配列を CSV 文字列に変換
    private static func generateMotionCSV(from motions: [CMDeviceMotion]) -> String {
        // ヘッダー行（列名）
        // タイムスタンプ、姿勢、回転速度、ユーザー加速度、重力、磁場
        var csv = "timestamp,"
        csv += "roll,pitch,yaw,"
        csv += "rotationRate_x,rotationRate_y,rotationRate_z,"
        csv += "userAcceleration_x,userAcceleration_y,userAcceleration_z,"
        csv += "gravity_x,gravity_y,gravity_z,"
        csv += "magneticField_x,magneticField_y,magneticField_z,magneticField_accuracy\n"

        // ISO8601形式の日時フォーマッター
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // ミリ秒を含める

        // 各モーションデータを1行ずつ追加
        for motion in motions {
            // タイムスタンプを Date に変換
            let date = Date(timeIntervalSinceReferenceDate: motion.timestamp)
            let timestamp = dateFormatter.string(from: date)

            // 姿勢（ラジアン）
            let roll = motion.attitude.roll
            let pitch = motion.attitude.pitch
            let yaw = motion.attitude.yaw

            // 回転速度（rad/s）
            let rotX = motion.rotationRate.x
            let rotY = motion.rotationRate.y
            let rotZ = motion.rotationRate.z

            // ユーザー加速度（G、重力を除く）
            let userAccelX = motion.userAcceleration.x
            let userAccelY = motion.userAcceleration.y
            let userAccelZ = motion.userAcceleration.z

            // 重力（G）
            let gravityX = motion.gravity.x
            let gravityY = motion.gravity.y
            let gravityZ = motion.gravity.z

            // 磁場（μT）
            let magX = motion.magneticField.field.x
            let magY = motion.magneticField.field.y
            let magZ = motion.magneticField.field.z
            let magAccuracy = motion.magneticField.accuracy.rawValue

            // CSV行を組み立て
            let row = """
            \(timestamp),\
            \(roll),\(pitch),\(yaw),\
            \(rotX),\(rotY),\(rotZ),\
            \(userAccelX),\(userAccelY),\(userAccelZ),\
            \(gravityX),\(gravityY),\(gravityZ),\
            \(magX),\(magY),\(magZ),\(magAccuracy)\n
            """
            csv.append(row)
        }

        return csv
    }

    /// 保存先のファイルURLを生成（ドキュメントディレクトリ + タイムスタンプ付きファイル名）
    /// - Parameter prefix: ファイル名のプレフィックス（"gps" または "motion"）
    /// - Returns: ファイルのURL
    /// - Throws: ディレクトリ取得エラー
    private static func generateFileURL(prefix: String) throws -> URL {
        // アプリのドキュメントディレクトリを取得
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CSVExportError.documentDirectoryNotFound
        }

        // ファイル名: prefix_yyyyMMdd_HHmmss.csv
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "\(prefix)_\(timestamp).csv"

        // ドキュメントディレクトリ + ファイル名 = フルパス
        return documentsURL.appendingPathComponent(filename)
    }
}

// MARK: - Error

/// CSV出力時のエラー
enum CSVExportError: LocalizedError {
    case documentDirectoryNotFound

    var errorDescription: String? {
        switch self {
        case .documentDirectoryNotFound:
            return "ドキュメントディレクトリが見つかりません"
        }
    }
}
