namespace eval Elements {
    namespace export NewPage Clear Debug Add Last Append Undo Redo ClearRedo 
variable elements
array set elements {}; #keys like 1l0, 1-based
variable texts
array set texts {}; #keys like 1l0, 1-based
variable redo
array set redo {}; #keys like 1, 1-based, which are the pages
array unset elements
array unset redo
#FIX: make texts an array with page index, and contents are lists
#Or even better, a 2D array elements(1,l0) or even elements(1l0) without the comma
proc AddText {page tag text} {
    variable texts
    #    set texts($page$tag) $text ; #by avoiding this, it remembers text from before. which is ok
    return "Elements::texts($page$tag)"
}
proc UpdateText {page tag} {
    variable texts
    variable elements
   
    set text $texts($page$tag)
    if [string match [lindex elements($page$tag) 0] "Text"] {
        set elements($page$tag) [lreplace elements($page$tag) 4 4 $text]
    }
    
}
proc sortcommand {a b} {
    set a [split $a $::tagpfx]
    set b [split $b $::tagpfx]
    if {[lindex $a 0]<[lindex $b 0]} {return -1}
    if {[lindex $a 0]>[lindex $b 0]} {return 1}
    if {[lindex $a 1]<[lindex $b 1]} {return -1}
    if {[lindex $a 1]>[lindex $b 1]} {return 1}
    return 0
}
proc SortedKeys {} {
    return [lsort -command Elements::sortcommand [array names Elements::elements]]
}
#FIX?: Store CurrentPage here? Maybe put Activate in here too?

proc NewPage {{page 0}} {
    #FIX: Double-check page to make sure there are enough?
    variable redo
    set redo($page) {}
}

proc ClearAll {} {
    array unset Elements::elements *
    array unset Elements::redo *
    array unset Elements::texts *
}

proc Clear {page} {
    variable elements
    variable redo
    array unset elements "$page$::tagpfx"
    array unset texts "$page$::tagpfx"
    set redo($page) {}
}


proc Add {page element} {
    variable elements
    set idx [expr 1+[Last $page]]
    set elements($page[Tag $idx]) $element
    ClearRedo $page
    return $idx
}
proc Last {page} {
    #returns the element with the largest index number
    variable elements
    set keys [array names elements -glob $page$::tagpfx*]
    if {! [llength $keys]} {return -1}
    set indices {}
    foreach key $keys {
        lappend indices [regsub "^\[0-9\]*$::tagpfx" $key ""]
    }
    return [lindex [lsort -integer -increasing $indices] end]
}
proc GetCoords {page index} {
    variable elements
    set coindex 2; #the index in the command that has the coordinates
    set idx $page[Tag $index]
    return [lindex $elements($idx) $coindex]
}
proc Append {page x y} {#if the last element was a line, then add {x y} to its first parameter
    variable elements
    set coindex 2; #the index in the command that has the coordinates
    set idx $page[Tag [Last $page]]
    if {[lindex $elements($idx) 0]!="Line"} {return ""}; #not a line!
    set coords [lindex $elements($idx) $coindex]
    set lx [lindex $coords end-1]
    set ly [lindex $coords end]
    if {$y-$ly==55} {
        #this is a spurious point , skip it (55 is a magic number)
        log "kludge: $lx,$ly-$x,$y"
        return $coords
    }
    lappend coords $x $y
    set elements($idx) [lreplace $elements($idx) $coindex $coindex $coords]
       
    return $coords
}
proc Undo {page} {
    variable elements
    variable redo
    if {[Last $page]<0} {return}; #there's nothing to undo
    set tag [Tag [Last $page]]
    set idx $page$tag
    set todelete $idx
    if [llength $todelete] { #this might need to be a catch on the previous line?
        set tomove $elements($idx)
        lappend redo($page) $tomove
        array unset elements $idx
        return $tag; #$todelete
    } else {
        return
    }
}
proc Redo {page} {
    #move first element of redo to end of elements
    variable elements
    variable redo
    if {[llength $redo($page)]>0} {
        set tomove [lindex $redo($page) end]
        set elements($page[Tag [expr [Last $page]+1]]) $tomove
        set redo($page) [lreplace $redo($page) end end]
        return $tomove
        #run the command?
    } else {
        return ""
    }
}
    
proc ClearRedo {page} {
    variable redo
    set redo($page) {}
}

proc Debug {} {
    variable elements
    puts "Elements: [array names elements]"
    puts "Redo: [array get redo]"
}

proc SanityCheck {page {debug 0}} {
    set flag 0
    foreach el [array names elements $page$::tagpfx*] {
        #does the second element match?
        if ![string match [lindex elements($el) 1] $el] {
            incr flag
            if {$debug} {
                puts $el,elements($el)
            }
        }
        #does the element exist on the canvas?
        if ![llength .c.pg$page find withtag $el] {
            incr flag
            if ($debug) {
                puts "$el is not on the canvas"
            }
        }
    }
    return $flag
}


}


