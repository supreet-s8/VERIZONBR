#!/usr/bin/env python
####################################################
#
# Filename: PrefetchAnalyzer.py
#
# Purpose:
#       Analyze Rubix v4 logs to find the times taken
#       to prefetch each day's data
#
# Author: sandeep.nanda@guavus.com
#
# Usage Examples:
#    ./PrefetchAnalyzer.py -f /data/instances/BR/0/bin/rubix.log     (Will analyze today's log file)
#    ./PrefetchAnalyzer.py -f /data/instances/BR/0/bin/rubix.2013-08-23.log     (Will analyze 2013-08-23 logs)
#    ./PrefetchAnalyzer.py -d 1 -f /data/instances/BR/0/bin/rubix.2013-08-23.log     (Will analyze 2013-08-23 and 2013-08-22 logs)
#    ./PrefetchAnalyzer.py -d 1 -f /data/instances/BR/0/bin/rubix.log     (Will analyze rubix.log and yesterday's logs)
#
# Modification History:
#     2013-Aug-31 - sandeep.nanda
#                   Initial Creation
#     2013-Sep-05 - sandeep.nanda
#                   Display Memory Usage if output of mem usage is provided
#     2013-Sep-08 - sandeep.nanda
#                   Show sum of memory on all nodes, Remove the need of COORDINATOR_IP
#     2013-Sep-18 - sandeep.nanda
#                   Add support for zipped log files
#     2013-Nov-13 - sandeep.nanda
#                   Add support for numbered log files
#
####################################################
import re
import sys
import os
import glob
import subprocess
from datetime import datetime, timedelta
from optparse import OptionParser

bold = "\033[1m"
reset = "\033[0;0m"

TMP_FILE = "out.txt"
DEFAULT_OUTPUT_FILE = "PrefetchAnalysis.txt"
INTERESTING_PATTERN = "Consuming combiner Task|Finished Combiner Task| PS |exception|Finished PreLoading cache in"
MEM_DIVISION_FACTORS = {
    "T" : 1099511627776,
    "G" : 1073741824,
    "M" : 1048576,
    "K" : 1024,
    "B" : 1,
}

