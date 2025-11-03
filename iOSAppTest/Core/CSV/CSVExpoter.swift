import CoreLocation
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
        let csvString = generateCSV(from: locations)

        // 2) 保存先のファイルURLを生成
        let fileURL = try generateFileURL()

        // 3) ファイルに書き込み
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    // MARK: - Private Methods

    /// CLLocation の配列を CSV 文字列に変換
    /// - Parameter locations: 位置情報の配列
    /// - Returns: CSV形式の文字列
    private static func generateCSV(from locations: [CLLocation]) -> String {
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

    /// 保存先のファイルURLを生成（ドキュメントディレクトリ + タイムスタンプ付きファイル名）
    /// - Returns: ファイルのURL
    /// - Throws: ディレクトリ取得エラー
    private static func generateFileURL() throws -> URL {
        // アプリのドキュメントディレクトリを取得
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CSVExportError.documentDirectoryNotFound
        }

        // ファイル名: gps_yyyyMMdd_HHmmss.csv
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "gps_\(timestamp).csv"

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
