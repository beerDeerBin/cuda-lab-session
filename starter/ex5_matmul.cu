// =====================================================================
// Exercise 5 (BONUS) - Shared memory tiling
// ---------------------------------------------------------------------
// 1) THE PROBLEM
//    Matrix multiplication is the core of AI. matmulNaive reads the same
//    values again and again from slow global memory.
//
// 2) YOUR TASK
//    - Write matmulTiled (keep the name and parameters): the same result,
//      but using tiles of TILE x TILE values in fast shared memory.
//      It must also work when N is not a multiple of TILE.
//
// 3) RUN & TEST
//    Build -> Run (PASS + speed-up) -> Test
// =====================================================================
#include <cstdio>
#include <cmath>
#include <vector>
#define TILE 16

__global__ void matmulNaive(const float* A, const float* B, float* C, int N) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    if (row < N && col < N) {
        float sum = 0.0f;
        for (int k = 0; k < N; ++k) sum += A[row * N + k] * B[k * N + col];
        C[row * N + col] = sum;
    }
}

__global__ void matmulTiled(const float* A, const float* B, float* C, int N) {
    __shared__ float As[TILE][TILE];   // one tile of A, shared by the whole block
    __shared__ float Bs[TILE][TILE];   // one tile of B

    int row = blockIdx.y * TILE + threadIdx.y;
    int col = blockIdx.x * TILE + threadIdx.x;
    float sum = 0.0f;

    for (int t = 0; t < (N + TILE - 1) / TILE; ++t) {
        // every thread loads ONE value of A and ONE value of B into As / Bs
        // (outside the matrix? -> load 0)

        // wait until the whole tile is loaded

        // add the products of this tile to sum

        // wait until everyone is done before the next tile overwrites As / Bs
    }

    // write sum to C (only if row and col are inside the matrix)
}

// ---------------- measurement (ready, no changes needed) ----------------
int main() {
    const int N = 2048;
    const size_t bytes = (size_t)N * N * sizeof(float);
    std::vector<float> hA(N * N), hB(N * N), hC1(N * N), hC2(N * N);
    for (int i = 0; i < N * N; ++i) { hA[i] = (i % 7) * 0.1f; hB[i] = (i % 5) * 0.2f; }

    float *A, *B, *C;
    cudaMalloc(&A, bytes); cudaMalloc(&B, bytes); cudaMalloc(&C, bytes);
    cudaMemcpy(A, hA.data(), bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(B, hB.data(), bytes, cudaMemcpyHostToDevice);
    dim3 block(TILE, TILE), grid((N + TILE - 1) / TILE, (N + TILE - 1) / TILE);
    cudaEvent_t s, e; cudaEventCreate(&s); cudaEventCreate(&e);
    float tNaive, tTiled;

    matmulNaive<<<grid, block>>>(A, B, C, N);
    cudaEventRecord(s); matmulNaive<<<grid, block>>>(A, B, C, N); cudaEventRecord(e);
    cudaEventSynchronize(e); cudaEventElapsedTime(&tNaive, s, e);
    cudaMemcpy(hC1.data(), C, bytes, cudaMemcpyDeviceToHost);

    matmulTiled<<<grid, block>>>(A, B, C, N);
    cudaEventRecord(s); matmulTiled<<<grid, block>>>(A, B, C, N); cudaEventRecord(e);
    cudaEventSynchronize(e); cudaEventElapsedTime(&tTiled, s, e);
    cudaMemcpy(hC2.data(), C, bytes, cudaMemcpyDeviceToHost);

    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) { printf("CUDA error: %s\n", cudaGetErrorString(err)); return 1; }

    int wrong = 0;
    for (int i = 0; i < N * N; ++i)
        if (std::fabs(hC1[i] - hC2[i]) > 1e-3f * std::fabs(hC1[i]) + 1e-3f) ++wrong;
    printf("naive: %.2f ms   tiled: %.2f ms   speed-up: %.2fx\n", tNaive, tTiled, tNaive / tTiled);
    printf("Result: %s\n", wrong == 0 ? "PASS" : "FAIL");
    cudaFree(A); cudaFree(B); cudaFree(C);
    return wrong != 0;
}