def main():
    prefetch_start = prefetch_end = None
    preload_time = 0
    today_dt = datetime.now()
    today_str = today_dt.strftime("%Y-%m-%d")
    is_numbered = False

    #import pdb; pdb.set_trace()
    # If there is a date in the logfile, extract it
    if "-" in LOG_FILE:
        filename_parts = LOG_FILE.split(".")
        if LOG_FILE.endswith(".gz"):
            logfile_ext = ".".join(filename_parts[-2:])
            if len(filename_parts) == 5:
                # rubix.YYYY-MM-DD.0.log.gz
                logdate_str = filename_parts[-4]
                logfile_basename = ".".join(filename_parts[:-4])
                is_numbered = True
            else:
                # rubix.YYYY-MM-DD.log.gz
                logdate_str = filename_parts[-3]
                logfile_basename = ".".join(filename_parts[:-3])
        else:
            logfile_ext = filename_parts[-1]
            logdate_str = filename_parts[-2]
            logfile_basename = ".".join(filename_parts[:-2])

        logfile_ext = "." + logfile_ext     # Need a dot in the extension
        logdate_dt = datetime.strptime(logdate_str, "%Y-%m-%d")
    else:
        # Else consider the logs to be generated today. Assume that these logs will never be zipped
        logdate_str = today_str
        logdate_dt = today_dt
        logfile_basename, logfile_ext = os.path.splitext(LOG_FILE)

    if not PREV_DAYS:
        # If this is a numbered file, read all the related numbered files 
        if is_numbered:
            numbered_pattern = logfile_basename + "." + logdate_str + ".*" + logfile_ext
            readLogFiles(numbered_pattern, logdate_str)
        else:
            readLogFiles(LOG_FILE, logdate_str)
    else:
        if os.path.exists(TMP_FILE):
            os.remove(TMP_FILE)

        # Grep the logs from all the previous days log file
        for i in range(PREV_DAYS, 0, -1):
            backday_dt = logdate_dt - timedelta(days=i)
            backday_str = backday_dt.strftime("%Y-%m-%d")
            backday_filename = logfile_basename + "." + backday_str + logfile_ext
            #print("Reading %s" % backday_str)

            # Check if a zipped version of the previous log file is present
            if not os.path.exists(backday_filename):
                backday_filename += ".gz"
            
            if os.path.exists(backday_filename):
                readLogFiles(backday_filename, backday_str)
            else:
                # Try to read numbered zip files of the previous day (if present)
                numbered_pattern = logfile_basename + "." + backday_str + ".*" + logfile_ext + ".gz"
                readLogFiles(numbered_pattern, backday_str)

        if is_numbered:
            numbered_pattern = logfile_basename + "." + logdate_str + ".*" + logfile_ext
            readLogFiles(numbered_pattern, logdate_str)
        else:
            readLogFiles(LOG_FILE, logdate_str)

    with open(TMP_FILE) as tmp_fh:
        prefetchDict = {}
        pTimeSecs = 0.0
        excepStr = ""
        for line in tmp_fh:
            # Note down Insta Time
            m = re.search('Time taken to .*? from PS ((?P<MINS>\d+) minutes )?((?P<SECS>\d+) seconds )?((?P<MSECS>\d+) milliseconds)?', line)
            if m is not None:
                pSec = m.group("SECS")
                pMSec = m.group("MSECS")
                pMin = m.group("MINS")

                pTimeSecs += float(pMin)*60 if pMin else 0
                pTimeSecs += float(pSec) if pSec else 0
                pTimeSecs += float(pMSec)/1000 if pMSec else 0
                continue    # Save time

            m = re.search('exception', line, flags=re.I)
            if m is not None:
                excepStr = excepStr + line    
                continue    # Save time

            # Note down combined prefetching Start Time
            m = re.search('(?P<PF_STIME>[^\[]+)\s+\[.*Consuming combiner Task.*?startTime=(?P<BIN_STIME>\d+), endTime=(?P<BIN_ETIME>\d+),.*binClass=(?P<BIN_CLASS>\w+),', line)
            if m is not None:
                bin_stime = float(m.group("BIN_STIME"))
                bin_etime = float(m.group("BIN_ETIME"))
                bin_class = m.group("BIN_CLASS")
                bin = (bin_stime, bin_etime)

                init_bin(prefetchDict, bin, bin_class)     # If required, Set default parameters in dict
                binclass_dict = prefetchDict[bin]["bin_classes"][bin_class]
                if not binclass_dict["stime"]:
                    # If prefetching has already started for another bin class, don't update stime
                    binclass_dict["stime"] = m.group("PF_STIME").split(".")[0]  # Don't need milliseconds, so strip anything after dot
                    excepStr = ""
                binclass_dict["etime"] = None   # To mark the prefetching as "In Progress"
                continue    # Save time

            # Note down Combined prefetching end time
            m = re.search('(?P<PF_ETIME>[^\[]+)\s+\[.*?Finished Combiner Task fetch.*?startTime=(?P<BIN_STIME>\d+), endTime=(?P<BIN_ETIME>\d+),.*binClass=(?P<BIN_CLASS>\w+),', line)
            if m is not None:
                bin_stime = float(m.group("BIN_STIME"))
                bin_etime = float(m.group("BIN_ETIME"))
                bin_class = m.group("BIN_CLASS")
                bin = (bin_stime, bin_etime)

                init_bin(prefetchDict, bin, bin_class)     # Set default parameters in dict

                binclass_dict = prefetchDict[bin]["bin_classes"][bin_class]
                binclass_dict["etime"] = m.group("PF_ETIME").split(".")[0]  # Don't need milliseconds
                binclass_dict["ptime"] += pTimeSecs
                if excepStr != "":
                    prefetchDict[bin]["exceptions"].append(excepStr)
                    excepStr = ""
                pTimeSecs = 0.0
                continue    # Save time

            m = re.search(r"Finished PreLoading cache in (?P<PRELOAD_TIME>.+) seconds", line)
            if m is not None:
                preload_time = float(m.group("PRELOAD_TIME")) 
                continue

    if not prefetchDict:
        print >>sys.stderr, "Prefetching data not found in log file..."
        sys.exit(1)
    
    # Start writing the output
    with open(OUTPUT_FILE, "w") as out_fh:
        print_header(out_fh)

        excepFlag = False
        exceptions = []
        sorted_bins = sorted(prefetchDict.keys(), reverse=True)
        for bin in sorted_bins:
            try:
                bin_stime, bin_etime = bin
                bin_stime_str = datetime.fromtimestamp(bin_stime).strftime("%Y-%m-%d %H:%M:%S")
                bin_etime_str = datetime.fromtimestamp(bin_etime).strftime("%Y-%m-%d %H:%M:%S")
                bin_str = "%s to %s" % (bin_stime_str, bin_etime_str)

                # Get parameters for prefetched bin
                bin_dict = prefetchDict[bin]
                stime_str = ""
                etime_str = ""
                stime_dt = None
                etime_dt = None
                ptime_secs = 0
                bin_prefetch_time_secs = 0
                print_dict = init_print_dict()
                bc_rubix_time = []
                for bin_class_name, bin_class in bin_dict["bin_classes"].iteritems():
                    # Add pstime for all binclass
                    ptime_secs += int(bin_class["ptime"])
                    stime_dt_bc = etime_dt_bc = None

                    # Take smallest stime
                    stime_str_bc = bin_class["stime"]
                    if stime_str_bc:
                        stime_dt_bc = datetime.strptime(stime_str_bc, "%Y-%m-%d %H:%M:%S")
                        if not stime_dt:
                            # If stime is not set
                            stime_dt = stime_dt_bc
                            stime_str = stime_str_bc
                        elif stime_dt_bc < stime_dt:
                            # Take the first stime_dt
                            stime_dt = stime_dt_bc
                            stime_str = stime_str_bc

                    # Take largest etime
                    etime_str_bc =  bin_class["etime"]
                    if etime_str_bc:
                        etime_dt_bc = datetime.strptime(etime_str_bc, "%Y-%m-%d %H:%M:%S")
                        if not etime_dt:
                            # If etime is not set
                            etime_dt = etime_dt_bc
                            etime_str = etime_str_bc
                        elif etime_dt_bc > etime_dt:
                            # Take the first stime_dt
                            etime_dt = etime_dt_bc
                            etime_str = etime_str_bc

                    if not stime_dt_bc or not etime_str_bc:
                        continue
                    bc_prefetch_time_secs = td_totalseconds(etime_dt_bc - stime_dt_bc)
                    bin_prefetch_time_secs += bc_prefetch_time_secs
                    bc_rubix_time.append("%s:%s" % (bin_class_name, bc_prefetch_time_secs))

                # If there are exceptions in this bin
                if not bin_dict["exceptions"]:
                    excepStatus = 'NO'
                else:
                    excepStatus = 'YES'
                    excepFlag = True
                    for exp in bin_dict["exceptions"]:
                        exceptions.append((bin_str, exp))

                # Note down combined prefetching start time
                if not prefetch_start or (stime_dt and stime_dt < prefetch_start):
                    # Keep only first occurence of start time
                    prefetch_start = stime_dt

                if not prefetch_end or (etime_dt and etime_dt > prefetch_end):
                    prefetch_end = etime_dt     # Will keep the last occurence of end time

                # If prefetching for this bin has not yet completed
                if not etime_str:
                    out_fh.write("%-45s%-25s%-15s%-22s%-22s%-15.2f%s\n" % (bin_str, " In Progress", "NA", stime_str, "NA", 0.0, excepStatus))
                    print "%-53s%-25s%-15s%-22s%-22s%-15.2f%s" % (bold+bin_str+reset, "  In Progress", "NA", stime_str, "NA", 0.0, excepStatus)
                    continue

                # Handling where "Consuming combiner task" log is missed
                if not stime_str:
                    out_fh.write("%-45s%-25s%-15s%-22s%-22s%-15.2f%s\n" % (bin_str, " INVALID", "NA", "NA", etime_str, 0.0, excepStatus))
                    print "%-53s%-25s%-15s%-22s%-22s%-15.2f%s" % (bold+bin_str+reset, "  INVALID", "NA", "NA", etime_str, 0.0, excepStatus)
                    continue

                # Calculate memory usage is required
                if MEM_INFO:
                    # Memory Usage will always be approximate, because we are getting the mem stats
                    # at 5 min interval. So, we ceil/floor every time to the nearest 5 min interval
                    mem_time = roundTime(etime_dt, ceil=True)
                    if mem_time not in MEM_INFO:
                        mem_time = roundTime(etime_dt, ceil=False)  # If ceil time is not available, take floor

                    if mem_time in MEM_INFO:
                        mem_usage = sum(MEM_INFO[mem_time].values())    # Sum of memory on all nodes
                        mem_usage = memConvert(mem_usage)   # Convert the memory to desirable units
                    else:
                        mem_usage = 0
                else:
                    mem_usage = 0

                print_dict["bin"] = bin_str
                print_dict["rubix_time"] = timeConvert(bin_prefetch_time_secs)
                print_dict["ps_time"] = timeConvert(ptime_secs)
                print_dict["stime"] = stime_dt
                print_dict["etime"] = etime_dt
                print_dict["mem_usage"] = mem_usage
                print_dict["has_exception"] = excepStatus
                print_dict["bin_classes"] = bc_rubix_time

                # Write to file & screen
                print_row(print_dict, out_fh)
            except:
                sys.stderr.write("Error while processing bin %s" % str(bin))
                raise

        out_fh.write("\n===== SUMMARY =====\n")
        print("\n===== SUMMARY =====")
        if preload_time:
            out_fh.write("Cache Preload time: %s (%s secs)\n" % (timeConvert(preload_time), preload_time))
            print(bold + "Cache Preload time: %s (%s secs)" % (timeConvert(preload_time), preload_time) + reset)
            
        last_bin = sorted_bins[0][1]   # etime of latest bin
        first_bin = sorted_bins[-1][0]   # stime of first bin
        num_days_prefetched = timeConvert(last_bin - first_bin, long=True)
        out_fh.write("\nData prefetched for: %s\n" % num_days_prefetched)
        print(bold + "\nData prefetched for: %s" % num_days_prefetched + reset)

        # prefetch_end will be None if prefetching has just started
        if prefetch_end != None:
            total_prefetch_time = td_totalseconds(prefetch_end - prefetch_start)
            out_fh.write("\nTotal Prefetching Time: %s (%s secs)\n" % (timeConvert(total_prefetch_time), total_prefetch_time))
            print_bold("\nTotal Prefetching Time: ")
            print("%s (%s secs)" % (timeConvert(total_prefetch_time), total_prefetch_time))

        # Show Final Memory used
        if MEM_INFO:
            if not prefetch_end:
                final_memtime = roundTime(prefetch_start, ceil=True)  # Round to ceiling, since we want the latest memory usage
                if final_memtime not in MEM_INFO:
                    final_memtime = roundTime(prefetch_start)     # If latest time not available, take the last available one
            else:
                final_memtime = roundTime(prefetch_end, ceil=True)  # Round to ceiling, since we want the latest memory usage
                if final_memtime not in MEM_INFO:
                    final_memtime = roundTime(prefetch_end)     # If latest time not available, take the last available one

            # Get the sum of memory on all nodes
            total_memory = memConvert(sum(MEM_INFO.get(final_memtime, {}).values()))
            out_fh.write("\nFinal Memory Used On All Nodes: %0.2f %s\n" % (total_memory, MEMORY_DISPLAY_UNITS))
            print(bold + "\nFinal Memory Used On All Nodes: %0.2f %s" % (total_memory, MEMORY_DISPLAY_UNITS) + reset)

            out_fh.write("\nPer-Node Memory Usage:\n")
            print(bold + "\nPer-Node Memory Usage:" + reset)
            for ip, mem_usage in MEM_INFO.get(final_memtime, {}).iteritems():
                print("    %s : %0.2f %s" % (ip, memConvert(mem_usage), MEMORY_DISPLAY_UNITS))
                out_fh.write("    %s : %0.2f %s\n" % (ip, memConvert(mem_usage), MEMORY_DISPLAY_UNITS))

        out_fh.write("===============\n")
        print("===============")

        if excepFlag and PRINT_EXCEPTIONS:
            out_fh.write("\n")
            out_fh.write('DETAILED EXCEPTIONS OCCURED\n')
            print "\n"
            print bold+'DETAILED EXCEPTIONS OCCURED'+reset
            for bin_str, excep in exceptions:
                out_fh.write("%s --> %s\n" % (bin_str, excep))
                print "%s --> %s" %(bold+bin_str+reset, excep)

