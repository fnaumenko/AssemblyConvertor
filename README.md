Exercise 
EMBL_test.pl is a script that converts region coordinates from GRCh38 to GRCh37 (or opposite) assemblies, using Ensempl Perl API.
This is a test exercise.

Usage:
EMBL_test.pl chrom start_pos end_pos [direct] [printTime] [printRegion]
chrom	: chromosome to convert, e.g. 10, X
start_pos	: source region start position
end_pos	: source region end position
direct	: direction of conversion: if 0 then GRCh38->GRCh37, if 1 then the opposite
default value	: 0 (false)
printTime	: if true then print elapsed time after each potentially time-consuming operation and total
default value	: 0 (false)
printRegion	: if true then print source and target regions
default value	: 0 (false)

Synopsis:
perl EMBL_test.pl Y 5000000 5000100
perl EMBL_test.pl 1 3000000 3005000 0 1


Challenge description
The main drawback of this implementation is the need to load the resulting sequence from the database on the client side in order to search for the source region. This can be a time-consuming operation (up to 2 minutes, depending on the chromosome and server load).
To reduce the latency, the following technique was applied: a subsequence is requested from the database with coordinates equal to the coordinates of the source region extended by DELTA, where DELTA is the difference in the length of the source and target chromosomes (i.e., chromosomes from different assemblies). The technique is based on the assumption that assemblies differ from each other by only a few inserts.
It really reduces the latency from 2 to 300 times (depending heavily on the chromosome, the coordinates of the source region, and server load).
If the region is not found (that is, the assumption is incorrect), then a search is performed on the entire assembly target chromosome.
Fundamentally, this flaw is eliminated when searching for a region on the server side. 
However, the Ensempl Perl API does not provide such opportunities, or I did not find them.

Note:
On the example of input data proposed in the task description – chromosome 10 from 25000 to 30000 –, the script returns a negative result (‘source region was not found within target sequence’). 
The analysis showed that there is a GRCh37 target region that almost coincides with the source one. Nevertheless, it differs in individual nucleotides. Since the admissibility of such minor discrepancies was not specified in the task description, the script looks for a complete match only.
Unfortunately, I cannot interpret the region chr10 25000 30000 conversion results, obtained by the Ensembl Assembly Convertor. It gives out 4 subregions, but already in the first one  there is at least one single mismatch.
I also find it difficult to interpret the results obtained by NCBI Genome Remapping Service, although in this case at least the coordinates of the region with minor discrepancies are returned.

Alternatives
I found at least 3 ways of retrieving the same information.
1.	online Ensembl Assembly Convertor https://www.ensembl.org/Homo_sapiens/Tools/AssemblyConverter?db=core
2.	online NCBI Genome Remapping Service
https://www.ncbi.nlm.nih.gov/genome/tools/remap
Both services have the similar advantages:
•	visibility
•	low latency
•	flexibility in the choice of assemblies
•	choice of input data format.
•	NCBI Remapping Service has also 4 remapping options.
Disadvantages are typical of online services: the impossibility or difficulty of using calculations in pipe-line tool chain.
3.	CrossMap tool
https://academic.oup.com/bioinformatics/article/30/7/1006/234947
Advantages:
•	estimated  high-performance
•	wide choice of user input file format
Disadvantages:
•	installation (and python preinstalled) required
•	chain files download required
•	If input file is in VCF format, a reference genome sequence download required
