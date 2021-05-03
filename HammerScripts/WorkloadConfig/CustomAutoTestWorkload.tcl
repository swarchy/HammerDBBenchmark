#!/bin/tclsh
proc runtimer { seconds } {
set x 0
set timerstop 0
while {!$timerstop} {
incr x
after 1000
  if { ![ expr {$x % 60} ] } {
          set y [ expr $x / 60 ]
          puts "Timer: $y minutes elapsed"
  }
update
if {  [ vucomplete ] || $x eq $seconds } { set timerstop 1 }
    }
return
}
puts "SETTING CONFIGURATION"
dbset db mssqls
diset connection mssqls_odbc_driver "ODBC Driver 13 for SQL Server"
diset tpcc mssqls_driver timed
diset tpcc mssqls_rampup 2
diset tpcc mssqls_duration 5
vuset logtotemp 1
vuset unique 1
loadscript
puts "SEQUENCE STARTED"


vuset vu 4
vuset delay 500
vuset iterations 1
vucreate
vurun
#Runtimer in seconds must exceed rampup + duration
runtimer 600
vudestroy
after 5000