def print_bold(str):
    sys.stdout.write("%s%s%s" % (bold, str, reset))

def print_header(out_fh):
    if OUTPUT_FORMAT == 1:
        header = "%-45s%-25s%-15s%-22s%-22s%-15s%s" % \
                        ('QUERY','TOTAL TIME(RUBIX+INSTA)','INSTA TIME','START TIME','END TIME', "MEMORY(%s)" % MEMORY_DISPLAY_UNITS, 'EXCEPTIONS')
    elif OUTPUT_FORMAT == 2:
        header = "%-45s%-25s%-22s%-22s%-11s%-12s%s" % \
                        ('QUERY','TOTAL TIME(RUBIX+INSTA)','START TIME', "END TIME", "MEMORY(%s)" % MEMORY_DISPLAY_UNITS, 'EXCEPTIONS', "BIN CLASSES")
    print(header)
    out_fh.write(header + "\n")

def print_row(print_dict, out_fh):
    if OUTPUT_FORMAT == 1:
        format_string = "%(bin)-45s%(rubix_time)-25s%(ps_time)-15s%(stime)-22s%(etime)-22s%(mem_usage)-15.2f%(has_exception)s"
        output_line = format_string % print_dict
    elif OUTPUT_FORMAT == 2:
        format_string = "%(bin)-45s%(rubix_time)-25s%(stime)-22s%(etime)-22s%(mem_usage)-11.2f%(has_exception)-12s"
        output_line = format_string % print_dict
        bin_classes = sorted(print_dict["bin_classes"])
        output_line += bin_classes[0]
        for bc in bin_classes[1:]:
            output_line += "\n%s%s" % (" "*137, bc)

    print output_line
    out_fh.write(output_line + "\n")

