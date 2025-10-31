# XFOIL Hinge-Moment Sweep (MATLAB)

This repository contains a MATLAB script that automates **hinge-moment coefficient (Cₕ)** sweeps in **XFOIL** by holding angle of attack constant and varying a control-surface deflection (flap or aileron).

The script:

- Builds an XFOIL input file per deflection (with `GDES → FLAP` parameters written on separate lines, as required by XFOIL).
- Runs XFOIL using MATLAB’s `system()` call.
- Parses the hinge moment line from XFOIL output (`Hinge moment/span = k * 0.5*rho*V^2*c^2`) to extract **Cₕ = k**.
- Saves all results to a CSV and generates a plot of **Cₕ vs δ**.
- Logs per-case `.inp` and `.out.txt` files in a timestamped folder for traceability.

This setup is particularly useful for quick **parametric studies of hinge moment vs control-surface deflection**, aerodynamic balance assessment, or actuator load estimation.

---

## ✈️ Motivation

This project was built to automate **hinge moment coefficient sweeps** for control surface analysis — a task that’s essential for:

- estimating **servo or actuator loads** during design,
- validating **aerodynamic balance** of ailerons, elevators, or flaps,
- comparing results with **CFD or XFLR5**,
- and quickly checking how **hinge location** or **deflection range** affects control effort.

Manually running XFOIL for every flap angle is slow and error-prone.  
This script does it programmatically — ensuring reproducibility, clean logging, and correct geometry updates (with proper handling of `GDES FLAP` input quirks).

---

## 📁 Files

- **`hinge_moment_sweep.m`** — Main MATLAB script (configuration, XFOIL execution, parsing, plotting).  
- **`README.md`** — This file.

---

## 🧩 Prerequisites

- **MATLAB** — Standard installation; no toolboxes required.  
- **XFOIL** — Tested with XFOIL 6.99. Must be callable from MATLAB via a full path or available on your system PATH.  
- **Airfoil geometry** — Either a `.dat` file or a NACA code (via `cfg.useNaca`).

---

## ⚙️ Quick Setup

1. Open the script (`hinge_moment_sweep.m`) in MATLAB.  
2. Edit the **CONFIG** block at the top to suit your case:

   - `cfg.xfoilExe`: Path to your XFOIL executable.  
     - Example: `'E:\Apps\XFOIL\xfoil.exe'` or simply `'xfoil'` if it’s on PATH.  
   - `cfg.airfoilDat`: Path to your `.dat` airfoil file. Ignored if `cfg.useNaca = true`.  
   - `cfg.useNaca`: Set `true` to use a NACA code instead of a `.dat` file.  
   - `cfg.nacaCode`: NACA 4-digit code (e.g., `'2412'`).  
   - `cfg.Re`, `cfg.Mach`, `cfg.iter`: Reynolds number, Mach number, and iteration limit.  
   - `cfg.alpha`: Constant angle of attack in degrees.  
   - `cfg.hingeX`, `cfg.hingeY`: Hinge location (x/c, y/c).  
   - `cfg.deltas`: Array of control-surface deflections (°) to sweep.

3. (Optional) Edit output file paths (`out.csvPath`, `out.figPath`) and log directory name pattern.

---

## ▶️ Run

In MATLAB:

```matlab
hinge_moment_sweep
````

The script will:

* Create a timestamped log directory (`xfoil_logs_YYYYMMDD_HHMMSS`).
* Generate `.inp` and `.out.txt` files for each deflection.
* Parse the hinge moment coefficient and print results in the console.
* Save the compiled results to a `.csv` and a `.png` plot.

---

## 📈 Outputs

* **CSV file** (default: `hinge_moment_vs_delta_matlab.csv`)

  | Column               | Description                        |
  | -------------------- | ---------------------------------- |
  | `delta_deg`          | Flap/aileron deflection (°)        |
  | `Ch`                 | Hinge moment coefficient           |
  | `alpha_deg`          | Angle of attack used               |
  | `Re`, `Mach`         | Flow conditions                    |
  | `hinge_x`, `hinge_y` | Hinge coordinates (chord fraction) |

* **Plot** (default: `hinge_moment_vs_delta_matlab.png`)

  * Shows **Cₕ vs δ** at the specified α, Re, and Mach.

* **Logs** (`xfoil_logs_...` folder):

  * `<case>.inp` — Command script sent to XFOIL.
  * `<case>.out.txt` — Captured XFOIL output, useful for debugging.

---

## 🔍 Parsing Details

The parser searches for lines such as:

```
Hinge moment/span = <number> * 0.5*rho*V^2*c^2
Mhinge/span = <number> * ...
```

It uses a robust, case-insensitive regex to tolerate formatting variations.
If it fails to find a match, you’ll see:

```
δ = +x deg ... FAILED (no hinge line)
```

In that case, check the corresponding `.out.txt` in the log directory — the last few hundred characters are printed to the console for convenience.

---

## 🧰 Troubleshooting

**XFOIL not found**

* Verify the path in `cfg.xfoilExe`, or ensure XFOIL is added to your PATH.
* Use double quotes around paths with spaces (the script already handles this).

**No hinge moment line found**

* May indicate convergence failure.
  Try increasing `cfg.iter`, adjusting α slightly, or re-running at higher Re.

**Permission issues writing logs**

* Change the working directory to a writable folder.

**Geometry didn’t update**

* XFOIL requires `GDES → FLAP` inputs on *separate lines* in non-interactive mode — this script already handles that, but confirm the log file if geometry looks wrong.

---

## 🧾 Example Configuration

```matlab
cfg.xfoilExe   = 'E:\Apps\XFOIL\xfoil.exe';
cfg.airfoilDat = 'E:\airfoils\mh115.dat';
cfg.useNaca    = false;
cfg.nacaCode   = '2412';

cfg.Re     = 2.76e5;
cfg.Mach   = 0.04;
cfg.iter   = 400;
cfg.alpha  = 2.5;
cfg.hingeX = 0.72;
cfg.hingeY = 0.00;
cfg.deltas = [-15 -10 -5 -4 -3 -2 -1 0 1 2 3 4 5 10 15];
```

---

## 💡 Notes & Tips

* The script writes **FLAP inputs on separate lines** because XFOIL ignores multi-line commands otherwise.
* Execution is sequential (`system()` blocks MATLAB until completion).
* For large parameter sweeps, consider parallelizing by running multiple MATLAB sessions with unique log directories.
* If you’re comparing with CFD or XFLR5, remember that XFOIL’s hinge moment coefficient uses **chord-based normalization**, not full-wing reference.

---

## 🧠 Future Improvements

* Add α-sweep support (Cₕ vs δ vs α).
* Parameterize hinge location to assess aerodynamic balance.
* Return results directly as MATLAB variables (no file I/O).

---
