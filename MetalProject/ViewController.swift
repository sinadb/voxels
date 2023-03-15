//
//  ViewController.swift
//  MetalProject
//
//  Created by Sina Dashtebozorgy on 22/12/2022.
//

import Cocoa
import Metal
import MetalKit

class ViewController: NSViewController {

    @IBOutlet weak var skybox1: NSButton!
    @IBOutlet weak var skybox0: NSButton!
    
    @IBAction func updateSkyBox(_ sender: NSButton) {
       
        
        switch sender {
        case skybox0:
            if(skybox0.state == .on){
                
                return
            }
            else{
                
                skybox0.state = .on
                skybox1.state = .off
                self.renderer.activeSkyBox.update_texture(with: self.renderer.skyboxTexture!)
                renderer.skymapChanged = true
                
                return
            }
        case skybox1:
            if(skybox1.state == .on){
                return
            }
            else{
                
                skybox1.state = .on
                skybox0.state = .off
                self.renderer.activeSkyBox.update_texture(with: self.renderer.skyboxTexture1!)
                renderer.skymapChanged = true
               
                return
            }
        default:
            return
        }
    }
    var mtkView: MTKView!
    var renderer: Renderer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // First we save the MTKView to a convenient instance variable
        guard let mtkViewTemp = self.view as? MTKView else {
            print("View attached to ViewController is not an MTKView!")
            return
        }
        
        mtkView = mtkViewTemp
       
        

        // Then we create the default device, and configure mtkView with it
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }

        print("My GPU is: \(defaultDevice)")
        mtkView.device = defaultDevice

        // Lastly we create an instance of our Renderer object,
        // and set it as the delegate of mtkView
        guard let tempRenderer = Renderer(mtkView: mtkView) else {
            print("Renderer failed to initialize")
            return
        }
       renderer = tempRenderer
//
       mtkView.delegate = renderer


    }
}

