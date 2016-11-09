#!/usr/bin/python
#   File : check_beacon_presence.py
#   Author: jmleglise
#   Date: 10-Nov-2016
#   Description : Check the presence of a list of beacon (BlueTooth Low Energy V4.0) and update uservariables in Domoticz accordingly. 
#   URL : https://github.com/jmleglise/mylittle-domoticz/edit/master/Presence%20detection%20%28beacon%29/check_beacon_presence.py
#   Version : 1.0
#   Version : 1.1   Log + Mac Adress case insensitive 
#   Version : 1.2   Fix initial AWAY state
#   Version : 1.3   Log + script takes care of hciconfig + Return the RSSI when detected and "AWAY" otherwise
#   Version : 1.4   Fix initial HOME state
#   Version : 1.5   Split loglevel warning / debug
#   Version : 1.6   Add le_handle_connection_complete +  Manage Domoticz login
#
# Feature : 
# Script takes care of Bluetooth Adapter. Switch it UP RUNNING.
# When the MACADRESS of a list of beacons are detected, update DOMOTICZ uservariable.
# Script operates now in 2 mode. Choose for each beacon witch one you want :
#       REPEAT MODE : For beacon in range, update the uservariable every 3 secondes with the RSSI. And "AWAY" otherwise.
#       SWITCH_MODE : For beacon in range, update only 1 time the uservariable with "HOME". And "AWAY" otherwise.
# Send "AWAY" when the beacons are not in range.
# The detection is very fast : around 4 secondes. And the absence is verified every 5 seconds by comparing the hour of the last presence with a time out for each beacon.
#
# References :
# https://www.domoticz.com/wiki/Presence_detection_%28Bluetooth_4.0_Low_energy_Beacon%29
# http://https://www.domoticz.com/forum/viewtopic.php?f=28&t=10640
# https://wiki.tizen.org/wiki/Bluetooth
# https://storage.googleapis.com/google-code-archive-source/v2/code.google.com/pybluez/source-archive.zip  => pybluez\examples\advanced\inquiry-with-rssi.py
#
# Required in Domoticz : An uservariable of type String for each BLE Tag
#
# Usefull command
# sudo /etc/init.d/check_beacon_presence [stop|start|restart|status] 
# 
# Configuration :
# Change your IP and Port here :  
URL_DOMOTICZ = 'https://xxxxxx.xxxxxx.org:xxxx/json.htm?type=command&param=updateuservariable&idx=PARAM_IDX&vname=PARAM_NAME&vtype=2&vvalue=PARAM_CMD'
DOMOTICZ_USER='xxxxxx'
DOMOTICZ_PASS='xxxxxx'

REPEAT_MODE=1
SWITCH_MODE=0

#
# Configure your Beacons in the TAG_DATA table with : [Name,MacAddress,Timeout,0,idx,mode]
# Name : the name of the uservariable used in Domoticz
# macAddress : case insensitive
# Timeout is in secondes the elapsed time  without a detetion for switching the beacon AWAY. Ie :if your beacon emits every 3 to 8 seondes, a timeout of 15 secondes seems good.
# 0 : used by the script (will keep the time of the last broadcast) 
# idx of the uservariable in Domoticz for this beacon
# mode : SWITCH_MODE = One update per status change / REPEAT_MODE = continuous updating the RSSI every 3 secondes

TAG_DATA = [
            ["Tag_White","cc:fd:36:20:32:42",30,0,8,REPEAT_MODE],
            ["Tag_Pink","f1:0d:d6:e6:b0:b2",30,0,6,REPEAT_MODE],
            ["Tag_Orange","Fb:14:78:38:18:5e",30,0,9,REPEAT_MODE],
            ["Tag_Green","ff:ff:60:00:22:ae",30,0,7,REPEAT_MODE]
           ]

           
import logging

# choose between DEBUG (log every information) or warning (change of state) or CRITICAL (only error)
#logLevel=logging.DEBUG
logLevel=logging.CRITICAL
#logLevel=logging.WARNING

logOutFilename='/var/log/check_beacon_presence.log'       # output LOG : File or console (comment this line to console output)
ABSENCE_FREQUENCY=5  # frequency of the test of absence. in seconde. (without detection, switch "AWAY".

################ Nothing to edit under this line #####################################################################################

import os
import subprocess
import sys
import struct
import bluetooth._bluetooth as bluez
import time
import requests
import signal
import threading


