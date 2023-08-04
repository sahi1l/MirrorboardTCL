
proc log {x} {
    #return
    set LOGFILE [open "LOG" "a"]
    puts $LOGFILE $x
    close $LOGFILE
}

