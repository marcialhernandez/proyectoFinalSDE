BEGIN {
seqno = -1;
droppedPackets = 0;
receivedPackets = 0;
count = 0;
sentpackets = 0;
ctrlpac = 0;
pdf = 0;
protocolo="OLSR"
tamPaquete=256
}
{
if($4 == "AGT"&&$1=="s"&&seqno<$6) {
seqno = $6;
sentpackets++;
}
else if(($4 == "AGT") && ($1 == "r")) {
receivedPackets++;
}
else if ($1=="d"&&($7=="tcp"||$7=="cbr") && $8 > tamPaquete){
droppedPackets++;
}
else if($4=="RTR"&&($1=="s" || $1 == "f") && ($7 == "DSR" || $7 == protocolo || $7 == "message")) {
ctrlpac++;
}
#end-to-end delay calculation
if($4 == "AGT" && $1 == "s") {
start_time[$6] = $2;
}
else if(($7 == "tcp"|| $7== "cbr")&& ($1 == "r")) {
end_time[$6] = $2;
}
else if($1 == "d" && ($7 == "tcp" || $7 == "cbr")) {
end_time[$6] = -1;
}
}
END {
for(i=0; i<=sentpackets; i++) {
if(end_time[i] > 0) {
delay[i] = end_time[i] - start_time[i];
count++;
}
else{
delay[i] = -1;
}
}
for(i=0; i<=seqno; i++) {
if(delay[i] > 0) {
n_to_n_delay = n_to_n_delay + delay[i];
} }
n_to_n_delay = n_to_n_delay/count;
print "GeneratedPackets = " seqno+1;
print "SentPackets = " sentpackets; print "ReceivedPackets = " receivedPackets;
pdf = receivedPackets/(sentpackets)*100
print "Packet Delivery Ratio = " pdf " %";
print"TotalDroppedPackets = " droppedPackets;
print "Average End-to-End Delay = " n_to_n_delay*1000 "ms" ;
print "Control Packets = "ctrlpac;
print "Average Routing Load = "ctrlpac/300;
}