def readLogFiles(pattern, date_str):
    log_files = glob.glob(pattern)
    for file in sorted(log_files):
        print("Reading file: %s" % file)
        cmd = 'zgrep -iE "%s" %s | sed "s/^/%s /" >> %s' % (INTERESTING_PATTERN, file, date_str, TMP_FILE)
        #print(cmd)
        runCmd(cmd)

def timeConvert(seconds, long=False):
    """Returns HH:MM:SS representation for value in seconds"""
    date_str = ""
    negative = True if seconds < 0 else False
    seconds = abs(seconds)

    m, s = divmod(seconds, 60)
    h, m = divmod(m, 60)
    d, h = divmod(h, 24)

    if long:
        # Do we want to print the long format
        date_str += "%02d days " % d if d > 0 else ""
        date_str += "%02d hours " % h if h > 0 else ""
        date_str += "%02d mins " % m if m > 0 else ""
        date_str += "%02d secs" % s if s > 0 else ""
    else:
        # Or the compact one
        date_str += "%02dD:" % d if d > 0 else ""
        date_str += "%02dH:%02dM:%02dS" % (h, m, s) if h > 0 else "%02dM:%02dS" % (m, s)

    if negative:
        date_str = "[negative] " + date_str
    return date_str

def memConvert(bytes):
    """Convert units of memory"""
    return float(bytes) / MEM_DIVISION_FACTORS[MEMORY_DISPLAY_UNITS]

