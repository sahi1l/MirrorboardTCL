namespace eval File {
    proc init {} {
        variable id [clock seconds]; #identifies the session
        variable tmpdir "/tmp/hill-whiteboard"
        if {![file exists $tmpdir]} {
            file mkdir $tmpdir
        }
        variable autosavefile [file join $tmpdir $id]
    }
    proc AddExtension {fname ext} {
        if ![llength $fname] {return}
        if {[file extension $fname]==""} {set fname $fname.$ext}
        return $fname
    }
    proc Save {{autosave 1} {dst ""}} {
        #Saves to a file, possibly a backup file
        #Not used for PDFs
        if $autosave {
            set fname $File::autosavefile
        } else {
            if [llength $dst] {
                set fname [tk_getSaveFile -initialdir $dst]
            } else {
                set fname [tk_getSaveFile]
            }
        }
        if ![llength $fname] {return}
        set fname [AddExtension $fname "txt"]
    set F [open $fname "w"]
        puts $F [array get Elements::elements]
        close $F
    }
    #IDEA: Need a file to load one page
    proc ClearAll {} {
        global Npages
        Elements::ClearAll
        for {set n 1} {$n<=$Npages} {incr n} {
            Drawing::Clear $n
        }
        for {set n 3} {$n<=$Npages} {incr n} {
            foreach w [Drawing::WhereToDraw] {
                destroy $w.pg$n $w.n$n
            }
        }
        set Npages 2
        ShowPages 1
        #select page 1 I think
    }
    proc ListOfPageNumbers {fname} {
        set allPageNumbers {};
        set F [open $fname "r"]
        set slurp [read $F]
        close $F
        #Make sure there are enough pages
        foreach {key val} $slurp {
            set pg [GetPage $key]
            if {[lsearch -exact $allPageNumbers $pg]==-1} {
                lappend allPageNumbers $pg
            }
        }
        return [lsort -integer $allPageNumbers]
    }
    proc PromptLoad {} {
        set fname [tk_getOpenFile]
        if ![llength $fname] {return}
        set allPageNumbers [ListOfPageNumbers $fname]
        set backup [array get Elements::elements]
        destroy .choosepage
        toplevel .choosepage
        wm title .choosepage "Choose"
        pack  [label .choosepage.top -text "Choose a page to insert"] -side top
        pack [button .choosepage.pRevert -text "Revert" -command [list File::SlurpToPage "$backup" $::currentpage]]
        foreach pg $allPageNumbers {
            pack [button .choosepage.p$pg -text "Page $pg" -command "File::Load $fname $pg"]
        }
        pack [button .choosepage.cancel -text "Done" -command "destroy .choosepage"]
        bind .choosepage <FocusOut> {destroy .choosepage}
    }
    proc SlurpToPage {slurp pages} {
        global Npages currentpage
        if ![llength $pages] { #load the entire file
            ClearAll
            array set ::Elements::elements $slurp
            set keys [::Elements::SortedKeys]
            set lastpage [lindex [split [lindex $keys end] "l"] 0]
            while {($Npages<$lastpage)} {
                NewPage
            }
            foreach key $keys {
                set page [lindex [split $key $::tagpfx] 0]
                ::Drawing::Redraw $::Elements::elements($key) $page
            }
            set ::currentpage [expr $Npages-1]
        } else { #single page
            set result {}
            ClearCanvas $currentpage noprompt
            foreach {key val} [lsort -stride 2 -command Elements::sortcommand $slurp] {
                lassign [split $key $::tagpfx] pg idx
                set idx $::tagpfx$idx
                if {$pg==$pages} {
                    set ::Elements::elements($currentpage$idx) $val
                    ::Drawing::Redraw $val $currentpage
                }
            }
        }
    }
    proc Load {{fname ""} {pages ""}} {
        #pages is a list of pages to load
        #if "", then load them all
        global Npages currentpage
        if ![llength $fname] {
            set fname [tk_getOpenFile]
            if ![llength $fname] {return}
        }
        set F [open $fname "r"]
        set slurp [read $F]
        close $F
        SlurpToPage $slurp $pages
    }

    proc Redraw {pg} {
        set keys [::Elements::SortedKeys]
        foreach key $keys {
            set page [lindex [split $key $::tagpfx] 0]
            if {$page == $pg} {
                ::Drawing::Redraw $::Elements::elements($key) $page
            }
        }
    }
    proc Autosave {} {
        bind .palette.autosave <1> {}
        Save
        .palette.autosave config -text "Autosaved [clock format [clock seconds] -format %H:%M]"
        after 5000 {.palette.autosave config -text ""}
        after 60000 {File::Autosave}; #save every minute
    }
    proc SavePS {pg} {
        variable tmpdir
        file mkdir $tmpdir ; #if it doesn't exist already
        set tmpfname $tmpdir/hill-MB$pg.ps
        .c.pg$pg postscript -file $tmpfname
        return $tmpfname
    }
    
    proc MakePDF {fname dir} {
        global Npages
        set ps {}; #filenames now
        set pdf {}
        for {set pg 1} {$pg<=$Npages} {incr pg} {
            if {[Elements::Last $pg]>=0} { #page is not empty
                lappend ps [SavePS $pg]
                #set tmpfname $dir/hill-WB$pg.ps
                #lappend ps $tmpfname
                #.c.pg$pg postscript -file $tmpfname;
            }
        }
        exec gs -o $fname -sDEVICE=pdfwrite -dPDFSettings=/Screen {*}$ps
        catch { exec /usr/bin/open -a Preview $fname }
    }
    proc SavePDF {} {
        variable tmpdir
        set fname [AddExtension [tk_getSaveFile] "pdf"]
        if [llength $fname] {
            set dir $tmpdir
            file mkdir $dir
            MakePDF $fname $dir
            .palette.printed config -text "PRINTED"
        }
    }
    proc SaveToClipboard {} {
        global Npages
        set pg $::currentpage
        .c.pg$pg postscript -file $tmpfname
        #Now if I can save this postscript file to the clipboard, I'm golden!
    }
    

}
