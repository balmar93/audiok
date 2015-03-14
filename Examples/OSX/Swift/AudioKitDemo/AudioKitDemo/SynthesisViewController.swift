//
//  SynthesisViewController.swift
//  AudioKitDemo
//
//  Created by Nicholas Arner on 3/1/15.
//  Copyright (c) 2015 AudioKit. All rights reserved.
//


class SynthesisViewController: NSViewController {
    
    @IBOutlet var fmSynthesizerTouchView: NSView!
    @IBOutlet var tambourineTouchView: NSView!
    
    let tambourine    = Tambourine()
    let fmSynthesizer = FMSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the vFMSynthesizeriew, typically from a nib.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        AKOrchestra.addInstrument(tambourine)
        AKOrchestra.addInstrument(fmSynthesizer)
        AKOrchestra.start()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        AKOrchestra.reset()
        AKManager.sharedManager().stop()
    }
    
    @IBAction func tapTambourine(sender: NSClickGestureRecognizer) {
        
        let touchPoint = sender.locationInView(tambourineTouchView)
        let scaledX = touchPoint.x / tambourineTouchView.bounds.size.height
        let scaledY = 1.0 - touchPoint.y / tambourineTouchView.bounds.size.height
        
        let intensity = Float(scaledY*4000 + 20)
        let dampingFactor = Float(scaledX / 2.0)
        
        let note = TambourineNote(intensity: intensity, dampingFactor: dampingFactor)
        tambourine.playNote(note)
    }
    
    @IBAction func tapFMOscillator(sender: NSClickGestureRecognizer) {
        
        let touchPoint = sender.locationInView(fmSynthesizerTouchView)
        let scaledX = touchPoint.x / fmSynthesizerTouchView.bounds.size.height
        let scaledY = 1.0 - touchPoint.y / fmSynthesizerTouchView.bounds.size.height
        
        let frequency = Float(scaledY*400)
        let color = Float(scaledX)
        
        let note = FMSynthesizerNote(frequency: frequency, color: color)
        fmSynthesizer.playNote(note)
    }
}
