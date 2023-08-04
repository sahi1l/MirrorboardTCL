package require Tk
wm title . "MIRRORBOARD"
wm geometry . +20+0
set ::tcl_interactive 1
cd [file dirname [info script]]
source main.tcl
#source console.tcl
#bind . <Control-c> {::tk::console show}

