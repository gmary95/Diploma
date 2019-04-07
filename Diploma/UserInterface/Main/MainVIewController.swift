//
//  ViewController.swift
//  Recorder
//
//  Created by Aurelius Prochazka, revision history on Githbub.
//  Copyright © 2017 Aurelius Prochazka. All rights reserved.
//

import Cocoa
import Charts
import AVFoundation

class MainViewController: NSViewController {
    
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var soundChart: LineChartView!
    @IBOutlet weak var timeLabel: NSTextField!

    var audioControl: AudioControl?
    var meterTimer: DispatchSourceTimer?
    
    var soundData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        soundChart.noDataTextColor = .white
        
        startButton.isEnabled = true
        stopButton.isEnabled = false
    }
    
    @IBAction func startRecord(_ sender: Any) {
        setPath()
    }
    
    @IBAction func stopRecord(_ sender: Any) {
        if self.stopButton.isEnabled {
            self.audioControl?.stopRecord()
            self.stopButton.isEnabled = false
            self.startButton.isEnabled = true
            self.meterTimer?.cancel()
            self.timeLabel.stringValue = ""
            
            let alert:NSAlert = NSAlert()
            alert.messageText = "Recording finished"
            alert.alertStyle = NSAlert.Style.informational
            alert.runModal()
            
            
        }
        
        
    }
    
    @IBAction func openFile(_ sender: Any) {
        let dialog = NSOpenPanel()
        
        let path = "/Users⁩/gmary⁩/Desktop/"
        dialog.directoryURL = NSURL.fileURL(withPath: path, isDirectory: true)
        dialog.title                   = "Choose a file"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = true
        dialog.canCreateDirectories    = true
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes        = ["wav"]
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                openAndRead(filePath: result!)
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    func openAndRead(filePath: URL) {
        do {
            soundData = try Data(contentsOf: filePath)
            startFilter()
        } catch {
            let alert:NSAlert = NSAlert()
            alert.messageText = "You choose incorect file or choose noone."
            alert.alertStyle = NSAlert.Style.informational
            alert.runModal()
        }
    }
    
    func record() {
        if startButton.isEnabled {
            print("start recording")
            self.stopButton.isEnabled = true
            self.startButton.isEnabled = false
            self.audioControl?.startRecord()
            setupUpdateMeter()
        }
        else {
            print("recording not possible. no file loaded")
        }
    }
    
    func setPath() {
        print("Set Path")
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["wav"]
        
        let choice = panel.runModal()
        
        switch(choice) {
        case .OK :
            self.audioControl = AudioControl(path:panel.url!)
            record()
            break;
        case .cancel :
            print("canceled")
            break;
        default:
            print("test")
            break;
        }
    }
    
    func setupUpdateMeter() {
        self.meterTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        
        self.meterTimer?.schedule(deadline: .now(), repeating: .microseconds(100))
        self.meterTimer?.setEventHandler
            {
                self.timeLabel.stringValue = "\(Float(((self.audioControl?.getTime())!*10).rounded()/10))s"
        }
        self.meterTimer?.resume()
    }
        
    func startFilter() {
        
        var wavcat = soundData!.subdata(in: 1024 ..< soundData!.count)
        
        let tmp = dataToInt(data: wavcat)
        print(tmp)
        representChart(timeSeries: tmp, chart: soundChart)
    }
    
    func dataToInt(data: Data) -> [UInt16] {
        var result: [UInt16] = []
        
        for i in 0 ..< data.count / 2 {
            let bytes: [UInt8] = [data[i * 2], data[i * 2 + 1]]
            let u16 = UnsafePointer(bytes).withMemoryRebound(to: UInt16.self, capacity: 1) {
                $0.pointee
            }
            result.append(u16)
        }
        return result
    }
    
    func representChart(timeSeries: Array<UInt16>, chart: LineChartView){
        let series = timeSeries.enumerated().map { x, y in return ChartDataEntry(x: Double(x), y: Double(y)) }
        
        let data = LineChartData()
        let dataSet = LineChartDataSet(values: series, label: "Current sound")
        dataSet.colors = [NSUIColor.yellow]
        dataSet.valueColors = [NSUIColor.white]
        dataSet.drawCirclesEnabled = false
        data.addDataSet(dataSet)
        
        chart.data = data
        
        chart.gridBackgroundColor = .red
        chart.legend.textColor = .white
        chart.xAxis.labelTextColor = .white
        chart.leftAxis.labelTextColor = .white
        chart.rightAxis.labelTextColor = .white
    }
}
