# VASP-CCQN

Unofficial implementation of the CCQN method for VASP 6.x (6.1–6.6), v2.

> Wu, Y.; Wang, H. *J. Chem. Theory Comput.* **2025**, 21, 18, 9054–9065. DOI: [10.1021/acs.jctc.5c01015](https://pubs.acs.org/doi/10.1021/acs.jctc.5c01015)

## Apply

```bash
cd /path/to/vasp-6.x.x
patch -p1 --fuzz=1 --ignore-whitespace < vasp_ccqn.patch
```

Then build VASP as usual (`make std`).

## Usage

Set `IBRION = 45` and a **negative** `EDIFFG` (force criterion, e.g. `EDIFFG = -0.05`)
in `INCAR`, and provide a `ccqn.ts` input file. The ascent direction is defined by
exactly one of three modes:

**BONDS mode** (paper Algorithm 2; reactive bonds known):

```
BONDS
1 2
1 3
```

**Interpolation mode** (paper eq 18, linear variant; final state known):

```
FINAL_POSCAR = POSCAR_fs
```

`POSCAR_fs` is a standard POSCAR of the product state with identical atom
count and ordering; the direction is recomputed each step with
minimum-image treatment.

**VECTOR mode** (fixed direction; not part of the paper — a manual override):

```
VECTOR
0.0 0.0 1.0
...            ! NIONS lines, or sparse format: atom_index vx vy vz
```

Optional parameters (defaults follow the paper SI settings for
heterogeneous catalysis):

```
INIT_HESSIAN_SCALE = 70.0   ! B0 = 70 x identity (eV/A^2)
DELTA_WELL   = 0.10         ! step length on the sphere in the well phase
COS_PHI      = 0.10         ! cone half-angle cosine (SI: 0.5 for molecules)
DELTA_MIN    = 0.10         ! PRFO trust-radius bounds (SI: 0.03-0.06
DELTA_MAX    = 0.20         !   for molecular systems)
CONV_NEG_TOL = 0.05         ! eigenvalue threshold (eV/A^2) counting
                            !   "significant" negative modes; convergence
                            !   additionally requires exactly one such mode.
                            !   Set negative to disable (pure force criterion,
                            !   the behaviour used in the paper SI).
NEG_EIG_TOL  = 1e-8         ! numerical-zero tolerance of the well/inflection test
RHO_INC = 1.2  RHO_DEC = 2.0  SIGMA_INC = 1.2  SIGMA_DEC = 0.5
VERBOSE = 1
```

Output is written to `ccqn.log` (overwritten each run) and OUTCAR.

## v2 changes

- One Hessian eigendecomposition per ionic step (cached and reused by the
  diagnostics, the TS-BFGS update, and PRFO); the PRFO subproblems are solved
  in the eigenbasis via the secular equation (paper eqs 13–17) instead of
  rediagonalizing inside the bisection loop.
- PRFO follows the paper's trust-region semantics: the Newton step is taken
  directly when inside the trust region.
- ALM (paper Algorithm 1): `sigma0 = 10` so the precision schedule actually
  tightens (with `sigma0 = 1` and a feasible start the subproblem was returned
  unconverged); inner solver is Barzilai–Borwein with a nonmonotone Armijo
  safeguard; warm start between consecutive well steps.
- Minimum-image convention in the BONDS direction (bonds crossing the periodic
  boundary were mis-directed before).
- Convergence: requires `EDIFFG < 0` (errors out otherwise — previously it
  silently ran all NSW steps), force criterion plus exactly one significant
  negative mode (`CONV_NEG_TOL`, disable with a negative value).
- New interpolation mode (`FINAL_POSCAR`).
- Fixed: a dense VECTOR block placed before other keys no longer swallows them.
- `PRFO_A_INIT` / `PRFO_MAX_ITER` are deprecated and ignored.

## Citation

If you use this code, please cite:

```bibtex
@article{wu2025ccqn,
  title={Cone-Shaped Constrained Quasi-Newton Method: Efficient and Robust Single-Ended Transition State Optimization Algorithm},
  author={Wu, Yinkai and Wang, Haifeng},
  journal={Journal of Chemical Theory and Computation},
  volume={21},
  number={18},
  pages={9054--9065},
  year={2025},
  doi={10.1021/acs.jctc.5c01015}
}
```

## Compatibility

v1 tested on VASP 6.1.2, 6.3.2, 6.4.3, 6.6.0 with Intel oneAPI and NVHPC
compilers (CPU & GPU). The v2 patch applies cleanly to 6.1.2, 6.2.1, 6.3.2,
6.4.3, 6.5.0, 6.5.1 and 6.6.0.

Known limitation: on 6.1.x/6.2.x the legacy CUDA-C port (`make gpu`) is not
supported — `ccqn_ts.o` is only added to the standard object list. `make std`
and the OpenACC GPU builds (6.3+) are unaffected.
