;;; ==========================================================================
;;; MASTER ARCHITECTURAL PRODUCTION & TOOL SUITE (OPEN SOURCE EDITION)
;;; Features: Architectural Section Generator & English Level Placement Engine
;;; ==========================================================================
;;; MIT License & Professional Use Disclaimer Notice
;;; Copyright (c) 2026 MecidTools
;;; 
;;; This software is licensed under the MIT License. A full copy of the 
;;; license text and professional liability disclaimers can be found in the 
;;; project root directory file: "MIT License.txt"

;;; Set initial global defaults
(setq *room-height* 300.0
      *slab-thickness* 15.0
      *door-height* 220.0
      *window-sill* 90.0
      *window-head* 220.0
      *beam-depth* 50.0
      *lw-structure* 60
      *lw-elements* 25
      *lw-elevation-close* 30
      *lw-elevation-med* 18
      *lw-elevation-far* 9
      *depth-threshold-close* 50.0
      *depth-threshold-far* 200.0)

;;; Global plane vectors remembered across routines
(setq *sect-vec-u* '(1.0 0.0)
      *sect-vec-v* '(0.0 1.0))

;;; ============================================================
;;; DYNAMIC POP-UP WINDOW INTERFACE (DCL GENERATOR)
;;; ============================================================

(defun show-settings-dialog (/ dcl-file file dcl-id status)
  (setq dcl-file (vl-filename-mktemp "section_settings.dcl"))
  (setq file (open dcl-file "w"))
  (write-line "section_settings : dialog { title = \"Section / Elevation Parameters\";" file)
  (write-line "  : boxed_column { label = \"Structural & Architectural Dimensions (cm)\";" file)
  (write-line "    : edit_box { label = \"Room Clear Height:\"; key = \"txt_rh\"; edit_width = 10; }" file)
  (write-line "    : edit_box { label = \"Slab Thickness:\"; key = \"txt_st\"; edit_width = 10; }" file)
  (write-line "    : edit_box { label = \"Beam Drop Depth:\"; key = \"txt_bd\"; edit_width = 10; }" file)
  (write-line "    : edit_box { label = \"Door Height:\"; key = \"txt_dh\"; edit_width = 10; }" file)
  (write-line "    : edit_box { label = \"Window Sill Height:\"; key = \"txt_ws\"; edit_width = 10; }" file)
  (write-line "    : edit_box { label = \"Window Head Height:\"; key = \"txt_wh\"; edit_width = 10; }" file)
  (write-line "  }" file)
  (write-line "  : boxed_column { label = \"Lineweight Weights & Thresholds\";" file)
  (write-line "    : edit_box { label = \"Structure Cut Lineweight:\"; key = \"txt_lws\"; edit_width = 10; }" file)
  (write-line "    : edit_box { label = \"Architectural Elements Lineweight:\"; key = \"txt_lwe\"; edit_width = 10; }" file)
  (write-line "    : edit_box { label = \"Close Depth Threshold (cm):\"; key = \"txt_dtc\"; edit_width = 10; }" file)
  (write-line "    : edit_box { label = \"Far Depth Threshold (cm):\"; key = \"txt_dtf\"; edit_width = 10; }" file)
  (write-line "  }" file)
  (write-line "  spacer; ok_cancel; }" file)
  (close file)

  (setq dcl-id (load_dialog dcl-file))
  (if (not (new_dialog "section_settings" dcl-id))
    (progn (vl-file-delete dcl-file) (exit))
  )

  (set_tile "txt_rh" (rtos *room-height* 2 1))
  (set_tile "txt_st" (rtos *slab-thickness* 2 1))
  (set_tile "txt_bd" (rtos *beam-depth* 2 1))
  (set_tile "txt_dh" (rtos *door-height* 2 1))
  (set_tile "txt_ws" (rtos *window-sill* 2 1))
  (set_tile "txt_wh" (rtos *window-head* 2 1))
  (set_tile "txt_lws" (itoa (fix *lw-structure*)))
  (set_tile "txt_lwe" (itoa (fix *lw-elements*)))
  (set_tile "txt_dtc" (rtos *depth-threshold-close* 2 1))
  (set_tile "txt_dtf" (rtos *depth-threshold-far* 2 1))

  (action_tile "accept"
    (strcat
      "(setq *room-height* (distof (get_tile \"txt_rh\")))"
      "(setq *slab-thickness* (distof (get_tile \"txt_st\")))"
      "(setq *beam-depth* (distof (get_tile \"txt_bd\")))"
      "(setq *door-height* (distof (get_tile \"txt_dh\")))"
      "(setq *window-sill* (distof (get_tile \"txt_ws\")))"
      "(setq *window-head* (distof (get_tile \"txt_wh\")))"
      "(setq *lw-structure* (fix (atoi (get_tile \"txt_lws\"))))"
      "(setq *lw-elements* (fix (atoi (get_tile \"txt_lwe\"))))"
      "(setq *depth-threshold-close* (distof (get_tile \"txt_dtc\")))"
      "(setq *depth-threshold-far* (distof (get_tile \"txt_dtf\")))"
      "(done_dialog 1)"
    )
  )
  (action_tile "cancel" "(done_dialog 0)")

  (setq status (start_dialog))
  (unload_dialog dcl-id)
  (vl-file-delete dcl-file)
  (= status 1)
)

;;; ============================================================
;;; POINT CAPTURE & PROJECTION FUNCTIONS
;;; ============================================================

(defun capture-points-safe (step-name requires-pairs / points current-pt looping current-idx wcs-pt)
  (setq points '()) (setq looping T)
  (princ (strcat "\n=======================================================\n>>>> [COLLECTING] " step-name "\n======================================================="))
  (while looping
    (setq current-idx (1+ (length points)))
    (setq current-pt (getpoint (strcat "\n[" step-name "] Pick point " (itoa current-idx) " (Press Enter to Finish / ESC to Cancel): ")))
    (cond
      ((null current-pt)
       (if (and requires-pairs (/= (rem (length points) 2) 0)) (setq points (cdr points)))
       (setq looping nil))
      (T 
       (setq wcs-pt (trans current-pt 1 0))
       (setq points (append points (list (list (car wcs-pt) (cadr wcs-pt))))))
    )
  )
  points
)

(defun safe-add-line (pt1 pt2 lineweight-val layer-name color-num / acad-obj doc layers layObj line IntLW ms)
  (setq acad-obj (vlax-get-acad-object)
        doc (vla-get-activedocument acad-obj)
        layers (vla-get-layers doc)
        ms (vla-get-ModelSpace doc)) ; Enforced casing for cross-compatibility
  
  (if (vl-catch-all-error-p (setq layObj (vl-catch-all-apply 'vla-item (list layers layer-name))))
    (progn
      (setq layObj (vla-add layers layer-name))
      (vla-put-color layObj color-num)
    )
  )
  
  (setq IntLW (fix lineweight-val))
  (if (< IntLW 0) (setq IntLW 0))
  
  (setq line (vla-addline ms
                          (vlax-3d-point (list (car pt1) (cadr pt1) 0.0))
                          (vlax-3d-point (list (car pt2) (cadr pt2) 0.0))))
  
  (vla-put-layer line layer-name)
  (vla-put-lineweight line IntLW)
  line
)

(defun project-rotated-point (pt ref-pt vec-u vec-v base-x base-y / dx dy proj-x)
  (setq dx (- (car pt) (car ref-pt)) 
        dy (- (cadr pt) (cadr ref-pt)))
  (setq proj-x (+ (* dx (car vec-u)) (* dy (cadr vec-u))))
  (list (+ base-x proj-x) base-y)
)

;;; ============================================================
;;; COMMAND 1: ARCHITECTURAL SECTION GENERATOR CORE
;;; ============================================================

(defun C:GEN-SECTION (/ acad-object acad-doc ms old-cmd-echo wall-intersections elevation-mode
                        elevation-points sx door-points window-points beam-points ref-pt pt-end
                        section-origin base-x base-y all-x-coords min-drawing-x max-drawing-x
                        slab-top-y ceiling-line-y elevation-top-y sx1 sx2 bottom-y top-limit-y
                        depth abs-depth lw temp-pt temp-pt2 i vec-len execution-continue wcs-ref wcs-end wcs-origin old-error)
  
  (vl-load-com)
  (setq execution-continue T)

  (setq old-cmd-echo (getvar "CMDECHO")
        old-error *error*)

  (defun *error* (msg)
    (setvar "CMDECHO" old-cmd-echo)
    (setq *error* old-error)
    (if (not (member msg '("Function cancelled" "quit / exit abort")))
      (princ (strcat "\nError encountered: " msg))
    )
    (princ "\n--> Environment settings successfully restored.")
    (princ)
  )
  
  (if execution-continue
    (if (not (show-settings-dialog))
      (setq execution-continue nil)
    )
  )
  
  (if execution-continue
    (progn
      (setq acad-object (vlax-get-acad-object)
            acad-doc (vla-get-activedocument acad-object)
            ms (vla-get-ModelSpace acad-object)) ; Fixed Casing
      
      (princ "\n--> Define the orientation plane of your Section Line.")
      (setq ref-pt (getpoint "\nPick START Point of Section Cut Line: "))
      (if ref-pt (setq pt-end (getpoint ref-pt "\nPick END Point of Section Cut Line: ")))
      
      (if (or (null ref-pt) (null pt-end))
        (progn (princ "\nError: Invalid plane coordinates.") (setq execution-continue nil))
        (progn
          (setq wcs-ref (trans ref-pt 1 0)
                wcs-end (trans pt-end 1 0))
        )
      )
    )
  )
  
  (if execution-continue
    (progn
      (setq vec-len (distance wcs-ref wcs-end)
            *sect-vec-u* (list (/ (- (car wcs-end) (car wcs-ref)) vec-len) (/ (- (cadr wcs-end) (cadr wcs-ref)) vec-len))
            *sect-vec-v* (list (- (cadr *sect-vec-u*)) (car *sect-vec-u*)))
      
      (setq wall-intersections (capture-points-safe "WALL LAYOUT CUTS" T))
      (setq elevation-mode (null wall-intersections))
      
      (setq elevation-points (capture-points-safe "BACKGROUND ELEVATION" nil)
            door-points (capture-points-safe "DOOR FRAMES" T)
            window-points (capture-points-safe "WINDOW CORES" T))
      
      (if (not elevation-mode) (setq beam-points (capture-points-safe "STRUCTURAL BEAMS" T)) (setq beam-points '()))
      
      (setq section-origin (getpoint "\nClick in an empty space to place your drawing output: "))
      (if (null section-origin) 
        (setq execution-continue nil)
        (setq wcs-origin (trans section-origin 1 0))
      )
    )
  )
  
  (if execution-continue
    (progn
      (setvar "CMDECHO" 0)
      (setq base-x (car wcs-origin) base-y (cadr wcs-origin) all-x-coords '())
      
      (foreach lst (list wall-intersections elevation-points door-points window-points)
        (if lst (foreach pt lst
          (setq temp-pt (project-rotated-point pt wcs-ref *sect-vec-u* *sect-vec-v* base-x base-y))
          (setq all-x-coords (append all-x-coords (list (car temp-pt))))
        )))
      
      (setq min-drawing-x (apply 'min all-x-coords) max-drawing-x (apply 'max all-x-coords))
      (setq slab-top-y (+ base-y *room-height*) ceiling-line-y (- slab-top-y *slab-thickness*) elevation-top-y (+ base-y *room-height*))
      
      (safe-add-line (list min-drawing-x base-y) (list max-drawing-x base-y) (fix *lw-elevation-close*) "ground" 8)
      
      (if (not elevation-mode)
        (progn
          (safe-add-line (list min-drawing-x ceiling-line-y) (list max-drawing-x ceiling-line-y) (fix *lw-structure*) "slab" 4)
          (safe-add-line (list min-drawing-x slab-top-y) (list max-drawing-x slab-top-y) (fix *lw-structure*) "slab" 4)
          
          (setq i 0)
          (while (< i (1- (length wall-intersections)))
            (setq temp-pt (project-rotated-point (nth i wall-intersections) wcs-ref *sect-vec-u* *sect-vec-v* base-x base-y)
                  temp-pt2 (project-rotated-point (nth (1+ i) wall-intersections) wcs-ref *sect-vec-u* *sect-vec-v* base-x base-y))
            (safe-add-line (list (car temp-pt) base-y) (list (car temp-pt) ceiling-line-y) (fix *lw-structure*) "wall" 2)
            (safe-add-line (list (car temp-pt2) base-y) (list (car temp-pt2) ceiling-line-y) (fix *lw-structure*) "wall" 2)
            (setq i (+ i 2))
          )
          
          (setq i 0)
          (while (< i (1- (length beam-points)))
            (setq temp-pt (project-rotated-point (nth i beam-points) wcs-ref *sect-vec-u* *sect-vec-v* base-x base-y)
                  temp-pt2 (project-rotated-point (nth (1+ i) beam-points) wcs-ref *sect-vec-u* *sect-vec-v* base-x base-y)
                  bottom-y (- ceiling-line-y *beam-depth*))
            (safe-add-line (list (car temp-pt) ceiling-line-y) (list (car temp-pt) bottom-y) (fix *lw-structure*) "beam" 1)
            (safe-add-line (list (car temp-pt2) ceiling-line-y) (list (car temp-pt2) bottom-y) (fix *lw-structure*) "beam" 1)
            (safe-add-line (list (car temp-pt) bottom-y) (list (car temp-pt2) bottom-y) (fix *lw-structure*) "beam" 1)
            (setq i (+ i 2))
          )
        )
        (safe-add-line (list min-drawing-x elevation-top-y) (list max-drawing-x elevation-top-y) (fix *lw-elevation-close*) "elevation" 3)
      )
      
      (setq i 0)
      (while (< i (1- (length door-points)))
        (setq temp-pt (project-rotated-point (nth i door-points) wcs-ref *sect-vec-u* *sect-vec-v* base-x base-y)
              temp-pt2 (project-rotated-point (nth (1+ i) door-points) wcs-ref *sect-vec-u* *sect-vec-v* base-x base-y))
        (safe-add-line (list (car temp-pt) base-y) (list (car temp-pt) (+ base-y *door-height*)) (fix *lw-elements*) "door" 30)
        (safe-add-line (list (car temp-pt2) base-y) (list (car temp-pt2) (+ base-y *door-height*)) (fix *lw-elements*) "door" 30)
        (safe-add-line (list (car temp-pt) (+ base-y *door-height*)) (list (car temp-pt2) (+ base-y *door-height*)) (fix *lw-elements*) "door" 30)
        (setq i (+ i 2))
      )
      
      (setq i 0)
      (while (< i (1- (length window-points)))
        (setq temp-pt (project-rotated-point (nth i window-points) wcs-ref *sect-vec-u* *sect-vec-v* base-x base-y)
              temp-pt2 (project-rotated-point (nth (1+ i) window-points) wcs-ref *sect-vec-u* *sect-vec-v* base-x base-y))
        (safe-add-line (list (car temp-pt) (+ base-y *window-sill*)) (list (car temp-pt) (+ base-y *window-head*)) (fix *lw-elements*) "window" 150)
        (safe-add-line (list (car temp-pt2) (+ base-y *window-sill*)) (list (car temp-pt2) (+ base-y *window-head*)) (fix *lw-elements*) "window" 150)
        (safe-add-line (list (car temp-pt) (+ base-y *window-sill*)) (list (car temp-pt2) (+ base-y *window-sill*)) (fix *lw-elements*) "window" 150)
        (safe-add-line (list (car temp-pt) (+ base-y *window-head*)) (list (car temp-pt2) (+ base-y *window-head*)) (fix *lw-elements*) "window" 150)
        (setq i (+ i 2))
      )
      
      (if elevation-mode (setq top-limit-y elevation-top-y) (setq top-limit-y ceiling-line-y))
      (foreach pt elevation-points
        (setq temp-pt (project-rotated-point pt wcs-ref *sect-vec-u* *sect-vec-v* base-x base-y))
        
        (setq dx (- (car pt) (car wcs-ref))
              dy (- (cadr pt) (cadr wcs-ref))
              depth (+ (* dx (car *sect-vec-v*)) (* dy (cadr *sect-vec-v*)))
              abs-depth (abs depth))
        
        (setq lw *lw-elevation-far*)
        (if (< abs-depth *depth-threshold-close*) 
          (setq lw *lw-elevation-close*)
          (if (< abs-depth *depth-threshold-far*) 
            (setq lw *lw-elevation-med*)
          )
        )
        (safe-add-line (list (car temp-pt) base-y) (list (car temp-pt) top-limit-y) (fix lw) "elevation" 3)
      )
      
      (setvar "CMDECHO" old-cmd-echo) 
      (vla-regen acad-doc acAllViewports) 
    )
  )
  (setvar "CMDECHO" old-cmd-echo)
  (setq *error* old-error)
  (princ)
)

;;; ============================================================
;;; COMMAND 2: AUTOMATED LEVEL PLACEMENT MARKER (ENGLISH ENGINE)
;;; ============================================================

(defun C:ADD-LEVELS (/ blk-name ref-pt dir-pt pos-pt target-pt looping scale 
                      wcs-ref wcs-dir wcs-pos wcs-target dx dy base-len dir-vec-x dir-vec-y
                      pos-dx pos-dy cross-prod invert-multiplier proj-dist calc-height 
                      height-str insert-obj old-osmode old-dimzin acad-obj doc ms insertion-pt 
                      attrs attr tag-str rot-angle old-error appdata-roaming source-dwg-path temp-insert)
  (vl-load-com)

  (setq old-osmode (getvar "OSMODE")
        old-dimzin (getvar "DIMZIN")
        old-error *error*)

  (defun *error* (msg)
    (setvar "OSMODE" old-osmode)
    (setvar "DIMZIN" old-dimzin)
    (setq *error* old-error)
    (if (not (member msg '("Function cancelled" "quit / exit abort")))
      (princ (strcat "\nError encountered: " msg))
    )
    (princ "\n--> Environment settings successfully restored.")
    (princ)
  )
  
  (setq scale 0.01)       
  (setq blk-name "level_marker")    

  (setq acad-obj (vlax-get-acad-object)
        doc (vla-get-activedocument acad-obj)
        ms (vla-get-ModelSpace doc)) ; Fixed Casing

  ;;; ============================================================
  ;;; VERIFICATION ENGINE FOR INTERNAL DRAWING BLOCK
  ;;; ============================================================
  (if (not (tblsearch "BLOCK" blk-name))
    (progn
      (princ "\n=======================================================")
      (princ (strcat "\n[STARTING] AppData Bundle Block Import Engine for '" blk-name "'..."))
      (princ "\n=======================================================")

      (setq appdata-roaming (getenv "APPDATA"))
      
      (if appdata-roaming
        (progn
          (setq source-dwg-path 
                 (strcat appdata-roaming 
                         "\\Autodesk\\ApplicationPlugins\\MecidTools.bundle\\Contents\\custom_detail.dwg"))
          
          (princ (strcat "\nConstructed Path: " source-dwg-path))
          
          (if (vl-file-size source-dwg-path)
            (progn
              (princ "\nFile Status: Found! Attempting block extraction layout insertion...")
              
              (setq temp-insert 
                (vl-catch-all-apply
                  '(lambda ()
                     (setq obj (vla-InsertBlock ms (vlax-3d-point '(0.0 0.0 0.0)) source-dwg-path 1.0 1.0 1.0 0.0))
                     (vla-delete obj)
                     T
                   )
                )
              )
              
              (if (and (not (vl-catch-all-error-p temp-insert)) (tblsearch "BLOCK" blk-name))
                (princ (strcat "\n\n>>> SUCCESS! Block definition '" blk-name "' successfully imported! <<<"))
                (progn
                  (alert (strcat "CRITICAL ERROR:\nPath is correct, but block '" blk-name "' was not found inside custom_detail.dwg."))
                  (exit)
                )
              )
            )
            (progn
              (princ "\nFile Status: External drawing not found on disk path. Evaluating internal definitions table...")
              (if (tblsearch "BLOCK" blk-name)
                (princ (strcat "\n--> Fallback Check Passed: Block '" blk-name "' is already present within current workspace. Continuing."))
                (progn
                  (alert (strcat "CRITICAL ERROR:\n'custom_detail.dwg' file was not found at path:\n" source-dwg-path "\n\nAdditionally, block definition '" blk-name "' does not exist internally in this template."))
                  (exit)
                )
              )
            )
          )
        )
        (progn
          (alert "CRITICAL ERROR:\nWindows %APPDATA% environment variable could not be parsed.")
          (exit)
        )
      )
      (princ "\n=======================================================\n")
    )
    (princ (strcat "\n--> Block [" blk-name "] verified locally inside template tables."))
  )
  ;;; ============================================================

  (setvar "DIMZIN" 0)
  
  (setq ref-pt (getpoint "\nClick reference point for zero level (±0.00): "))
  (if ref-pt
    (progn
      (setq dir-pt (getpoint ref-pt "\nPick second point to define the BASELINE/DIRECTION line: "))
      (setq pos-pt (getpoint ref-pt "\nClick on the OPPOSITE (-) side of this line: "))
      
      (if (and dir-pt pos-pt)
        (progn
          (setq wcs-ref (trans ref-pt 1 0)
                wcs-dir (trans dir-pt 1 0)
                wcs-pos (trans pos-pt 1 0))
          
          (setq base-len (distance wcs-ref wcs-dir))
          (if (< base-len 1e-6) (progn (alert "Error: Baseline vectors are coincident.") (exit)))
          
          (setq rot-angle (angle wcs-ref wcs-dir))
          
          (setq dir-vec-x (/ (- (car wcs-dir) (car wcs-ref)) base-len)
                dir-vec-y (/ (- (cadr wcs-dir) (cadr wcs-ref)) base-len))
          
          (setq pos-dx (- (car wcs-pos) (car wcs-ref))
                pos-dy (- (cadr wcs-pos) (cadr wcs-ref)))
          
          (setq cross-prod (- (* pos-dx dir-vec-y) (* pos-dy dir-vec-x)))
          (if (< (abs cross-prod) 1e-6)
            (setq invert-multiplier 1.0)
            (if (> cross-prod 0.0) (setq invert-multiplier -1.0) (setq invert-multiplier 1.0))
          )

          (setq looping T)
          
          (princ "\n--- Rotated Precision Directional Placement Active ---")
          (princ "\n>> Click anywhere in layout space to place block markers.")
          (princ "\n>> TO TERMINATE EXECUTION: Press ENTER or SPACEBAR without selection.")
          
          (while looping
            (setvar "OSMODE" old-osmode)
            (setq target-pt (getpoint "\nPick next layout level vector point: "))
            
            (cond
              ((null target-pt) 
               (princ "\n--> Standard exit sequence requested. Terminating placement routine loop cleanly.")
               (setq looping nil)) 
              (T
                (setq wcs-target (trans target-pt 1 0))
                
                (setq dx (- (car wcs-target) (car wcs-ref))
                      dy (- (cadr wcs-target) (cadr wcs-ref)))
                
                (setq proj-dist (- (* dx dir-vec-y) (* dy dir-vec-x)))
                (setq calc-height (* (* proj-dist invert-multiplier) scale))
                
                (if (< (abs calc-height) 0.005)
                  (setq height-str "%%p0.00")
                  (if (> calc-height 0.0)
                    (setq height-str (strcat "+" (rtos calc-height 2 2)))
                    (setq height-str (rtos calc-height 2 2))
                  )
                )
                
                (setvar "OSMODE" 0)  
                
                (setq insertion-pt (vlax-3d-point wcs-target))
                (setq insert-obj (vla-InsertBlock ms insertion-pt blk-name 1.0 1.0 1.0 rot-angle))
                
                (if (= (vla-get-hasattributes insert-obj) :vlax-true)
                  (progn
                    (setq attrs (vlax-invoke insert-obj 'GetAttributes))
                    (foreach attr attrs
                      (setq tag-str (strcase (vla-get-tagstring attr)))
                      (if (member tag-str '("LEVEL" "HEIGHT" "ELEVATION" "VALUE"))
                        (progn
                          (vla-put-textstring attr height-str)
                          (vla-update attr)
                          (princ (strcat "\nMarker plotted (Rotation: " (rtos (/ (* rot-angle 180.0) pi) 2 1) "°) -> Output: " height-str))
                        )
                      )
                    )
                  )
                )
                (vla-update insert-obj)
              )
            )
          )
        )
      )
    )
  )
  
  (setvar "OSMODE" old-osmode)
  (setvar "DIMZIN" old-dimzin)
  (setq *error* old-error)
  (princ)
)

;;; ============================================================
;;; INITIALIZATION DIAGNOSTIC REPORTS
;;; ============================================================

(princ "\n=======================================================")
(princ "\n--> Command 'GEN-SECTION' Loaded (Escape Protection Configured).")
(princ "\n--> Command 'ADD-LEVELS' Loaded (Enforced English Engine & 2-Decimal Precision).")
(princ "\n====================================open source toolkit====ready====")
(princ)