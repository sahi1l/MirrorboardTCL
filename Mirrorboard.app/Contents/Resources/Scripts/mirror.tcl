destroy .mirror
set mirrorW [expr 2*$cX]
set mirrorH [expr $numwidth+$cY]
toplevel .mirror -width [expr $scale*$mirrorW]  -height [expr $scale*$mirrorH]
wm title .mirror "*MIRROR*"

#create a fake window to check for a second monitor (to the right only!)
proc GetDisplays {{which 0}} {
    #NOTE: This assumes the second display is on the right
    set top .#dualMonitorCheck# 
    if {![winfo exists $top]} { toplevel $top; wm withdraw $top }
    #sw is the total width of this screen (more or less?) 
    set this_screen [winfo screenwidth $top]
    #mw is the total width of both screens
    set all_screens [lindex [wm maxsize .] 0]
    if {[expr ($this_screen + 10) < $all_screens]} {#two screens
        set screens [list $this_screen [expr $all_screens-$this_screen]]
    } else {
        set screens [list $this_screen 0]
    }
    
    switch $which {
        0 {return $screens}
        1 - main {return [lindex $screens 0]}
        2 - mirror {return [lindex $screens 1]}
    }
}

if [GetDisplays mirror] {
    wm geometry .mirror +[expr [GetDisplays main]+10]+0;  #place .mirror on the other screen
} else {
    wm geometry .mirror +[expr 2*$cX]+0; #place .mirror on main screen (why 2*cX?)
    wm iconify .mirror;
}
proc ShowMirror {} {wm deiconify .mirror}
proc ResizeMirror {} {
    global mirrorW mirrorH scale
    if [winfo exists .mirror] {
        set W [winfo width .]
        set H [winfo height .]
        wm geometry .mirror [expr round($W*$scale)]x[expr round($H*$scale)]
    }
}
