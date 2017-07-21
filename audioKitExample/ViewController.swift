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
    @IBOutlet weak var plot: AKNodeOutputPlot!
    
    
    var request:Alamofire.Request?
    var player:AKAudioPlayer?
    
    /// the folder to store this service's files in
    var audioFileDirectoryURL:URL!
    
    var filename:String! = "-pl-0000024-Cody-Johnson-Guilty-As-Can-Be.mp3"
    var downloadURLString:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDownload()
        self.setupAudioKit()
        self.beginDownload()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupDownload()
    {
        self.downloadURLString = "https://s3-us-west-2.amazonaws.com/playolasongsdevelopment/\(self.filename!)"
        
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
            try fileManager.removeItem(atPath: audioFileDirectoryURL.appendingPathComponent(self.filename).path)
            print("removed")
        }
        catch let error as NSError
        {
            print("Error trying to delete file from audioCache: \(error)")
        }

    }
    
    func setupAudioKit()
    {
        
    }
    
    func beginDownload()
    {
        self.updateLabel(text: "Downloading...")
        let urlToSaveTo = self.audioFileDirectoryURL.appendingPathComponent(self.filename)
        let destination:DownloadRequest.DownloadFileDestination = { _, _ in return ((urlToSaveTo), []) }
        
        self.request = Alamofire.download(self.downloadURLString, method: .get, to: destination)
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
                self.onDownloadCompleted()
            }
        }
    }
    
    func updateLabel(text:String!)
    {
        DispatchQueue.main.async
        {
            self.statusLabel.text = text
        }
    }
    
    func onDownloadCompleted()
    {
        self.playAudio()
    }
    
    func playAudio()
    {
        do
        {
            let file = try AKAudioFile(forReading: self.audioFileDirectoryURL.appendingPathComponent(filename))
            print("here")
            self.player = try AKAudioPlayer(file: file)
            {
                print("callback...")
                self.playButton.isEnabled = true
                self.player?.start()
            }
            self.plot.node = self.player!
            self.plot.shouldFill = true
            self.plot.shouldMirror = true
            self.plot.color = UIColor.black
            self.plot.plotType = .rolling
            
            AudioKit.output = self.player
            AudioKit.start()
        }
        catch let error
        {
            print("errror")
            print(error)
        }
    }
    
    @IBAction func playButtonPressed(_ sender: Any)
    {

        if (self.player?.isPlaying == true) {
            self.player?.pause()
            self.playButton.setTitle("Play", for: .normal)
        } else {
            self.player?.play()
            self.playButton.setTitle("Pause", for: .normal)
        }
    }
    
    @IBAction func stopButtonPressed(_ sender: Any)
    {
        self.player?.stop()
        self.playButton.setTitle("Play", for: .normal)
    }
}

