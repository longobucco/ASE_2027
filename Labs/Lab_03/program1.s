.section .data

# ---------- Batch of N = 4 fixed values ----------
N:      .word 4
v:      .float 0.62, -0.35, 1.18, 0.07

# ---------- Batch normalization ----------
gamma:  .float 1.0
beta:   .float 0.0
eps:    .float 0.001
bn:     .space 16       # N normalized floats
result: .space 4        # sqrt(variance + eps)


# The text section contains the instructions that the CPU runs.
.section .text

# Make _start visible as the point where the program begins.
.globl _start

_start:
    la   t4, N
    lw   t0, 0(t4)         # t0 = N
    fcvt.s.w f1, t0       # f1 = float(N)

    # Step 1: mean = sum(v[i]) / N
    la   t1, v
    li   t2, 0
    la   t4, beta
    flw  f2, 0(t4)         # sum = 0.0

mean_loop:
    bge  t2, t0, mean_done
    flw  f3, 0(t1)
    fadd.s f2, f2, f3
    addi t1, t1, 4
    addi t2, t2, 1
    j    mean_loop

mean_done:
    fdiv.s f2, f2, f1     # f2 = mean

    # Step 2: variance = sum((v[i] - mean)^2) / N
    la   t1, v
    li   t2, 0
    la   t4, beta
    flw  f4, 0(t4)         # sum of squared differences = 0.0

variance_loop:
    bge  t2, t0, variance_done
    flw  f3, 0(t1)
    fsub.s f5, f3, f2
    fmul.s f5, f5, f5
    fadd.s f4, f4, f5
    addi t1, t1, 4
    addi t2, t2, 1
    j    variance_loop

variance_done:
    fdiv.s f4, f4, f1     # f4 = variance

    # Compute sqrt(variance + eps) once
    la   t4, eps
    flw  f6, 0(t4)
    fadd.s f4, f4, f6
    fsqrt.s f4, f4
    la   t3, result
    fsw  f4, 0(t3)

    # Step 3: bn[i] = gamma * (v[i] - mean) / result + beta
    la   t1, v
    la   t3, bn
    li   t2, 0
    la   t4, gamma
    flw  f6, 0(t4)
    la   t4, beta
    flw  f7, 0(t4)

normalize_loop:
    bge  t2, t0, End
    flw  f3, 0(t1)
    fsub.s f5, f3, f2
    fdiv.s f5, f5, f4
    fmul.s f5, f6, f5
    fadd.s f5, f5, f7
    fsw  f5, 0(t3)
    addi t1, t1, 4
    addi t3, t3, 4
    addi t2, t2, 1
    j    normalize_loop


# The End block stops the program and returns control to the simulator.
End:
    li a0, 0
    li a7, 93
    ecall