def td_totalseconds(td):
    """Returns seconds present in timedelta"""
    return (td.microseconds + (td.seconds + td.days * 24 * 3600) * 10**6) / 10**6

def init_bin(pf_dict, bin, bin_class):
    """Initialize a prefetched bin with default values"""
    pf_dict.setdefault(bin, {"bin_classes" : {}, "exceptions" : []})
    pf_dict[bin]["bin_classes"].setdefault(bin_class, {})

    # Init Bin Class
    pf_dict[bin]["bin_classes"][bin_class].setdefault("stime", None)
    pf_dict[bin]["bin_classes"][bin_class].setdefault("etime", None)
    pf_dict[bin]["bin_classes"][bin_class].setdefault("ptime", 0.0)

def init_print_dict():
    print_dict = {
        "bin" : "NA",
        "stime" : "NA",
        "etime" : "NA",
        "mem_usage" : "NA",
        "rubix_time" : "NA",
        "ps_time" : "NA",
        "has_exception" : "NA"
    }
    return print_dict

def parseMemInfo(mem_usage_file):
    """Returns a dict with format {<timestamp> : <mem usage>}"""
    mem_usage = {}
    with open(mem_usage_file) as mem_usage_fh:
        file_contents = mem_usage_fh.read()

    for ts_m in re.finditer(r"Mem Usage Start for Timestamp: (?P<TIMESTAMP>[^\r\n]+)(?P<TS_BODY>.*?)Mem Usage Complete",
                            file_contents, flags=re.M|re.I|re.DOTALL):

        ts_str = ts_m.group("TIMESTAMP")
        ts_body = ts_m.group("TS_BODY")
        #print(ts_str)

        # Convert timestamp in datetime
        ts_dt = roundTime(datetime.strptime(ts_str, "%Y-%m-%d %H:%M"))
        mem_usage[ts_dt] = {}

        for ip_m in re.finditer(r"=== Fetch Start from (?P<IP>[\.\d]+)\s*===(?P<IP_BODY>.*?)=== Fetch Complete from",
                                ts_body, flags=re.M|re.I|re.DOTALL):
            ip = ip_m.group("IP")
            ip_body = ip_m.group("IP_BODY")
            #print(ip)

            if "Usage" not in ip_body:
                continue

            m = re.search(r"Usage = {.*?used\s*=\s*(?P<USED>[\d]+)[^{]*}", ip_body, flags=re.DOTALL|re.M)
            # Not keeping any check, because we always expect this output to be there.
            used_mem = m.group("USED")
            mem_usage[ts_dt][ip] = float(used_mem)
    return mem_usage

