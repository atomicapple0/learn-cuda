#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda_runtime.h>
#include "device_launch_parameters.h"

__global__ void vectorMultiply(float *A, float *B, float *C, int numElements) {
    int i = threadIdx.x + blockIdx.x*blockDim.x;
    if (i < numElements) C[i] = A[i] * B[i];
}

int main(void) {
    // params
    float eps = 0.00001;
    int numElements = 50000;
    size_t size = numElements * sizeof(float);

    printf("[Vector addition of %d elements]\n", numElements);

    // allocate host vectors
    printf("allocate host vectors\n");
    float *h_A = (float *)malloc(size);
    float *h_B = (float *)malloc(size);
    float *h_C = (float *)malloc(size);

    // initialize host vectors
    printf("initializing host vectors\n");
    for (int i=0; i<numElements; i++) {
        h_A[i] = i + 1;
        h_B[i] = 1.0 / (i + 1 + eps);
    }

    // allocate device vectors
    printf("allocate device vectors\n");
    float *d_A = NULL;
    float *d_B = NULL;
    float *d_C = NULL;
    cudaError_t err1 = cudaMalloc((void **)&d_A, size);
    printf("allocate device vectors pt 1\n");
    cudaError_t err2 = cudaMalloc((void **)&d_B, size);
    printf("allocate device vectors pt 2\n");
    cudaError_t err3 = cudaMalloc((void **)&d_C, size);
    printf("allocate device vectors pt 3\n");
    if ((err1 != cudaSuccess) || (err2 != cudaSuccess) || (err3 != cudaSuccess)) {
        fprintf(stderr, "Failed to allocate one of the device vectors\n");
        exit(EXIT_FAILURE);
    }

    // copy host input vectors A and B
    printf("copying host vectors to device\n");
    cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);

    // launch the kernel
    printf("launching kernel\n");
    int threadsPerBlock = 256;
    int blocksPerGrid = ceil(numElements / (float)threadsPerBlock);
    vectorMultiply <<<blocksPerGrid, threadsPerBlock>>>(d_A, d_B, d_C, numElements);

    // copy device result back to host
    printf("copying device result back to host\n");
    cudaMemcpy(h_C, d_C, size, cudaMemcpyDeviceToHost);

    // verify that result is correct by computing on cpu
    printf("verifying results\n");
    for (int i = 0; i<numElements; i++) {
        if (fabs((h_A[i] * h_B[i]) - h_C[i]) > 1e-5) {
            fprintf(stderr, "Result verification failed at element %d!\n", i);
            exit(EXIT_FAILURE);
        }
    }
    printf("Test PASSED\n");

    // free device global memory
    cudaFree(d_A); cudaFree(d_B); cudaFree(d_C);

    // free host memory
    free(h_A); free(h_B); free(h_C);

    return 0;
}