//  Created on 2022/6/22.

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        

    }

    @IBAction func clickSample(_ sender: Any) {
        let vc = LMRSampleVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func clickSample3D(_ sender: Any) {
        let vc = LMRSample3DVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func click3dBox(_ sender: Any) {
        let vc = LMR3DBoxVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func click3dLight(_ sender: Any) {
        let vc = LMR3DLightVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func click3DObjFile(_ sender: Any) {
        let vc = LMRSampleVC(obj: true)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func click3dScene(_ sender: Any) {
        let vc = LMRPointShadowVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func clickRayTracing(_ sender: Any) {
        let vc = LMRRayTracingVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func clickForwardPlus(_ sender: Any) {
        let vc = LMRTileForwardPlusVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func clickReflection(_ sender: Any) {
        let vc = LMRReflectionVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func clickTerrain(_ sender: Any) {
        let vc = LMRTerrainVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

