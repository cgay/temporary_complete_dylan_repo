Library:       io
Synopsis:      A portable IO library
Author:        Gail Zacharias
Copyright:     Original Code is Copyright (c) 1998-2001 Functional Objects, Inc.
               All rights reserved.
License:       Functional Objects Library Public License Version 1.0
Dual-license:  GNU Lesser General Public License
Warranty:      Distributed WITHOUT WARRANTY OF ANY KIND
Files:	library
	streams/defs
	streams/stream
	streams/sequence-stream
        streams/native-buffer
	streams/buffer
	streams/typed-stream
	streams/external-stream
	streams/buffered-stream
	streams/convenience
	streams/wrapper-stream
	streams/cleanup-streams
        streams/native-speed
        pprint
        print
        print-double-integer-kludge
	format
	buffered-format
	format-condition
	unix-standard-io
	format-out
Other-Files:   Open-Source-License.txt
Major-Version: 2
Minor-Version: 1
Target-Type:   dll

//---*** NOTE: Implement asynchronous? for streams using this file...
	streams/async-writes
