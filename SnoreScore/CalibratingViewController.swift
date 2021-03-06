//
//  CalibratingViewController.swift
//  SnoreScore
//
//  Created by MU IT Program on 2/19/16.
//  Copyright © 2016 Corey Matzat. All rights reserved.
//

import UIKit
import AVFoundation

class CalibratingViewController: UIViewController {
    
    //var monitor: AudioMonitor!
    var audioPlayer: AVAudioPlayer!
    var recorder: AVAudioRecorder!
    var baselineRecordingTimer = NSTimer()
    var baselineCalculationTimer = NSTimer()
    var speakingRecordingTimer = NSTimer()
    var speakingCalculationTimer = NSTimer()
    var decibels = 0.0
    var trials = 0.0
    var baselineThreshold = 0.0
    var speakingThreshold = 0.0

    @IBOutlet weak var CalibrationStatus: UIActivityIndicatorView!
    @IBOutlet weak var CalibrationLabel: UILabel!
    @IBOutlet weak var CalButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Calibrate"
        
        CalibrationStatus.stopAnimating()
        //CalibrationStatus.hidden = true
        //monitor = AudioMonitor()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func calibrating(sender: AnyObject) {
        self.navigationItem.setHidesBackButton(true, animated:true);
        CalibrationLabel.text = "Calibration in Progress..."
        calibrateAudio()
        //monitor = AudioMonitor()
        CalibrationStatus.startAnimating()
        CalButton.enabled = false
        //CalibrationLabel.text = NSUserDefaults.standardUserDefaults().integerForKey("numberTimes").description
    }
    
    func calibrateAudio() {
        // Make an AudioSession, set it to PlayAndRecord and make it active
        let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioSession.setActive(true)
        } catch {}
        
        // Set up the URL for the audio file
        let documents: AnyObject = NSSearchPathForDirectoriesInDomains( NSSearchPathDirectory.DocumentDirectory,  NSSearchPathDomainMask.UserDomainMask, true)[0]
        let str =  documents.stringByAppendingPathComponent("recording.m4a")
        let url = NSURL.fileURLWithPath(str as String)
        
        // make a dictionary to hold the recording settings so we can instantiate our AVAudioRecorder
        let recordSettings: [String : AnyObject] = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000.0,
            AVNumberOfChannelsKey: 1 as NSNumber,
            AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue]
        
        //Instantiate an AVAudioRecorder
        do {
            try recorder = AVAudioRecorder(URL: url, settings: recordSettings)
        } catch {
        }
        recorder.prepareToRecord()
        recorder.meteringEnabled = true
        dingSound()
        //start recording
        recorder.record()
        
        //instantiate a timer to be called with whatever frequency we want to grab metering values
        
        baselineRecordingTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("recordBaseline"), userInfo: nil, repeats: true)
        baselineCalculationTimer = NSTimer.scheduledTimerWithTimeInterval(8, target: self, selector: Selector("calculateBaseline"), userInfo: nil, repeats: false)
        
        
    }
    
    
    func recordBaseline() {
        //we have to update meters before we can get the metering values
        recorder.updateMeters()
        
        print(recorder.averagePowerForChannel(0))
        decibels += Double(recorder.averagePowerForChannel(0))
        trials++
    }
    
    func calculateBaseline() {
        baselineRecordingTimer.invalidate()
        baselineThreshold = decibels / trials
        decibels = 0
        trials = 0
        print("Quiet average is " + String(baselineThreshold))
        NSUserDefaults.standardUserDefaults().setDouble(baselineThreshold, forKey: "baseLineRecord")
        dingSound()
        speakingRecordingTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("recordSpeaking"), userInfo: nil, repeats: true)
        speakingCalculationTimer = NSTimer.scheduledTimerWithTimeInterval(6, target: self, selector: Selector("calculateSpeaking"), userInfo: nil, repeats: false)

        
    }
    
    func recordSpeaking() {
        //we have to update meters before we can get the metering values
        recorder.updateMeters()
        
        print(recorder.averagePowerForChannel(0))
        if (Double(recorder.averagePowerForChannel(0)) > baselineThreshold + (0 - baselineThreshold) * 0.05) {
            decibels += Double(recorder.averagePowerForChannel(0))
            trials++
        }
    }
    
    func calculateSpeaking() {
        speakingRecordingTimer.invalidate()
        speakingThreshold = decibels / trials
        
        print("Speaking average is " + String(decibels / trials))
        NSUserDefaults.standardUserDefaults().setDouble(speakingThreshold, forKey: "speakingThresholdRecord")
        self.navigationItem.setHidesBackButton(false, animated:true);
        CalibrationStatus.stopAnimating()
        CalButton.enabled = true
        CalibrationLabel.text = "Calibration Complete"
        dingSound()
        

    }
    
    
    func dingSound(){
        let audioFilePath = NSBundle.mainBundle().pathForResource("ding", ofType: "mp3")
        
        if audioFilePath != nil {
            
            let audioFileUrl = NSURL.fileURLWithPath(audioFilePath!)
            
            audioPlayer = try? AVAudioPlayer(contentsOfURL: audioFileUrl)
            
            audioPlayer.play()
            audioPlayer.volume = 2.0
            
            
            
        } else {
            print("audio file is not found")
        }
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
