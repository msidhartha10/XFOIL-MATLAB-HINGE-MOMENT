# XFOIL Hinge-Moment Sweep (MATLAB)

This repository contains a MATLAB script to automate hinge-moment (C_h) sweeps with XFOIL by holding angle-of-attack constant and varying a control-surface deflection (flap/aileron). The script:

- Builds an XFOIL input script per deflection (puts FLAP parameters on separate lines as required by XFOIL GDES/FLAP).
- Runs XFOIL via MATLAB's system() call.
- Parses the XFOIL output for the hinge-moment/span value (reports C_h).
- Saves results to a CSV and exports a plot of C_h vs. deflection.
- Saves per-case XFOIL input (`.inp`) and output (`.out.txt`) files in a timestamped log directory for inspection.

This is useful for quick parametric studies of hinge moment vs control-surface deflection.

## Files

- hinge_moment_sweep.m (main MATLAB script) — build/configure and run the sweep.
- README.md (this file)

(If you named the main script differently, adapt instructions below to your filename.)

## Prerequisites

- MATLAB (script is plain MATLAB; no special toolboxes required).
- XFOIL (tested with XFOIL 6.99). The script calls XFOIL using system() so XFOIL must be reachable by the path configured in the script or placed on your PATH.
- An airfoil `.dat` file (or use a NACA code via the cfg.useNaca option).

## Quick Setup

1. Open the script (e.g., `hinge_moment_sweep.m`) in MATLAB editor.
2. Edit the CONFIG block at the top of the script to match your environment:

   - cfg.xfoilExe : full path to your XFOIL executable (on Windows include .exe or let Explorer hide it). Example:
     - `'E:\Apps\XFOIL\xfoil.exe'`
     - or simply `'xfoil'` if XFOIL is on your PATH.
   - cfg.airfoilDat : path to your airfoil `.dat` file (ignored if cfg.useNaca = true).
   - cfg.useNaca : set to true to use cfg.nacaCode instead of loading a `.dat` file.
   - cfg.nacaCode : NACA 4-digit code string when useNaca is true (e.g., `'2412'`).
   - cfg.Re, cfg.Mach, cfg.iter : Reynolds number, Mach, and solver iterations.
   - cfg.alpha : constant angle of attack (deg).
   - cfg.hingeX, cfg.hingeY : hinge location (chord fraction, spanwise offset).
   - cfg.deltas : vector of control-surface deflections (degrees) to sweep.

3. (Optional) Edit output paths (out.csvPath, out.figPath) and the log directory naming if desired.

## Run

In MATLAB command window:

- Make sure your current folder is the script folder or add it to the path.
- Run:

  ```matlab
  hinge_moment_sweep
  ```

The script will:

- Create a timestamped `xfoil_logs_YYYYMMDD_HHMMSS` folder in the working directory.
- For each deflection, write an `.inp` file and capture XFOIL stdout into a `.out.txt` file.
- Parse the hinge moment output and print per-case results to the MATLAB console.
- Save a CSV and a PNG plot in the current folder (or as configured).

## Outputs

- CSV (default `hinge_moment_vs_delta_matlab.csv`) with columns:
  - delta_deg : flap/aileron deflection in degrees
  - Ch        : hinge moment coefficient (extracted from XFOIL "Hinge moment/span = k * 0.5*rho*V^2*c^2")
  - alpha_deg : angle of attack used
  - Re, Mach  : conditions used
  - hinge_x, hinge_y : hinge location

- PNG plot (default `hinge_moment_vs_delta_matlab.png`): C_h vs deflection.

- Per-case logs in the `xfoil_logs_...` directory:
  - `<tag>.inp` : XFOIL input commands sent to XFOIL
  - `<tag>.out.txt` : XFOIL stdout captured — useful for debugging.

## Parsing details and robustness

- The parser looks for lines similar to:
  - `Hinge moment/span = <number> * 0.5*rho*V^2*c^2`
  - or `Mhinge/span = <number> * ...`
- It uses a case-insensitive regular expression and tolerates small format differences, but if your XFOIL build prints a different phrase the parser may fail.
- If the script prints "FAILED (no hinge line)", inspect the corresponding `.out.txt` file in the log directory. The last part of the file is also printed to the console for quick inspection.

## Troubleshooting

- XFOIL not found:
  - Verify `cfg.xfoilExe` points to the real executable, or place xfoil on your PATH and set `cfg.xfoilExe = 'xfoil'`.
  - On Windows, verify proper quoting of paths if they contain spaces.
- Permission errors writing logs:
  - Run MATLAB with sufficient permissions or change `pwd`/output locations to a writable folder.
- Parsing fails:
  - Open the `.out.txt` and search for the hinge moment line. If XFOIL prints a different variable name or format, update the regexp in the script (look for the token-matching code near the FMOM parsing section).
- Convergence / divergence in XFOIL:
  - Increase `cfg.iter`, try slightly different `cfg.alpha` initializations, or use additional XFOIL commands (modify the `lines` array in the script).

## Example CONFIG snippet

(Inside the script top CONFIG block)

```matlab
cfg.xfoilExe   = 'E:\Apps\XFOIL\xfoil.exe';
cfg.airfoilDat = 'E:\airfoils\mh115.dat';
cfg.useNaca    = false;          % set true to use cfg.nacaCode instead
cfg.nacaCode   = '2412';

cfg.Re     = 2.76e5;
cfg.Mach   = 0.04;
cfg.iter   = 400;
cfg.alpha  = 2.5;
cfg.hingeX = 0.72;
cfg.hingeY = 0.0;
cfg.deltas = [-15 -10 -5 -4 -3 -2 -1 0 1 2 3 4 5 10 15];
```

## Notes & tips

- The script writes the FLAP inputs as separate lines because XFOIL's GDES/FLAP command expects them on successive lines when used non-interactively.
- The script runs XFOIL synchronously via system() which blocks MATLAB until each case completes.
- For large sweeps consider batching or parallelizing by running multiple MATLAB sessions (each must point to a unique log folder) — the script itself does not parallelize.