LE_META_EVENT = 0x3e
OGF_LE_CTL=0x08
OCF_LE_SET_SCAN_ENABLE=0x000C
EVT_LE_CONN_COMPLETE=0x01
EVT_LE_ADVERTISING_REPORT=0x02

def print_packet(pkt):
    for c in pkt:
        sys.stdout.write("%02x " % struct.unpack("B",c)[0])

def packed_bdaddr_to_string(bdaddr_packed):
    return ':'.join('%02x'%i for i in struct.unpack("<BBBBBB", bdaddr_packed[::-1]))

def hci_disable_le_scan(sock):
    hci_toggle_le_scan(sock, 0x00)

def hci_toggle_le_scan(sock, enable):
    cmd_pkt = struct.pack("<BB", enable, 0x00)
    bluez.hci_send_cmd(sock, OGF_LE_CTL, OCF_LE_SET_SCAN_ENABLE, cmd_pkt)

def handler(signum = None, frame = None):
    time.sleep(1)  #here check if process is done
    sys.exit(0)   
    
for sig in [signal.SIGTERM, signal.SIGINT, signal.SIGHUP, signal.SIGQUIT]:
    signal.signal(sig, handler)

def le_handle_connection_complete(pkt):
    status, handle, role, peer_bdaddr_type = struct.unpack("<BHBB", pkt[0:5])
    device_address = packed_bdaddr_to_string(pkt[5:11])
    interval, latency, supervision_timeout, master_clock_accuracy = struct.unpack("<HHHB", pkt[11:])
    #print "le_handle_connection output"
    #print "status: 0x%02x\nhandle: 0x%04x" % (status, handle)
    #print "role: 0x%02x" % role
    #print "device address: ", device_address

def request_thread(idx,cmd, name):
    try:
        url = URL_DOMOTICZ
        url=url.replace('PARAM_IDX',str(idx))
        url=url.replace('PARAM_CMD',str(cmd))
        url=url.replace('PARAM_NAME',str(name))
        result = requests.get(url,auth=(DOMOTICZ_USER, DOMOTICZ_PASS))
        logging.debug(" %s -> %s" % (threading.current_thread(), result))
    except requests.ConnectionError, e:
        logging.critical(' %s Request Failed %s - %s' % (threading.current_thread(), e, url) )

