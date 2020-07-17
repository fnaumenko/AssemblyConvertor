# Assembly Convertor
**EMBL_test.pl** is a script that converts region coordinates from GRCh38 to GRCh37 (or opposite) assemblies, using Ensempl Perl API.<br>
This is a test exercise.<br>

## Usage
`EMBL_test.pl chrom start_pos end_pos direct [printTime] [printRegion]`<br>
`chrom`	: chromosome to convert, e.g. 10, X
`start_pos`	: source region start position
`end_pos`	: source region end position
`direct`	: direction of conversion: if 0 then GRCh38-> GRCh37, if 1 then the opposite 
default value	: 0 (false)
`printTime`	: if true then print elapsed time after each potentially time-consuming operation and total
default value	: 0 (false)
`printRegion`	: if true then print source and target regions
default value	: 0 (false)

`biostat <command> [options] [<file>…]`<br>
or<br>
`<Command> [options] [<file>…]`<br><br>
In the second case, the output to the terminal is carried out immediately, which can be informative when processing large input files.

## Synopsis
`perl EMBL_test.pl Y 5000000 5000100`
`perl EMBL_test.pl 1 3000000 3005000 1 1`

## Brief challenge description
The main drawback of this implementation is the need to load the resulting sequence from the database on the client side in order to search for the source region.
 This can be a time-consuming operation (up to 2 minutes, depending on the chromosome and server load).<br>
To reduce the latency, the following technique was applied: a subsequence is requested from the database 
with coordinates equal to the coordinates of the source region extended by DELTA, 
where DELTA is the difference in the length of the source and target chromosomes (i.e., chromosomes from different assemblies). 
The technique is based on the assumption that assemblies differ from each other by only a few inserts.<br>
It really reduces the latency from 2 to 300 times (depending heavily on the chromosome, the coordinates of the source region, and server load).<br>
If the region is not found (that is, the assumption is incorrect), then a search is performed on the entire assembly target chromosome.<br>
Fundamentally, the flaw is eliminated when searching for a region on the server side.<br>
However, the Ensempl Perl API does not provide such opportunities, or I did not find them.

