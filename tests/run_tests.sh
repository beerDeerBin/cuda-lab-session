#!/usr/bin/env bash
# Automatic checks for the CUDA lab exercises.
#   bash tests/run_tests.sh              -> tests your files in starter/
#   bash tests/run_tests.sh solutions    -> tests the reference solutions (teacher)
#   bash tests/run_tests.sh starter 2    -> only exercise 2   (possible: 0 1 2 3 4 5)
# Optional: ARCH=sm_86 bash tests/run_tests.sh   (if -arch=native is not supported)

cd "$(dirname "$0")/.." || exit 1          # repository root (lab/)
DIR="${1:-starter}"
ONLY="${2:-}"
ARCH="${ARCH:-native}"
NVCC="${NVCC:-nvcc}"
BUILD="tests/build"
mkdir -p "$BUILD"
TOTAL_OK=0; TOTAL_FAIL=0

ok()   { echo "  [PASS] $*"; TOTAL_OK=$((TOTAL_OK+1)); }
bad()  { echo "  [FAIL] $*"; TOTAL_FAIL=$((TOTAL_FAIL+1)); }
want() { [ -z "$ONLY" ] || [ "$ONLY" = "$1" ]; }

# compile <name> <source> [extra flags...] ; prints compiler errors on failure
compile() {
    local out="$BUILD/$1"; shift
    if ! "$NVCC" -O2 -arch="$ARCH" -w -o "$out" "$@" 2> "$BUILD/compile.log"; then
        bad "does not compile:"; sed 's/^/         /' "$BUILD/compile.log" | head -15
        return 1
    fi
}

# run a kernel test file that #includes the student's exercise
kernel_test() {   # <test file> <student file>
    local name; name="$(basename "$1" .cu)"
    compile "$name" "tests/$1" -DSTUDENT_FILE="\"../$DIR/$2\"" || return
    if "$BUILD/$name" > "$BUILD/$name.log" 2>&1; then
        grep -E "^\s+\[(PASS|FAIL)\]" "$BUILD/$name.log"
        TOTAL_OK=$((TOTAL_OK + $(grep -c "\[PASS\]" "$BUILD/$name.log")))
    else
        grep -E "^\s+\[(PASS|FAIL)\]|error" "$BUILD/$name.log" | head -20
        TOTAL_OK=$((TOTAL_OK + $(grep -c "\[PASS\]" "$BUILD/$name.log")))
        local f; f=$(grep -c "\[FAIL\]" "$BUILD/$name.log"); [ "$f" -eq 0 ] && f=1
        TOTAL_FAIL=$((TOTAL_FAIL + f))
    fi
}

case "$ONLY" in
    ""|0|1|2|3|4|5) ;;
    *) echo "No tests found for '$ONLY'. Open an exercise file (ex0_... to ex5_...) and try again."; exit 1 ;;
esac

echo "Testing the exercises in: $DIR/"
echo "=================================================="

if want 0; then
    echo; echo "Ex 0 - warm-up"
    if compile ex0 "$DIR/ex0_warmup.cu"; then
        "$BUILD/ex0" > "$BUILD/ex0.log" 2>&1
        if grep -q "Hello from the GPU!" "$BUILD/ex0.log"; then ok "the GPU says hello"
        else bad "no \"Hello from the GPU!\" - is the kernel started and do you wait for the GPU?"; fi
        val() { grep "^$1 *:" "$BUILD/ex0.log" | head -1 | sed -E 's/^[^:]*: *//'; }
        name=$(val "GPU name")
        if [ -n "$name" ]; then ok "GPU name ($name)"; else bad "line \"GPU name : ...\" is missing"; fi
        sms=$(val "Streaming multiprocessors" | grep -oE '^[0-9]+')
        if [ -n "$sms" ] && [ "$sms" -gt 0 ]; then ok "streaming multiprocessors ($sms)"
        else bad "line \"Streaming multiprocessors : <number>\" is missing"; fi
        ws=$(val "Warp size" | grep -oE '^[0-9]+')
        if [ "$ws" = "32" ]; then ok "warp size (32)"
        else bad "line \"Warp size : <number>\" is missing or wrong (got: '$ws')"; fi
        mt=$(val "Max threads per block" | grep -oE '^[0-9]+')
        if [ -n "$mt" ] && [ "$mt" -ge 256 ]; then ok "max threads per block ($mt)"
        else bad "line \"Max threads per block : <number>\" is missing or wrong"; fi
        mem=$(val "Global memory" | grep -oE '^[0-9.]+')
        if [ -n "$mem" ] && awk -v x="$mem" 'BEGIN { exit !(x > 0.5 && x < 1000) }'; then ok "global memory ($mem GB)"
        else bad "line \"Global memory : <number> GB\" is missing or wrong (in GB, e.g. 24.0)"; fi
    fi
