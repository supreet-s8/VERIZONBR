#!/usr/bin/env python
#
# Dumps the PS Oldgen memory usage of all rubix nodes

RUBIX_IPS = [
    '192.168.168.189:8089',
    '192.168.168.190:8089',
]

INPUT_CMDS = """
domain java.lang
bean java.lang:name=PS\ Old\ Gen,type=MemoryPool
get Usage
"""

from subprocess import Popen, PIPE
from datetime import datetime
import os
import sys

ROOT_DIR = os.path.dirname(__file__)

def main(output_file):
    start_dt = datetime.now()

    with open(output_file, 'a') as file:
        file.write('-----------------------------------------------------------------------------------------------\n')
        file.write("Mem Usage Start for Timestamp: " + start_dt.strftime("%Y-%m-%d %H:%M") + '\n')

        for ip in RUBIX_IPS:
            only_ip = ip.split(":")[0]
            file.write("=== Fetch Start from %s ===\n" % only_ip)
            file.write("IP: %s\n" % only_ip)
            jmx = Popen("java -jar %s/jmxterm-1.0-alpha-4-uber.jar -n -l %s" % (ROOT_DIR, ip), shell=True, stdout=PIPE, stdin=PIPE)
            file.write(jmx.communicate(INPUT_CMDS)[0])
            file.write('=== Fetch Complete from %s ===\n\n' % only_ip)

        file.write("Mem Usage Complete for Timestamp: " + start_dt.strftime("%Y-%m-%d %H:%M") + '\n')
        file.write('-----------------------------------------------------------------------------------------------\n')

if __name__ == '__main__':
    if len(sys.argv) == 2:
        output_file = sys.argv[1]
    else:
        output_file = os.path.join(ROOT_DIR, 'RubixMemData.txt')

    main(output_file)
