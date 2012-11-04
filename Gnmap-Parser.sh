#!/bin/bash
#####################################################################################
# Gnmap-Parser.sh
#####################################################################################
# Description: Script to parse large amounts of Nmap (.gnmap) exported scan files 
#              into multiple plain-text formats for easy analysis.
#####################################################################################

# Global Variables
parsedir=Gnmap-Parser
portldir=${parsedir}/Port-Lists
portfdir=${parsedir}/Port-Files
portmdir=${parsedir}/Port-Matrix
hostldir=${parsedir}/Host-Lists
ipsorter='sort -n -u -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4'

# Title Function
func_title(){
  # Clear (For Prettyness)
  clear

  # Print Title
  echo '============================================================================'
  echo ' Gnmap-Parser | [Version]: 3.0.0 | [Updated]: 11.04.2012'
  echo '============================================================================'
  echo ' [By]: Mike Wright (@TheMightyShiv) | https://github.com/TheMightyShiv'
  echo '============================================================================'
  echo
}

# Gather Gnmap Files Function
func_gather(){
  echo '[?] Enter The Parent Directory Where Your Gnmap Files Are Located.'
  echo
  read -p '[>] Parent Directory: ' floc
  clear
  func_title
  echo '[*] Gathering .gnmap Files'
  find ${floc} -name *.gnmap -exec cp {} . \; >>/dev/null 2>&1
  func_title
  echo '[*] Gathering Complete.'
  echo
  exit 0
}

# Function To Parse .gnmap Files
func_parse(){
  # Check For .gnmap Files Before Parsing
  fcheck=`ls|grep ".gnmap"|wc -l`
  if [ "${fcheck}" -lt '1' ]
  then
    echo '[Failed]: No Gnmap Files Found (*.gnmap).'
    echo
    echo '--[ Possible Fixes ]--'
    echo
    echo '[1]: Run this script with option (-g).'
    echo '[2]: Place this script in a folder with all (*.gnmap) files.'
    echo
    exit 1
  fi

  # Create Parsing Directories If Non-Existent
  echo '[*] Preparing Directories...'
  for d in ${parsedir} ${portldir} ${portfdir} ${portmdir} ${hostldir}
  do
    if [ ! -d ${d} ]
    then
        mkdir ${d}
    fi
  done

  # Build Alive Hosts Lists
  func_title
  echo '[*] Building Alive Hosts Lists...'
  cat *.gnmap|awk '!/#|Status: Down/'|sed -e 's/Host: //g' -e 's/ (.*//g'|${ipsorter} > ${hostldir}/Alive-Hosts-ICMP.txt
  cat *.gnmap|awk '!/#/'|grep "open/"|sed -e 's/Host: //g' -e 's/ (.*//g'|${ipsorter} > ${hostldir}/Alive-Hosts-Open-Ports.txt

  # Build TCP Ports List
  func_title
  echo '[*] Building TCP Ports List...'
  cat *.gnmap|grep "Ports:"|sed -e 's/^.*Ports: //g' -e 's;/, ;\n;g'|awk '!/udp|filtered/'|cut -d"/" -f 1|sort -n -u > ${portldir}/TCP-Ports-List.txt

  # Build UDP Ports List
  func_title
  echo '[*] Building UDP Ports List...'
  cat *.gnmap|grep "Ports:"|sed -e 's/^.*Ports: //g' -e 's;/, ;\n;g'|awk '!/tcp|filtered/'|cut -d"/" -f 1|sort -n -u > ${portldir}/UDP-Ports-List.txt

  # Build TCP Port Files
  for i in `cat ${portldir}/TCP-Ports-List.txt`
  do
    TCPPORT="$i"
    func_title
    echo '[*] Building TCP Port Files...'
    echo "The Current TCP Port Is: ${TCPPORT}"
    cat *.gnmap|grep " ${TCPPORT}/open/tcp"|sed -e 's/Host: //g' -e 's/ (.*//g'|${ipsorter} > ${portfdir}/Port-${TCPPORT}-TCP.txt
  done

  # Build UDP Port Files
  for i in `cat ${portldir}/UDP-Ports-List.txt`
  do
    UDPPORT="$i"
    func_title
    echo '[*] Building UDP Port Files...'
    echo "The Current UDP Port Is: ${UDPPORT}"
    cat *.gnmap|grep " ${UDPPORT}/open/udp"|sed -e 's/Host: //g' -e 's/ (.*//g'|${ipsorter} > ${portfdir}/Port-${UDPPORT}-UDP.txt
  done

  # Build TCP Services Matrix
  for i in `cat ${portldir}/TCP-Ports-List.txt`
  do
    TCPPORT="$i"
    func_title
    echo '[*] Building TCP Services Matrix...'
    echo "The Current TCP Port Is: ${TCPPORT}"
    cat *.gnmap|grep " ${i}/open/tcp"|sed -e 's/Host: //g' -e 's/ (.*//g' -e "s/^/${i},TCP,/g"|${ipsorter} >> ${portmdir}/TCP-Services-Matrix.txt
  done

  # Build UDP Services Matrix
  for i in `cat ${portldir}/UDP-Ports-List.txt`
  do
    UDPPORT="$i"
    func_title
    echo '[*] Building UDP Services Matrix...'
    echo "The Current UDP Port Is: ${UDPPORT}"
    cat *.gnmap|grep " ${i}/open/udp"|sed -e 's/Host: //g' -e 's/ (.*//g' -e "s/^/${i},UDP,/g"|${ipsorter} >> ${portmdir}/UDP-Services-Matrix.txt
  done

  # Remove Empty Files
  func_title
  echo '[*] Removing Empty Files...'
  find ${parsedir} -size 0 -exec rm {} \;

  # Show Complete Message
  func_title
  echo '[*] Parsing Complete.'
  echo
}

# Start Statement
func_title
case ${1} in
  -g|--gather)
    func_gather
    ;;
  -p|--parse)
    func_parse
    ;;
  *)
    echo ' Usage...: ./Gnmap-Parser.sh [OPTION]'
    echo
    echo ' Options.:'
    echo '           -g|--gather = Gather .gnmap Files'
    echo '           -p|--parse  = Parse .gnmap Files'
    echo
esac
