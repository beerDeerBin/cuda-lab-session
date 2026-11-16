// =====================================================================
// Exercise 1 - Thread indexing
// ---------------------------------------------------------------------
// 1) THE PROBLEM
//    A kernel runs as thousands of threads at the same time. Each thread
//    must know WHICH element it is responsible for: its global index.
//
// 2) YOUR TASK
//    - Write a kernel hello() in which every thread computes its global
//      index from its block number, the block size and its position in the block.
//    - Every thread prints one line (exactly this format):
//        block <b>, thread <t> -> global index <i>
//    - Start the kernel with 3 blocks of 32 threads and wait for the GPU.
//
// 3) RUN & TEST
//    Build -> Run -> Test (all lines must show [PASS])
//    Look at the order of the lines. Run it again - what do you notice?
// =====================================================================
#include <cstdio>

__global__ void hello() {
    // global index of this thread = block number * block size + position in the block
    int i = 0;

    // print: block <b>, thread <t> -> global index <i>
}

int main() {
    // start hello with 3 blocks of 32 threads

    // wait for the GPU and check for errors (like in Exercise 0)

    return 0;
}
