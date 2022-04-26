# ArrayFire Pi Test
Show off your GPU programming skill to use Monte Carlo estimation of PI.

## Algorithm
The basic method is as follows: generate (x,y) points uniformly over the unit
square and count what fraction of those fell within the unit circle.

From `pi_cpu()` you can see one method of doing this: generate (x,y) values over
[0,1] and count how many are unit distance from the origin (0,0). Since this is
only the positive upper right quadrant, multiply that fraction by four to
estimate Pi over the entire domain. For ArrayFire, you can see pi_af() implement
the same algorithm in a parallel fashion.

## Code
The code is divided into 3 parts:

1. **src/common**: Contains the common code including the ArrayFire
   implementation of Pi estimation, a CPU implementation as well as timing code.
   You do not need to modify these files.
2. **src/cuda**: The CUDA implementation should go here. Your task is to
   complete the `pi_init`, `pi`, and `pi_reset` functions. You may choose to
   add more functions if you wish, but those must be called from one of these
   functions.
3. **src/opencl**: The OpenCL implementation should go here. Your task is to
   complete the `pi_init`, `pi`, and `pi_reset` functions. You may choose to
   add more functions if you wish, but those must be called from one of these
   functions.

## Scoring
1. Your primary task is to implement the Monte Carlo Estimation of PI in either
   CUDA or OpenCL or both (extra points).
2. All the initizalization and one-time code such as memory allocation must go
   in the `pi_init` function.
3. All the deletion and clearing of memory etc must go in the `pi_reset`
   function.
4. The `pi` function must contain the kernel call. This is the function that
   will be timed. You must choose wisely as to which calls are in this function.
   Calls that can be init but are put in pi will result in extra time and hence
   a lower score. Calls that should be timed, but are not a part of this
   function will result in a deduction in score.
5. You will be scored for your code style, error handling, and performance.
6. For fair comparison, evaluate the same number of samples (defined in
   common.h) as in the ArrayFire and CPU versions. Notice that we consider an
   estimate a "success" if it's within 1/1000 of the reference af::Pi.
7. If your submission does not compile, you basically get a zero. If your
   submission runs slower than the CPU, you basically get a zero.
8. We are judging you on performance of your code, numerical accuracy, coding
   style, readability (comments in code), and organization. It's up to you to
   strike a balance between all of those. Completing both CUDA and OpenCL will
   earn you extra points.

## Requirements:
You will require the following libraries:
* ArrayFire (Download from http://arrayfire.com/download/)
* Atleast one of:
  * CUDA 7.5 (Download: https://developer.nvidia.com/cuda-downloads)
  * OpenCL SDK (download from vendor's website)
* CMake
* Visual Studio 2013 or newer if on Windows.

## Building:
### Linux
Once you have downloaded and installed ArrayFire, CUDA/OpenCL SDK and CMake,
you are ready to build.
The initial step is to run CMake. The commands will be:
```
mkdir build && cd build
cmake .. -DArrayFire_DIR=/path/to/arrayfire/share/ArrayFire/cmake
make
```

Everything should ideally compile correctly, and you should see `pi_cuda` and
`pi_opencl` in the build/bin directory. You can run these out of the box.

You can add your changes and repeat the cycle of `make` and `./bin/pi_cuda` or
`./bin/pi_opencl`

### Windows (Using Visual Studio 2013)
Download and install ArrayFire, CUDA/OpenCL SDK, CMake and Visual Studio 2013.
The steps to build are as follows.

1. Open the CMake GUI and add the source path as the directory for the pi
   estimation. In the build directory, use the directory to the pi estimation
   appended by build. That is, if the source directory is `C:\workspace\pi`, the
   build directory should be `C:\workspace\pi\build`.
2. Click configure and choose the generator as Visual Studio 12 2013 Win64.
   CMake should automatically detect ArrayFire along with CUDA and/or OpenCL.
3. Click generate to generate the solution and project files in the build
   directory.
4. You can open the Visual Studio solution and you will find 2 projects,
   `pi_cuda` and `pi_opencl`. Exanding these projects will should the source
   files that you will need to modify.

Note: For CUDA, you will need to copy the CUDA NVVM DLL to the bin directory.
The NVVM DLL path is `CUDA_PATH/nvvm/bin/nvvm64_30_0.dll`

## FAQ
Can I use CUDA Libraries?
> A: You can use any code and functions that ship with the CUDA toolkit. This
> includes the libraries as well as thrust.

Is there a correct code style?
> A: You may choose the code style you are most familiar with. We look for
> consistency and readability in your code.

Will I be hurting my chances by not completing both CUDA and OpenCL?
> A: Completing either of CUDA or OpenCL will be considered as completing the
> task. If you feel comfortable doing both, you can surely do that too.

Can I show more than one implementation of Pi estimation.
> Yes, absolutely. If you wish to show how you went about adding performance,
> sure do. Just make sure to use the init and reset functions appropriatelty.
> You may add new `pi` functions (say `pi_v1`, `pi_v2`) etc and add the timing
> code in `src/common/pi.cpp` file. This is essentially copy pasting the lines
> where `pi` gets called. Make sure to add dummy functions in backends you may
> not be coding.

Can I skip CMake and use my own build system?
> Yes, in such a case, make sure to write **clear and precise** instructions
> in a readme. If the compilation fails after following your instructions, then
> you will risk getting a 0. Our primary interest is in `cuda/pi.cu` and
> `opencl/pi.cpp` and any files that you may add. Ideally, we would simply copy
> paste your files into the structure we have to compile and run it.

Can I use ArrayFire to allocate memory and get the device pointers?
> No, your CUDA/OpenCL implementation must be written from scratch with
> initialization, teardown and kernels.
