# VASP-CCQN

Unofficial implementation of the CCQN method for VASP 6.x (6.1–6.6).

> Wu, Y.; Wang, H. *J. Chem. Theory Comput.* **2025**, 21, 18, 9054–9065. DOI: [10.1021/acs.jctc.5c01015](https://pubs.acs.org/doi/10.1021/acs.jctc.5c01015)

## Apply

```bash
cd /path/to/vasp-6.x.x
patch -p1 --fuzz=1 --ignore-whitespace < vasp_ccqn.patch
```

Then build VASP as usual (`make std`).

## Usage

Set `IBRION = 45` in `INCAR` and provide a `ccqn.ts` input file:

```
INIT_HESSIAN_SCALE = 70.0
DELTA_WELL = 0.10
COS_PHI = 0.10
BONDS
1 2
1 3
```

Output is written to `ccqn.log`.

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

Tested on VASP 6.1.2, 6.3.2, 6.4.3, 6.6.0 with Intel oneAPI and NVHPC compilers (CPU & GPU).
