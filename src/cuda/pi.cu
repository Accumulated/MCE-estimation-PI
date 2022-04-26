/*******************************************************
 * Copyright (c) 2014, ArrayFire
 * All rights reserved.
 *
 * This file is distributed under 3-clause BSD license.
 * The complete license agreement can be obtained at:
 * http://arrayfire.com/licenses/BSD-3-Clause
 ********************************************************/

#include <common.h>
#include <curand.h>
#include <curand_kernel.h>
#include <cuda.h>
#include <cuda_runtime_api.h>
#include <device_launch_parameters.h>
#include <cuda_runtime.h>
#include <device_functions.h>

#define WARP_SIZE 32

/*******************************************************************************
 * This code implements Monte Carlo Simulation for estimating
 * Pi value. The estimation is performed using 3 kernels:
 *
 * 1. Init -> Initializes random generator for each thread. This is	done by
 *			  using seed and sequence (sub-seed) in 'curand' function.
 *
 * 2. Reduction -> This kernel does 2 operations:
 *	1. (Generation stage)
 *		Every thread executes this kernel is going to generate 2 * N
 *		samples using 'curand' function. The thread first generates N samples
 * 		and calculate number of points are inside the circle and puts that
 *		number in memory at its own index i.e. threadIdx.x. It then generates
 * 		another N samples and puts the final sum in a strided location i.e.
 *		threadIdx.x + blockDim.x.
 *
 *	2. (Reduction Sum algorithm)
 *		It finally sums all elements in the shared memory array generated by
 * 		the current block.
 *
 * 3. Naive summation -> The final output will be a 1-D vector of 100 elements,
 *						A single thread calculates the final summation.
 *******************************************************************************/

// Given 30000000 samples -> i chose certain configuration for
// Kernels. Grid of 10 x 10 x 1 blocks. Each block contains 256 threads
// Each thread generates 1200 samples. Total samples: 30720000
const int BLOCK_SIZE = 256;
const int ItersPerThread = 600;
int nbx = 10;
int nby = 10;

typedef struct {
    int NumberOfElements;
    float* elements;
}
Vector1D;

void CheckCudaError(char* ptr, cudaError err);
void Set_DeviceMatrix(int NumOfElements, Vector1D* ptr, char* NamePtr);

__global__ void Reduction(curandState_t* states, float *ptr)
{
  /*
	This code works on 2 * Block_Size elements.
	i.e. for 512 Block_Size -> we are reducing 1024 elements.
	Each thread loads 2 elements, one at tx and the
	other shifted by blockIdx.x. Each element loaded represents
	Number of points that exist inside a quarter unit circle.
  */

  // Optimize for shared memory traffic instead of DRAM as
  // There will be lots of traffic in this kernel.
  __shared__ float partialSum[2 * BLOCK_SIZE];

  int tx = threadIdx.x;
  int bx_dim = blockDim.x;

  int by_index = blockIdx.y;
  int bx_index = blockIdx.x;

  // This sequence is how we know which thread has which random generator
  // in the states variable. It locates the location of the thread inside
  // the block inside the grid.
  int sequence = bx_index * bx_dim + by_index * (gridDim.x * bx_dim) + tx;

  float tmp = 0., x = 0., y = 0.;

  // Start generating the first N samples
  for(int i = 0; i < ItersPerThread; i++)
  {
    x = curand_uniform(&states[sequence]);
    y = curand_uniform(&states[sequence]);
    // Count Number of points
    if (x * x + y * y < 1)
      tmp += 1;
  }
  // Append the value in memory
  partialSum[tx] = tmp;

  tmp = 0;
  for(int i = 0; i < ItersPerThread; i++)
  {
    x = curand_uniform(&states[sequence]);
    y = curand_uniform(&states[sequence]);
    if (x * x + y * y <= 1)
      tmp += 1;
  }
  partialSum[tx] += tmp;
  
  __syncthreads();
  for (unsigned int stride = blockDim.x / 2; stride > WARP_SIZE; stride = stride / 2.0f)
  {
    if (tx < stride)
      partialSum[tx] += partialSum[tx + stride];
      __syncthreads();
  }

  // Reduction tree with shuffle instructions
  float sum = 0;
  if(tx < WARP_SIZE) 
  {
    sum = partialSum[tx] + partialSum[tx + WARP_SIZE];
    for(unsigned int stride = WARP_SIZE/2; stride > 0; stride /= 2) 
    {
      sum += __shfl_down_sync(0xffffffff, sum, stride);
    }
  }

  if (tx == 0)
    ptr[bx_index + by_index * gridDim.x] = sum;
}

__global__ void init(unsigned int seed, curandState_t* states)
{
  /*
	Simply initalize the generators needed by the threads to
	generate random numbers. I use 2 values, the seed which depends
	on the clock to assure random numbers accross different runs.
	The second one is the thread location in the block and the
	block location in the grid, this is used as sequence value just
	to make sure that all threads have unique numbers generated and
	none is repeated.
  */

  int tx = threadIdx.x;
  int bx_dim = blockDim.x;

  int by_index = blockIdx.y;
  int bx_index = blockIdx.x;

  int sequence = bx_index * bx_dim + by_index * (gridDim.x * bx_dim) + tx;

  curand_init(seed, sequence, 0, &states[sequence]);
}

__global__ void Sum (float *ptr, int NumberOfElements)
{
	// Naive implementation of summation kernel
    float tmp = 0;

    if (threadIdx.x == 0)
    {
      for (int i = 0; i < NumberOfElements; i++)
      {
          tmp += ptr[i];
      }
      ptr[0] = tmp;
    }
}

namespace cuda
{

  curandState_t* states;
  Vector1D Summation;

  dim3 dim_Grid(nbx, nby, 1);
  dim3 dim_Block(BLOCK_SIZE, 1, 1);

  dim3 dim_Grid2(1, 1, 1);
  dim3 dim_Block2(1, 1, 1);

void pi_init()
{
  // allocate space on the GPU for the random states
  cudaMalloc((void**) &states, nbx * nby * BLOCK_SIZE * sizeof(curandState_t));

  // Allocate the final output that will include all blocks results.
  Set_DeviceMatrix(nbx * nby, &Summation, "Allocate The Output matrix");

}

double pi()
{

  init <<< dim_Grid, dim_Block >>> (time(NULL), states);
  Reduction <<< dim_Grid, dim_Block >>> (states, Summation.elements);
  Sum <<< dim_Grid2, dim_Block2 >>> (Summation.elements,  Summation.NumberOfElements);
  cudaDeviceSynchronize();

  float x = 0;
  cudaMemcpy(&x, &Summation.elements[0], sizeof(float), cudaMemcpyDeviceToHost);
  return 4.0 * (((double)x) / ((double)(nbx * nby * BLOCK_SIZE * ItersPerThread * 2)));
}

void pi_reset()
{
  cudaFree(states);
  cudaFree(Summation.elements);
}

}

// Allocations for Device matrices
void Set_DeviceMatrix(int NumOfElements, Vector1D* ptr, char* NamePtr)
{
    ptr -> NumberOfElements = NumOfElements;
    size_t size = NumOfElements * sizeof(float);
    cudaError err = cudaMalloc((void **)&(ptr->elements), size);
    CheckCudaError(NamePtr, err);
}

void CheckCudaError(char* ptr, cudaError err)
{
    if (err == cudaSuccess);
    else
        printf("CUDA error in %s: %s\n", ptr, cudaGetErrorString(err));
}
