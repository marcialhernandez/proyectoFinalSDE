# Define options
set val(chan)           Channel/WirelessChannel    ;# channel type
set val(nn)             10                         ;# number of mobilenodes

#Default
#set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model

#Ricean Settings
set val(prop)           Propagation/Ricean   ;# radio-propagation model
set val(RiceanK)        6                          ;# Ricean K factor
set val(RiceanMaxVel)   2.5                        ;# Ricean  Propagation  MaxVelocity Parameter

# Ricean  Propagation: Maximum ID of nodes (Total number of nodes) used to
# compute pairwise table offsets.
set val(RiceMaxNodeID)  [expr {$val(nn)-1}]        ;
set val(RiceDataFile)   "rice_table.txt"             ;# Ricean Propagation Data File

set val(netif)          Phy/WirelessPhy            ;# network interface type
set fulltcp_ 1
set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         100                         ;# max packet in ifq


set val(rp)             OLSR               ;# routing protocol OLSR
set val(packetSize__)             256               ;
set val(window__)             32               ;
set val(movilidad)       "movilidad.txt"             ;# archivo de movilidad
#set val(trafico)         "tcp-10-test"  ;# archivo de tráfico de datos
set val(trafico)         "trafico.txt"
set val(x)              500                        ;# X dimension of topography
set val(y)              500                        ;# Y dimension of topography
set val(stop)           150                        ;# time of simulation end
set val(eMin)            122.505                    ;#Energía mínima nodos (counter)
set val(eMax)            326.77                     ;#Energía máxima nodos (counter)
set val(energyModel)     EnergyModel                ;# Modelo de energía (*), energía = potencia eléctrica x tiempo,J=W*S
set val(initialEnergy)   1000                       ;# Energía inicial en joules para el nodo principal (adapter)
set val(txPower)         20.0                        ;# Potencia de transmisión en watts
set val(rxPower)         1.0                        ;# Potencia de recepción en watts
set val(idlePower)       0.5                        ;# Watts
set val(sleepPower)      0.001                      ;# Watts
set val(transitionPower) 0.2                        ;# Watts
set val(transitionTime)  0.005                      ;# Segundos

# Rango de transmisión 25[m]
$val(ant) set X_ 0
$val(ant) set Y_ 0
$val(ant) set Z_ 1.5
$val(ant) set Gt_ 1
$val(ant) set Gr_ 1

set ns_          [new Simulator]
set tracefd       [open OlsrRicean.tr w]
set windowVsTime2 [open win.tr w]
set namtrace      [open OlsrRicean.nam w]

$ns_ trace-all $tracefd
$ns_ namtrace-all-wireless $namtrace $val(x) $val(y)

# set up topography object
set topo       [new Topography]

$topo load_flatgrid $val(x) $val(y)

set namfile [open outOlsrRicean.nam w]

# (2) Tell NS to write NAM network events to this trace file

$ns_ namtrace-all $namfile
set god_ [create-god $val(nn)]
#create-god $val(nn)

# Energía inicial aleatoria
set n [new RandomVariable/Uniform]
$n set min_ $val(eMin);
$n set max_ $val(eMax);

# configure the nodes
        $ns_ node-config -adhocRouting $val(rp) \
             -Agent/DSDV set fulltcp_ 1 \
             -llType $val(ll) \
             -macType $val(mac) \
             -ifqType $val(ifq) \
             -ifqLen $val(ifqlen) \
             -antType $val(ant) \
             -propType $val(prop) \
             -phyType $val(netif) \
             -channelType $val(chan) \
             -topoInstance $topo \
             -energyModel $val(energyModel) \
             -initialEnergy [$n value] \
             -txPower $val(txPower) \
             -rxPower $val(rxPower) \
             -idlePower $val(idlePower) \
             -sleepPower $val(sleepPower) \
             -transitionPower $val(transitionPower) \
             -transitionTime $val(transitionTime) \
             -agentTrace ON \
             -routerTrace ON \
             -macTrace ON \
             -movementTrace ON

# Set propagation settings
set prop_inst [$ns_ set propInstance_]
$prop_inst MaxVelocity  $val(RiceanMaxVel);
$prop_inst RiceanK      $val(RiceanK);
$prop_inst LoadRiceFile  $val(RiceDataFile);
$prop_inst RiceMaxNodeID $val(RiceMaxNodeID);

for {set i 0} {$i < $val(nn) } { incr i } {
    set node_($i) [$ns_ node]
    $node_($i) random-motion 0;
    #$ns_ initial_node_pos $node_($i) 5
    #$ns at [ expr 15+round(rand()*60) ] "$node_($i) setdest [ expr 10+round(rand()*480) ] [ expr 10+round(rand()*380) ] [ expr 2+round(rand()*15) ]"
    
}

#Redefinicion de agentes a FullTcp
set TCP [new Agent/TCP/FullTcp]

set TCPSink [new Agent/TCP/FullTcp]

$TCP set fid_ 0
$TCPSink set fid_ 0
$TCPSink listen

#Establecimiento del largo de la ventana deslizante
$TCP set window_ window__;

# Carga del Modelo de movilidad
source $val(movilidad)

#Carga del Modelo de trafico
source $val(trafico)

$TCP set fid_ 0
$TCPSink set fid_ 0
$TCPSink listen
$TCP set window_ window__;

# Printing the window size
proc plotWindow {tcpSource file} {
global ns_
set time 0.01
set now [$ns_ now]
set cwnd [$tcpSource set cwnd_]
puts $file "$now $cwnd"
$ns_ at [expr $now+$time] "plotWindow $tcpSource $file" }
$ns_ at 10.1 "plotWindow $tcp_(0) $windowVsTime2"


# Telling nodes when the simulation ends
for {set i 0} {$i < $val(nn) } { incr i } {
     $ns_ at $val(stop) "$node_($i) reset";
}

# ending nam and the simulation
$ns_ at $val(stop) "$ns_ nam-end-wireless $val(stop)"
$ns_ at $val(stop) "stop"
$ns_ at 150.01 "puts \"end simulation\" ; $ns_ halt"
proc stop {} {
    global ns_ tracefd namtrace
    $ns_ flush-trace
    close $tracefd
    #exec nam outOlsrRicean.nam &        ;   
    # OPTIONAL: run NAM from inside the NS simulation  
    #exec xgraph -M -bg white -fg blue -t "Time VS Bandwidth" -x "Time" -y "Bandwidth"   -geometry 700*800 &
    #exec xgraph win.tr -M -bg white -fg blue -t "Time VS Throughput" -x "Time" -y "Throughput" -geometry 700*800  & 
        
    #exec nam -r 100.000000us OLSR_final.nam &  
    exit 0
}

$ns_ run