class CheckAbsenceThread(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
    def run(self):

        time.sleep(ABSENCE_FREQUENCY)    
        for tag in TAG_DATA:
            elapsed_time_absence=time.time()-tag[3]
            if elapsed_time_absence>=tag[2] : # sleep execute after the first Home check.
                logging.warning('Tag %s not seen since %i sec => update absence',tag[0],elapsed_time_absence)
                threadReqAway = threading.Thread(target=request_thread,args=(tag[4],"AWAY",tag[0]))
                threadReqAway.start()

        while True:
            time.sleep(ABSENCE_FREQUENCY)
            for tag in TAG_DATA:
                elapsed_time_absence=time.time()-tag[3]
                if elapsed_time_absence>=tag[2] and elapsed_time_absence<(tag[2]+ABSENCE_FREQUENCY) :  #update when > timeout ant only 1 time , before the next absence check [>15sec <30sec]
                    logging.warning('Tag %s not seen since %i sec => update absence',tag[0],elapsed_time_absence)
                    threadReqAway = threading.Thread(target=request_thread,args=(tag[4],"AWAY",tag[0]))
                    threadReqAway.start()
            
FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
if globals().has_key('logOutFilename') :
    logging.basicConfig(format=FORMAT,filename=logOutFilename,level=logLevel)
else:
    logging.basicConfig(format=FORMAT,level=logLevel)

#Reset Bluetooth interface, hci0
os.system("sudo hciconfig hci0 down")
os.system("sudo hciconfig hci0 up")

#Make sure device is up
interface = subprocess.Popen(["sudo hciconfig"], stdout=subprocess.PIPE, shell=True)
(output, err) = interface.communicate()

if "RUNNING" in output: #Check return of hciconfig to make sure it's up
    logging.debug('Ok hci0 interface Up n running !')
else:
    logging.critical('Error : hci0 interface not Running. Do you have a BLE device connected to hci0 ? Check with hciconfig !')
    sys.exit(1)
    
devId = 0
try:
    sock = bluez.hci_open_dev(devId)
    logging.debug('Connect to bluetooth device %i',devId)
except:
    logging.critical('Unable to connect to bluetooth device...')
    sys.exit(1)

old_filter = sock.getsockopt( bluez.SOL_HCI, bluez.HCI_FILTER, 14)
hci_toggle_le_scan(sock, 0x01)

for tag in TAG_DATA:
    tag[3]=time.time()-tag[2]  # initiate lastseen of every beacon "timeout" sec ago. = Every beacon will be AWAY. And so, beacons here will update 

th=CheckAbsenceThread()
th.daemon=True
th.start()

while True:
    old_filter = sock.getsockopt( bluez.SOL_HCI, bluez.HCI_FILTER, 14)
    flt = bluez.hci_filter_new()
    bluez.hci_filter_all_events(flt)
    bluez.hci_filter_set_ptype(flt, bluez.HCI_EVENT_PKT)
    sock.setsockopt( bluez.SOL_HCI, bluez.HCI_FILTER, flt )
    
    pkt = sock.recv(255)
    ptype, event, plen = struct.unpack("BBB", pkt[:3])

    if event == bluez.EVT_INQUIRY_RESULT_WITH_RSSI:
            i =0
    elif event == bluez.EVT_NUM_COMP_PKTS:
            i =0 
    elif event == bluez.EVT_DISCONN_COMPLETE:
            i =0 
    elif event == LE_META_EVENT:
            subevent, = struct.unpack("B", pkt[3])
            pkt = pkt[4:]
            if subevent == EVT_LE_CONN_COMPLETE:
                le_handle_connection_complete(pkt)
            elif subevent == EVT_LE_ADVERTISING_REPORT:
                num_reports = struct.unpack("B", pkt[0])[0]
                report_pkt_offset = 0
                for i in range(0, num_reports):
                            #logging.debug('UDID: ', print_packet(pkt[report_pkt_offset -22: report_pkt_offset - 6]))
                            #logging.debug('MAJOR: ', print_packet(pkt[report_pkt_offset -6: report_pkt_offset - 4]))
                            #logging.debug('MINOR: ', print_packet(pkt[report_pkt_offset -4: report_pkt_offset - 2]))
                            #logging.debug('MAC address: ', packed_bdaddr_to_string(pkt[report_pkt_offset + 3:report_pkt_offset + 9]))
                            #logging.debug('Unknown:', struct.unpack("b", pkt[report_pkt_offset -2])) # don't know what this byte is.  It's NOT TXPower ?
                            #logging.debug('RSSI: %s', struct.unpack("b", pkt[report_pkt_offset -1])) #  Signal strenght !
                            macAdressSeen=packed_bdaddr_to_string(pkt[report_pkt_offset + 3:report_pkt_offset + 9])
                            for tag in TAG_DATA:
                                if macAdressSeen.lower() == tag[1].lower():  # MAC ADDRESS
                                    logging.debug('Tag %s Detected %s - RSSI %s - DATA unknown %s', tag[0], macAdressSeen, struct.unpack("b", pkt[report_pkt_offset -1]),struct.unpack("b", pkt[report_pkt_offset -2])) #  Signal strenght + unknown (hope it's battery life).                                    
                                    elapsed_time=time.time()-tag[3]  # lastseen
                                    if tag[5]==SWITCH_MODE and elapsed_time>=tag[2] : # Upadate only once : after an absence (>timeout). It's back again
                                        threadReqHome = threading.Thread(target=request_thread,args=(tag[4],"HOME",tag[0]))  # IDX, RSSI, name
                                        threadReqHome.start()
                                        logging.warning('Tag %s seen after an absence of %i sec : update presence',tag[0],elapsed_time)
                                    elif tag[5]==REPEAT_MODE and elapsed_time>3 : # in continuous, Every 2 sec
                                        rssi=''.join(c for c in str(struct.unpack("b", pkt[report_pkt_offset -1])) if c in '-0123456789')
                                        threadReqHome = threading.Thread(target=request_thread,args=(tag[4],rssi,tag[0]))   # IDX, RSSI, name
                                        threadReqHome.start()
                                        logging.debug('Tag %s is still there with an RSSI of %s  : update presence with RSSI',tag[0],rssi)
                                    tag[3]=time.time()   # update lastseen
                                    
    sock.setsockopt( bluez.SOL_HCI, bluez.HCI_FILTER, old_filter )