def roundTime(dt, roundTo=300, ceil=False):
    """Floor/Ceil a datetime object to the nearest binInterval in seconds
    dt : datetime object
    roundTo : Closest number of seconds to round to, default 5 minutes
    ceil : If you want to ceil the datetime, else dt will be floored
    """
    seconds = (dt - dt.min).seconds
    if ceil == False:
        rounding = seconds % roundTo
        return dt - timedelta(0, rounding, dt.microsecond)
    else:
        # // is floor division in the following line, not a comment :)
        rounding = ((seconds + roundTo) // roundTo * roundTo) - seconds
        return dt + timedelta(0, rounding, -dt.microsecond)

def getLocalIp():
    """Return the IP of Local Machine"""
    # Hack to find machine NIC IP
    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("192.168.1.1", 80))
    machine_ip = s.getsockname()[0]
    s.close()
    return machine_ip

def runCmd(cmd):
    p = subprocess.Popen(cmd, shell=True, universal_newlines=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = p.communicate()
    return stdout

if __name__ == "__main__":
    parser = OptionParser(usage="usage: %prog [options] ",version="%prog 1.0")
    parser.add_option("-f", "--file",
                action="store",
                dest="filepath",
                type="str",
                help="Complete log file path (Mandatory)")
    parser.add_option("-d", "--prevDays",
                action="store",
                dest="prevDays",
                type="int",
                help="How many old days' logs should be included in analysis")
    parser.add_option("-o", "--output",
                action="store",
                dest="outputFile",
                type="str",
                default=DEFAULT_OUTPUT_FILE,
                help="Name of output file (Default: %s)" % DEFAULT_OUTPUT_FILE)
    parser.add_option("-m", "--memInfoFile",
                action="store",
                dest="memInfoFile",
                type="str",
                help="File path containing Mem usage info")
    parser.add_option("-u", "--memUnits",
                action="store",
                default="G",
                dest="memUnits",
                choices=MEM_DIVISION_FACTORS.keys(),
                help="Units of memory usage to display (Default: G)")
    parser.add_option("-n", "--noExceptions",
                action="store_false",
                dest="printExceptions",
                default=True,
                help="Do not print all exceptions (Default: False)")
    parser.add_option("-c", "--columnFormat",
                action="store",
                dest="columnFormat",
                type="int",
                default=1,
                help="Output format to display columns (Default: 1) (Choices: 1, 2)")
    options, args = parser.parse_args()

    if not options.filepath:
        print >> sys.stderr, "-f/--file is a mandatory argument"
        parser.print_help()
        sys.exit(1)
    else:
        LOG_FILE = options.filepath

    PREV_DAYS = options.prevDays
    PRINT_EXCEPTIONS = options.printExceptions
    OUTPUT_FILE = options.outputFile
    MEMORY_DISPLAY_UNITS = options.memUnits
    if options.columnFormat not in (1, 2):
        print >> sys.stderr, "-c/--columnFormat supports only 1 or 2"
        parser.print_help()
        sys.exit(1)
    else:
        OUTPUT_FORMAT = options.columnFormat

    if options.memInfoFile:
        MEM_INFO = parseMemInfo(options.memInfoFile)
    else:
        MEM_INFO = None

    main()
