# Build all exercises:   make            Build one:  make ex2_vector_add
# Older CUDA (< 11.6) does not know -arch=native: use e.g.  make ARCH=sm_86
NVCC  ?= nvcc
ARCH  ?= native
FLAGS  = -O2 -arch=$(ARCH)

SRC := $(wildcard ex*.cu)
BIN := $(SRC:.cu=)

all: $(BIN)

%: %.cu
	$(NVCC) $(FLAGS) -o $@ $<

# Run one exercise (build it first):  make run F=ex2_vector_add   (optional: ARGS="1000000")
run:
	@test -n "$(F)" || { echo "Open an exercise file first."; exit 1; }
	@test -x "./$(F)" || { echo "$(F) is not built yet - click Build first."; exit 1; }
	@./$(F) $(ARGS) || true

# Check your solutions:  make test      (one exercise: make test EX=2)
test:
	@ARCH=$(ARCH) bash ../tests/run_tests.sh starter $(EX) || true

clean:
	rm -f $(BIN)

.PHONY: all clean test run
