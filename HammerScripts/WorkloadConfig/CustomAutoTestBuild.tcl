vudestroy
puts "SETTING CONFIGURATION"
global complete
proc wait_to_complete {} {
global complete
set complete [vucomplete]
if {!$complete} { after 5000 wait_to_complete } else { exit }
}
puts "SETTING CONFIGURATION"

dbset db mssqls
diset connection mssqls_odbc_driver "ODBC Driver 13 for SQL Server"
dbset bm TPC-C
diset tpcc mssqls_driver timed
vuset logtotemp 1
vuset unique
buildschema

wait_to_complete
vwait forever