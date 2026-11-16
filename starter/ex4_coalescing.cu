// =====================================================================
// Exercise 4 - Memory access patterns
// ---------------------------------------------------------------------
// 1) THE PROBLEM
//    Every thread copies exactly ONE value. Only the distance ("stride")
//    between the values that neighbouring threads READ changes:
//      stride 1:  thread 0 reads in[0], thread 1 reads in[1], ...
//      stride 32: thread 0 reads in[0], thread 1 reads in[32], ...
//    Same work, same amount of useful data - does the access pattern matter?
//
// 2) YOUR TASK
//    - Write the kernel stridedCopy (keep the name and parameters):
//      thread i writes out[i] and reads the value at position i * stride.
//      Careful: i * stride can be too large for an int.
//    - main() is ready: it measures your kernel for stride 1, 2, 4 ... 32.
//
// 3) RUN & TEST
//    Build -> Run -> Test (all lines must show [PASS])
//    Where does the bandwidth stop getting worse? Why there?
// =====================================================================
#include <cstdio>
#include <cstdlib>

__global__ void stridedCopy(const float* in, float* out, int n, int stride) {
    // global index of this thread

    // valid index? -> out at position i = in at position i * stride
}

// ---------------- measurement (ready, no changes needed) ----------------
// measures your kernel for stride 1, 2, 4 ... 32
int main() {
    const int n = 1 << 22, maxStride = 32;
    const size_t inBytes = (size_t)n * maxStride * sizeof(float);
    float *d_in, *d_out;
    if (cudaMalloc(&d_in, inBytes) != cudaSuccess || cudaMalloc(&d_out, n * sizeof(float)) != cudaSuccess) {
        printf("cudaMalloc failed\n"); return 1;
    }
    cudaMemset(d_in, 0, inBytes);
    int threads = 256, blocks = (n + threads - 1) / threads;

    cudaEvent_t start, stop;
    cudaEventCreate(&start); cudaEventCreate(&stop);

    // theoretical peak of the GPU memory: 2 transfers per clock * clock * bus width
    int memClockKHz = 0, busBits = 0;
    cudaDeviceGetAttribute(&memClockKHz, cudaDevAttrMemoryClockRate, 0);
    cudaDeviceGetAttribute(&busBits, cudaDevAttrGlobalMemoryBusWidth, 0);
    double peakGBs = 2.0 * memClockKHz * 1e3 * (busBits / 8) / 1e9;
    printf("GPU memory peak: %.0f GB/s - nothing can be faster than that\n\n", peakGBs);

    printf("stride | time per copy | useful bandwidth\n");
    for (int stride = 1; stride <= maxStride; stride *= 2) {
        stridedCopy<<<blocks, threads>>>(d_in, d_out, n, stride);
        cudaEventRecord(start);
        for (int r = 0; r < 20; ++r) stridedCopy<<<blocks, threads>>>(d_in, d_out, n, stride);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        cudaError_t err = cudaGetLastError();
        if (err != cudaSuccess) { printf("CUDA error: %s\n", cudaGetErrorString(err)); return 1; }
        float ms; cudaEventElapsedTime(&ms, start, stop); ms /= 20;
        double gbs = 2.0 * n * sizeof(float) / ms / 1e6;
        printf("%6d | %10.3f ms | %9.1f GB/s%s\n", stride, ms, gbs,
               (peakGBs > 0 && gbs > 1.2 * peakGBs) ? "   <- faster than the hardware: does your kernel do anything?" : "");
    }
    cudaFree(d_in); cudaFree(d_out);
    return 0;
}
