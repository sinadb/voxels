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
    
    var cameraOrigin : simd_float3?
    var cameraDirection : simd_float3?
    
    var cameraState : Bool = false {
        didSet {
            
            if let origin = cameraOrigin, let direction = cameraDirection {
               // print(origin,direction)
                var camera = simd_float4x4(eye: origin, center: direction, up: simd_float3(0,1,0))
                renderer.currentScene.updateCamera(with: camera)
                self.renderer.currentScene.eye = origin
                self.renderer.currentScene.direction = direction
            }

                cameraState = false
        }
    }
    
    @IBOutlet weak var xEye: NSTextField!
    @IBOutlet weak var yEye: NSTextField!
    @IBOutlet weak var zEye: NSTextField!
    
    @IBOutlet weak var testOrigin: NSTextField!
    
    @IBOutlet weak var testDirection: NSTextField!
    
    @IBAction func updateCamera(_ sender: NSTextField) {
        
        switch sender {
        case xEye:
            print(sender.doubleValue)
            return
        case yEye:
            print(sender.doubleValue)
            return
        case zEye:
            print(sender.doubleValue)
            return
        case testOrigin:
            let origin = sender.stringValue.split(separator: ",")
            cameraState = true
            cameraOrigin = simd_float3(Float(origin[0])!,Float(origin[1])!,Float(origin[2])!)
            return
        case testDirection:
            let direction = sender.stringValue.split(separator: ",")
            cameraDirection = simd_float3(Float(direction[0])!,Float(direction[1])!,Float(direction[2])!)
            cameraState = true
        default:
            return
        }
    }
    

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

