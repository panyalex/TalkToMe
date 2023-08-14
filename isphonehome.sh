#!/bin/bash

#sendet arp anfrage an die handy IP, ist das handy im lokalen Netzwerk verbunden wird ishome zurückgegeben

  arping -c 1 192.168.178.137 | grep -E "1 response|1 packets received" > /dev/null

    if [ $? == 0 ]; then
      echo "ishome" 
    else
      echo "nothome"
  fi
