//
//  ViewController.swift
//  audioKitExample
//
//  Created by Brian D Keane on 7/19/17.
//  Copyright © 2017 Brian D Keane. All rights reserved.
//

import UIKit
import Alamofire
import AudioKit

class ViewController: UIViewController {
    
   
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playButton2: UIButton!
    @IBOutlet weak var plot: AKNodeOutputPlot!
    @IBOutlet weak var stopButton2: UIButton!
    
    var request:Alamofire.Request?
    var player1:AKAudioPlayer?
    var player2:AKAudioPlayer?
    var mixer:AKMixer!
    
    /// the folder to store this service's files in
    var audioFileDirectoryURL:URL!
    
    var filename:String! = "-pl-0000024-Cody-Johnson-Guilty-As-Can-Be.mp3"
    //var filename2:String! = "YOUTUBE-5_edoKB9W-Q.m4a"
    var filename2:String! = "YOUTUBE-Y3r3MUZQkfg.m4a"
    var downloadURLString:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDownload(filename: self.filename)
        self.setupDownload(filename: self.filename2)
        self.beginDownload()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupDownload(filename:String!)
    {
        var downloadURLString = "https://s3-us-west-2.amazonaws.com/playolasongsdevelopment/\(filename!)"
        
        // IF there is no AudioFile folder yet, create it
        // create folder if it does not already exist
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectoryURL:URL = URL(fileURLWithPath: paths[0])
        audioFileDirectoryURL = documentsDirectoryURL.appendingPathComponent("AudioFiles")
    
        let fileManager = FileManager.default
        
        do
        {
            try fileManager.createDirectory(atPath: audioFileDirectoryURL.path, withIntermediateDirectories: false, attributes: nil)
        }
        catch let error as NSError
        {
            print(error.localizedDescription);
        }
        
        // remove song if already downloaded
        do
        {
            try fileManager.removeItem(atPath: audioFileDirectoryURL.appendingPathComponent(filename).path)
            print("removed")
        }
        catch let error as NSError
        {
            print("Error trying to delete file from audioCache: \(error)")
        }
    }
    
    //------------------------------------------------------------------------------
    
    func beginDownload()
    {
        var downloadURLString = "https://s3-us-west-2.amazonaws.com/playolasongsdevelopment/\(self.filename!)"
        self.updateLabel(text: "Downloading...")
        let urlToSaveTo = self.audioFileDirectoryURL.appendingPathComponent(self.filename)
        let destination:DownloadRequest.DownloadFileDestination = { _, _ in return ((urlToSaveTo), []) }
        
        self.request = Alamofire.download(downloadURLString, method: .get, to: destination)
        .downloadProgress
        {
            (progress) -> Void in
            self.updateLabel(text: "Downloading... \(progress.fractionCompleted)")
        }
        .response
        {
            (response) -> Void in
            if let error = response.error
            {
                print("download error")
                print(error)
                self.request?.cancel()
                self.request = nil
            }
            else
            {
                var downloadURLString = "https://s3-us-west-2.amazonaws.com/playolasongsdevelopment/\(self.filename2!)"
                self.updateLabel(text: "Downloading...")
                let urlToSaveTo = self.audioFileDirectoryURL.appendingPathComponent(self.filename2)
                let destination:DownloadRequest.DownloadFileDestination = { _, _ in return ((urlToSaveTo), []) }
                
                self.request = Alamofire.download(downloadURLString, method: .get, to: destination)
                .downloadProgress
                {
                    (progress) -> Void in
                    self.updateLabel(text: "Downloading... \(progress.fractionCompleted)")
                }
                .response
                {
                    (response) -> Void in
                    if let error = response.error
                    {
                        print("download error")
                        print(error)
                        self.request?.cancel()
                        self.request = nil
                    }
                    else
                    {
                        self.setupAudio()
                    }
                }
            }
        }
    }
    
    func setupAudio()
    {
        do
        {
            let file1 = try AKAudioFile(forReading: self.audioFileDirectoryURL.appendingPathComponent(self.filename))
            self.player1 = try AKAudioPlayer(file: file1)
            let file2 = try AKAudioFile(forReading: self.audioFileDirectoryURL.appendingPathComponent(self.filename2))
            self.player2 = try AKAudioPlayer(file: file2)
        } catch let err
        {
            print("error loading audioplayer: \(err.localizedDescription)")
        }
        self.mixer = AKMixer([self.player1!, self.player2!])
        AudioKit.output = self.mixer
        self.plot.plotType = .rolling
        self.plot.shouldFill = true
        self.plot.shouldMirror = true
        self.plot.node = self.mixer
        AudioKit.start()
        print("Audio Ready")
    }
    
    //------------------------------------------------------------------------------
    
    func updateLabel(text:String!)
    {
        DispatchQueue.main.async
        {
            self.statusLabel.text = text
        }
    }
    
    //------------------------------------------------------------------------------
    
    @IBAction func playButtonPressed(_ sender: Any)
    {
        if (sender as! UIButton == self.playButton)
        {
            if (self.player1!.isPlaying)
            {
                self.player1!.pause()
                self.playButton.setTitle("Play", for: .normal)
            }
            else
            {
              self.player1!.play(from: 0, to: self.player1!.duration)
              self.playButton.setTitle("Pause", for: .normal)
            }
        }
        else
        {
            if (self.player2!.isPlaying)
            {
                self.player2!.pause()
                self.playButton2.setTitle("Play", for: .normal)
            }
            else
            {
                self.player2!.play(from: 0, to: self.player2!.duration)
                self.playButton2.setTitle("Pause", for: .normal)
            }
        }
    }
    
    
    
    //------------------------------------------------------------------------------
    
    @IBAction func stopButtonPressed(_ sender: Any)
    {
        if (sender as! UIButton == self.stopButton2)
        {
            self.player2?.stop()
            self.playButton2.setTitle("Play", for: .normal)
        }
        else
        {
            self.player1?.stop()
            self.playButton.setTitle("Play", for: .normal)
        }
        
    }
    
    //------------------------------------------------------------------------------
    @IBAction func reloadPlayer2ButtonPressed(_ sender: Any) {
        do
        {
            let file2 = try AKAudioFile(forReading: self.audioFileDirectoryURL.appendingPathComponent(self.filename2))
            try self.player2?.replace(file: file2)
        } catch let err
        {
            print("error loading audioplayer: \(err.localizedDescription)")
        }
        self.player2?.
        print("Audio Ready")
    }
}

