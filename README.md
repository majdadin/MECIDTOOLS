# MecidTools Architectural Suite 📐

[![AutoCAD Extension](https://img.shields.io/badge/AutoCAD-Plugin-blue.svg)](https://www.autodesk.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**MecidTools** is an open-source, lightweight 2D drafting automation suite built specifically for **AutoCAD**. Engineered to streamline native architectural documentation workflows, it accelerates cross-section generation and height measurement layouts directly from 2D plane references without binding you to rigid parametric 3D objects. https://youtu.be/vXTbqRYxO_I

### 📺 Watch the Demo Video
[![Watch the video](https://img.youtube.com/vi/vXTbqRYxO_I/maxresdefault.jpg)](https://www.youtube.com/watch?v=vXTbqRYxO_I)

---

## 🚀 Core Automation Features

### 1. Cross-Section Generation (`GEN-SECTION`)
The `GEN-SECTION` engine allows rapid architectural drafting of section cuts along any orientation vector. The macro workflow operates sequentially:

1. **Configuration Interface:** Executing the command initializes a dialog menu allowing direct definition of structural layer dimensions, boundary parameters, and target line weights.
2. **Vector Initialization:** The system prompts you to pick a primary start and end point establishing the cutting plane sequence. The tool features complete geometric rotation freedom, processing non-orthogonal and angled configurations seamlessly.
3. **Point-Selection Mapping:** The component rendering is driven dynamically by simply picking points across five fundamental architectural requirements:
   * **Wall Sections:** Structural intersection outlines.
   * **Elevation Lines:** Background projection lines.
   * **Doors:** Door profiles and clearance cuts.
   * **Windows:** Window frames and glazing details.
   * **Beams:** Structural concrete overhead elements.
4. **Insertion Layout:** Upon mapping your points, a single click positions the completed 2D line profile instantly into model space exactly where you click.

### 2. Dynamic Level Coordination (`ADD-LEVELS`)
The `ADD-LEVELS` routine provides an agile height-tracking ecosystem utilizing an optimized reference block library.

* **Automated Calculation:** Instead of manual attribute input, the tool dynamically reads target point coordinates and evaluates spatial offsets relative to your designated datum floor baseline, calculating the exact measurement automatically.
* **Omnidirectional Placement:** Supports arbitrary coordinate systems and drafting angles, allowing precise manual level markers to be dropped down anywhere regardless of active UCS rotations.

> [!NOTE]
> **Technical Operational Scope:** MecidTools is explicitly engineered for standard manual **2D presentation and production layouts**. It functions universally across any generic line/curve reference array without forcing dependencies on localized or system-specific 3D architectural object schemas. Manual refinement remains supported for final detailing.

---

## 🛠️ Installation & Setup

### Method 1: Automated Installation (Recommended)
Simply run the provided compiled Windows Installer (`MecidTools.msi`) package. It will automatically deploy the assets and bypasses administrator permission prompts by installing locally to your user profile. 

### for uninstalling the tool. It is simply done.... Go to.... installed apps => Mecidtools Architectural Suite => 3 DOTS AND UNINSTALL 


### Method 2: Manual Non-Admin Deployment
If the installer is blocked by security or network policies, the suite can be installed instantly via a direct copy-paste sequence:

1. Press `Win + R` to launch the Windows **Run** dialog.
2. Input the local roaming path sequence below and hit Enter:
   ```text
   %APPDATA%\Autodesk\ApplicationPlugins
3. Paste "MecidTools.bundle" file in there


## Enjoy your times..... 
