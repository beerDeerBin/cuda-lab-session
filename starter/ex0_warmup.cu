// =====================================================================
// Exercise 0 - Warm-up: Hello, GPU!
// ---------------------------------------------------------------------
// 1) THE PROBLEM
//    Is there a GPU? Can we start code on it? How big is it?
//
// 2) YOUR TASK
//    - Write a kernel hello() that prints "Hello from the GPU!".
//    - Start it on the GPU with 1 block of 1 thread.
//    - Wait until the GPU is done (the launch is asynchronous!)
//      and print an error message if something went wrong.
//    - Read the properties of GPU 0 and print them (all fields are in
//      the struct cudaDeviceProp - look it up in the CUDA docs or ask an AI).
//
//    Expected output:
//      Hello from the GPU!
//      GPU name                 : <name>
//      Streaming multiprocessors: <number>
//      Warp size                : <number>
//      Max threads per block    : <number>
//      Global memory            : <number> GB
//
// 3) RUN & TEST
//    Build -> Run -> Test (all lines must show [PASS])
// =====================================================================
#include <cstdio>

__global__ void hello() {
    // print "Hello from the GPU!"
}

int main() {
    // start hello on the GPU: 1 block with 1 thread

    // wait until the GPU is done and print an error if something went wrong
    cudaError_t err = cudaSuccess;   // <- store the result of the wait here
    if (err != cudaSuccess) {
        printf("CUDA error: %s\n", cudaGetErrorString(err));
        return 1;
    }

    // read the properties of GPU 0 into prop (cudaGetDeviceProperties)
    cudaDeviceProp prop;

    // print the five values (see "Expected output" above)

    return 0;
}
