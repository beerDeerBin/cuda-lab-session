# CUDA Lab – Exercises

## Setup (once)
1. In a terminal, inside the `lab` folder:
   ```bash
   bash setup.sh
   ```
   This installs the recommended VS Code extensions, checks the CUDA tools and opens the lab in VS Code.
   *Without the script:* open the `lab` folder in VS Code, then `Ctrl+Shift+X` → type `@recommended` → install all.
2. Three buttons appear in the status bar at the bottom. They always work on the file that is **currently open**:

| Button | What it does |
|--------|--------------|
| **Build** | compiles the exercise |
| **Run** | runs it (click **Build** first after every change) |
| **Test** | checks your solution automatically – every line shows `[PASS]` or `[FAIL]` |

## Every exercise works the same way
Each file starts with a short header:
1. **The problem** – what we want to find out
2. **Your task** – write the missing code yourself (the file header says what it must do)
3. **Run & test** – click **Build**, then **Run**, then **Test** until everything shows `[PASS]`

| # | File | Topic |
|---|------|-------|
| 0 | `ex0_warmup.cu` | Warm-up: Hello, GPU! |
| 1 | `ex1_hello_threads.cu` | Thread indexing |
| 2 | `ex2_vector_add.cu` | Vector addition |
| 3 | `ex3_timing.cu` | Where does the time go? |
| 4 | `ex4_coalescing.cu` | Memory access patterns |
| 5 | `ex5_matmul.cu` | **Bonus:** shared memory tiling |

## Cheat sheet
The exercise files only contain the basics – the header of each file says what the program must do and print. You may use AI, but you must be able to explain your code.

```cpp
int i = blockIdx.x * blockDim.x + threadIdx.x;          // global thread index
int blocks = (n + threads - 1) / threads;               // round up
cudaMalloc(&d_x, bytes);                                // allocate on the GPU
cudaMemcpy(dst, src, bytes, cudaMemcpyHostToDevice);    // CPU -> GPU  (DeviceToHost: GPU -> CPU)
kernel<<<blocks, threads>>>(args...);                   // launch
cudaDeviceProp prop; cudaGetDeviceProperties(&prop, 0); // GPU info (prop.name, ...)

// every cuda... function returns a cudaError_t - check it:
cudaError_t err = cudaGetLastError();                   // error when starting the kernel?
if (err == cudaSuccess) err = cudaDeviceSynchronize();  // wait for the GPU - error while running?
if (err != cudaSuccess) { printf("CUDA error: %s\n", cudaGetErrorString(err)); return 1; }

cudaEvent_t e; cudaEventCreate(&e); cudaEventRecord(e); // timing: record events around a step
cudaEventSynchronize(e_stop); cudaEventElapsedTime(&ms, e_start, e_stop);
cudaFree(d_x);                                          // free GPU memory
```

## Without the buttons
```bash
cd starter
make ex2_vector_add                         # build
make run F=ex2_vector_add                   # run
make test EX=2                              # test
```