fi

if want 1; then
    echo; echo "Ex 1 - hello_threads"
    if compile ex1 "$DIR/ex1_hello_threads.cu"; then
        "$BUILD/ex1" > "$BUILD/ex1.log" 2>&1
        idx=$(grep -o "index [0-9]*" "$BUILD/ex1.log" | awk '{print $2}' | sort -n | uniq | tr '\n' ' ')
        lines=$(grep -c "index" "$BUILD/ex1.log")
        expect96=$(seq 0 95 | tr '\n' ' ')
        if [ "$lines" -eq 0 ]; then
            bad "no output - is the kernel started?"
        elif [ "$lines" -eq 96 ]; then
            ok "kernel started with 3 blocks x 32 threads (96 threads)"
            if [ "$idx" = "$expect96" ]; then ok "every thread has its own global index (0-95)"
            else bad "global indices are not 0-95, each once (got: $(echo "$idx" | cut -c1-30)...)"; fi
        else
            bad "expected 96 threads (3 blocks x 32), got $lines"
            if [ "$(echo "$idx" | wc -w)" -eq "$lines" ]; then ok "every thread has its own global index"
            else bad "global indices are not unique (got: $(echo "$idx" | cut -c1-30)...)"; fi
        fi
    fi
fi

if want 2; then
    echo; echo "Ex 2 - vector_add: the kernel"
    kernel_test test_ex2.cu ex2_vector_add.cu
    echo "Ex 2 - vector_add: the full program (memory, copies, number of blocks)"
    if compile ex2 "$DIR/ex2_vector_add.cu"; then
        "$BUILD/ex2" > "$BUILD/ex2.log" 2>&1
        if grep -q "CUDA error" "$BUILD/ex2.log"; then
            bad "$(grep "CUDA error" "$BUILD/ex2.log" | head -1)"
        else
            # every line "c[i] = value" must equal sin(i) + cos(i)
            res=$(grep -E '^c\[ *[0-9]+\] *=' "$BUILD/ex2.log" | sed -E 's/c\[ *([0-9]+)\] *= *(.*)/\1 \2/' |
                  awk '{ n++; if ($2 == "" || (($2 - (sin($1) + cos($1)))^2) > 1e-8) bad++ } END { print n+0, bad+0 }')
            set -- $res
            if [ "$1" -lt 3 ]; then bad "the lines \"c[...] = ...\" are missing"
            elif [ "$2" -eq 0 ]; then ok "c[0], c[n/2] and c[n-1] are correct (memory, copies, all blocks)"
            else bad "$2 of the printed values are wrong (copies? enough blocks? copied back?)"; fi
        fi
    fi
fi

if want 3; then
    echo; echo "Ex 3 - timing"
    if compile ex3 "$DIR/ex3_timing.cu"; then
        "$BUILD/ex3" 4000000 > "$BUILD/ex3.log" 2>&1
        num() { grep "$1" "$BUILD/ex3.log" | head -1 | sed -E 's/.*: *([0-9.]+) ms.*/\1/'; }
        pos() { awk -v x="$1" 'BEGIN { exit !(x + 0 > 0) }'; }
        if grep -q "CUDA error" "$BUILD/ex3.log"; then
            bad "$(grep "CUDA error" "$BUILD/ex3.log" | head -1)"
        else
            h2d=$(num "copy CPU -> GPU"); ker=$(num "GPU kernel"); d2h=$(num "copy GPU -> CPU")
            if pos "$h2d" && pos "$d2h"; then ok "events recorded (copy to GPU $h2d ms, copy back $d2h ms)"
            else bad "copy times are not measured correctly"; fi
            if pos "$ker"; then ok "kernel time measured ($ker ms)"
            else bad "kernel time is 0 - compute kernel_ms with cudaEventElapsedTime"; fi
            if grep -q "c\[n-1\] = 3.0" "$BUILD/ex3.log"; then ok "result is correct (c[n-1] = 3.0)"
            else bad "result is wrong: $(grep 'c\[n-1\]' "$BUILD/ex3.log" | head -1)"; fi
        fi
    fi
fi

if want 4; then
    echo; echo "Ex 4 - coalescing"
    kernel_test test_ex4.cu ex4_coalescing.cu
fi

if want 5; then
    echo; echo "Ex 5 - matmul (bonus)"
    kernel_test test_ex5.cu ex5_matmul.cu
fi

echo; echo "=================================================="
echo "TOTAL: $TOTAL_OK passed, $TOTAL_FAIL failed"
[ "$TOTAL_FAIL" -eq 0 ]
