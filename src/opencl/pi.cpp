/*******************************************************
 * Copyright (c) 2014, ArrayFire
 * All rights reserved.
 *
 * This file is distributed under 3-clause BSD license.
 * The complete license agreement can be obtained at:
 * http://arrayfire.com/licenses/BSD-3-Clause
 ********************************************************/

#include <common.h>

namespace opencl
{

void pi_init()
{
    /*
      TODO any initialization code you need goes here, e.g. random
      number seeding, memory allocations, etc.  Random number
      _generation_ should still go in pi().
    */
}

double pi()
{
    /*
      TODO Put your code here. You can use anything in the OpenCL
      SDK, including libraries, or your own device
      kernels, but do not use ArrayFire functions here. If you have
      initialization code, see pi_init().
    */
    return 0;
}

void pi_reset()
{
    /*
      TODO This function should contain the clean up. You should add
      memory deallocation etc here.
    */
}

}
