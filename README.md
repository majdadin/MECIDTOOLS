<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MecidTools Architectural Suite Documentation</title>
    <style>
        :root {
            --primary: #2563eb;
            --primary-dark: #1d4ed8;
            --text-main: #1f2937;
            --text-muted: #4b5563;
            --bg-light: #f9fafb;
            --border-color: #e5e7eb;
            --code-bg: #1e1e1e;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            color: var(--text-main);
            max-width: 850px;
            margin: 40px auto;
            padding: 0 20px;
            background-color: #ffffff;
        }

        h1 {
            font-size: 2.25rem;
            color: #111827;
            border-bottom: 2px solid var(--border-color);
            padding-bottom: 10px;
            margin-bottom: 20px;
        }

        h2 {
            font-size: 1.5rem;
            color: #1f2937;
            margin-top: 30px;
            padding-bottom: 5px;
            border-bottom: 1px solid var(--border-color);
        }

        h3 {
            font-size: 1.2rem;
            color: #374151;
            margin-top: 20px;
        }

        p {
            color: var(--text-muted);
            margin-bottom: 16px;
        }

        .badge {
            background-color: var(--primary);
            color: white;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.85rem;
            font-weight: 600;
            display: inline-block;
            margin-bottom: 10px;
        }

        ul, ol {
            margin-bottom: 20px;
            padding-left: 24px;
            color: var(--text-muted);
        }

        li {
            margin-bottom: 8px;
        }

        .nested-list {
            margin-top: 8px;
            list-style-type: circle;
        }

        .notice-box {
            background-color: var(--bg-light);
            border-left: 4px solid #9ca3af;
            padding: 15px;
            margin: 20px 0;
            border-radius: 0 6px 6px 0;
        }

        .notice-box strong {
            color: #111827;
        }

        code {
            font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
            background-color: #f3f4f6;
            color: #d97706;
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 0.9em;
        }

        pre {
            background-color: var(--code-bg);
            color: #g8f6f2;
            padding: 16px;
            border-radius: 8px;
            overflow-x: auto;
            font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
            font-size: 0.9rem;
            line-height: 1.45;
            box-shadow: inset 0 1px 3px rgba(0,0,0,0.1);
        }

        pre code {
            background-color: transparent;
            color: #e0e0e0;
            padding: 0;
        }

        .file-tree-comment {
            color: #757575;
        }

        details {
            background-color: var(--bg-light);
            border: 1px solid var(--border-color);
            border-radius: 6px;
            padding: 12px;
            margin: 20px 0;
        }

        details summary {
            font-weight: 600;
            cursor: pointer;
            color: var(--primary);
            outline: none;
        }

        details[open] summary {
            margin-bottom: 10px;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 5px;
        }
    </style>
</head>
<body>

    <h1>MecidTools Architectural Suite</h1>
    <span class="badge">AutoCAD Extension</span>
    
    <p>MecidTools is an open-source, flexible 2D drafting automation extension built specifically for AutoCAD. Designed to streamline native architectural documentation, it accelerates cross-section generation and height measurement workflows directly from 2D plane references without binding you to rigid parametric objects.</p>

    <h2>Core Automation Mechanisms</h2>

    <h3>1. Cross-Section Generation (<code>GEN-SECTION</code>)</h3>
    <p>The <code>GEN-SECTION</code> engine allows rapid architectural drafting of section cuts along any orientation vector. The macro workflow operates sequentially:</p>
    <ol>
        <li><strong>Configuration Interface:</strong> Executing the command initializes a dialog layout allowing direct definition of structural layer profiles, boundary parameters, and target layer lineweights.</li>
        <li><strong>Vector Initialization:</strong> The system prompts for a primary start and end point establishing the cutting plane sequence. The tool features complete geometric rotation freedom, processing non-orthogonal and angled cutting configurations seamlessly.</li>
        <li><strong>Point-Selection Mapping:</strong> The component rendering is driven manually by selecting points across five fundamental architectural elements:
            <ul class="nested-list">
                <li>Structural Wall Intersections</li>
                <li>Elevation Projection Lines</li>
                <li>Door Openings & Profiles</li>
                <li>Window Frames & Glazing Details</li>
                <li>Structural Concrete Beams</li>
            </ul>
        </li>
        <li><strong>Insertion Layout:</strong> Upon mapping configuration requirements, a single click positions the completed 2D line profile instantly into model space.</li>
    </ol>

    <h3>2. Dynamic Level Coordination (<code>ADD-LEVELS</code>)</h3>
    <p>The <code>ADD-LEVELS</code> routine provides an agile height-tracking ecosystem utilizing an optimized reference block library.</p>
    <ul>
        <li><strong>Automated Calculation:</strong> Instead of manual attribute input, the tool dynamically reads target point elevations and evaluates spatial offsets relative to your designated datum floor baseline.</li>
        <li><strong>Omnidirectional Placement:</strong> Supports arbitrary coordinate systems and drafting angles, allowing precise manual level markers to be dropped down anywhere regardless of active UCS rotations.</li>
    </ul>

    <div class="notice-box">
        <strong>Technical Operational Scope:</strong> MecidTools is explicitly engineered for standard manual <strong>2D presentation and production layouts</strong>. It functions universally across any generic line/curve reference array without forcing dependencies on localized or system-specific 3D architectural object schemas. Manual refinement remains supported for final detailing.
    </div>

    <h2>Deployment & Installation</h2>
    <p>If deploying via the automated Windows Installer (<code>.msi</code>) bundle package fails or is restricted by security policies, the suite can be installed instantly using manual directory placement.</p>

    <details>
        <summary>View Manual Installation Method (Non-Admin)</summary>
        <p>1. Press <code>Win + R</code> to launch the Windows Run execution utility.</p>
        <p>2. Input the local roaming sequence below and hit Enter:</p>
        <pre><code>%APPDATA%\Autodesk\ApplicationPlugins</code></pre>
        <p>3. Unzip and drop the clean <code>MecidTools.bundle</code> folder hierarchy directly into this working directory path.</p>
    </details>

    <h3>Target Directory Mapping</h3>
    <p>For successful startup initialization, ensure your asset deployment mirrors the following tree architecture perfectly:</p>
    <pre><code>%APPDATA%\Autodesk\ApplicationPlugins\MecidTools.bundle\
├── PackageContents.xml       <span class="file-tree-comment"># Bundle manifest (registers commands & autoload rules)</span>
└── Contents\                 <span class="file-tree-comment"># Core plugin execution assets directory</span>
    ├── MecidTools.lsp        <span class="file-tree-comment"># Core LISP Suite (GEN-SECTION & ADD-LEVELS engines)</span>
    └── custom_detail.dwg     <span class="file-tree-comment"># Base block library drawing (contains 'level_marker')</span></code></pre>

    <p><em>Note: Upon directory validation, AutoCAD automatically discovers the active <code>.bundle</code> package extension during startup sequence initialization and safely processes autoload rules.</em></p>

</body>
</html>
