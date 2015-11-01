//
//  dpmetal_types.metal
//  DegradrCore3
//
//  Created by denis svinarchuk on 29/06/15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#ifndef __DPMETAL_TYPES
#define __DPMETAL_TYPES

#include <metal_stdlib>

#ifndef __INLINE__
#warning __INLINE__ is not defined
#define __INLINE__ inline __attribute__((__always_inline__))
#endif

#ifndef METAL_FUNC
#warning METAL_FUNC is not defined
#define METAL_FUNC inline __INLINE__
#endif

#define DPMETAL_NAMESPACE_BEGIN namespace dpmetal {
#define DPMETAL_NAMESPACE_END }

#endif
