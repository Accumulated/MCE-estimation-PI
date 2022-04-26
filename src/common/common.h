/*******************************************************
 * Copyright (c) 2014, ArrayFire
 * All rights reserved.
 *
 * This file is distributed under 3-clause BSD license.
 * The complete license agreement can be obtained at:
 * http://arrayfire.com/licenses/BSD-3-Clause
 ********************************************************/

#include <stdio.h>

#define PI 3.1415926535897931f

// generate millions of random samples
static int samples = 30e6;

#ifdef AF_OPENCL
namespace opencl
#else
namespace cuda
#endif
{

void pi_init();
double pi();
void pi_reset();

}

#ifdef AF_OPENCL
namespace detail = opencl;
#else
namespace detail = cuda;
#endif
