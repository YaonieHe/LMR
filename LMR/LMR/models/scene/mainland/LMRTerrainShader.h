//  Created on 2022/8/30.

#ifndef LMRTerrainShader_h
#define LMRTerrainShader_h

#import <simd/simd.h>

#ifdef __METAL_VERSION__
#define IAB_INDEX(x) [[id(x)]]
#else
#define IAB_INDEX(x)
#endif

enum LMRTerrainHabitatType: uint8_t {
    LMRTerrainHabitatTypeSand,
    LMRTerrainHabitatTypeGrass,
    LMRTerrainHabitatTypeRock,
    LMRTerrainHabitatTypeSnow,
    
    LMRTerrainHabitatTypeCount
};



#endif /* LMRTerrainShader_h */
