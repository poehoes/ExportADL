#!/usr/bin/perl
#
# File		: ExportAquaDiveLog.pl
# Author	: Rob van Eerd
# Date		: 01-2-2005
# Purpose	: Perl Script to read AquaDiveLog databases
# Dependencies	: Requires/assumes stylesheet Menu.css
# Requires      : ExportAquaDiveLog.conf
# Usage		:

our($progname);

use strict;								# be strict
use Data::Dumper;						# Module to properly print complex structures
use DateTime;
use DateTime::Locale;
use File::Basename;						# Use File-basename
use Getopt::Long;						# Command Line options Parser

use ReadADL qw(:Both);
#use WritePDL;
#use WriteUDCF qw(:UDCF);
use WriteUDDF qw(:UDDF);

my $global_debug = 0;					# Global setting for debugging

my @exts = qw(.pl .cgi);				# This program can be run as a Perl-script or as a CGI-script
my ($progname,$path,$extension) = fileparse($0, @exts);

my $configFile = $progname.".conf";		# configuration file (including path)
my %config;								# hash containing configuration
my $key;								# hash key loop variable


# Various hashes to store the data retrieved. Using these hashes, the data can later be used
	our %diver;				# Hash to store diver information
	our %locations;			# Hash containing all Dive Location info
	our %places;			# Hash containing all Dive Place info
	our %suits;				# Hash containing all Dive Suit info
	our %diveComputers;		# Hash containing all Dive Computer info
	our %manufacturers;		# Hash containing all Equipment Manufacturers
	our %tanks;				# Hash containing all Tank info
	our %buddies;			# Hash containing all Buddy info
	our %units;				# Hash containing the units used
	our %diveTypes;			# Hash containing the various (user defined) types of dives
	our %logbookEntry;		# Hash containing all data from the Dive Logbook
	our $diveNr;			# Unique Number, increased by 1
	our %diveDebugInfo;		# Hash containing info to debug missing dives.
	our %mixes;				# Hash containing the mixes used while diving
	

my $dummy;

#################################################
### Subroutines
#################################################


### Read configuration file
sub ReadConfig {
	# Parameters:
	# fileName	Name of hrFile to write
	# table		Reference to hash to store config
	my ( $fileName, $table ) = @_;		# get config filename, hash ref to store config
	my ( $key, $val );				# key, value pair

	open( INFILE, "<$fileName" ) || 		# open config file
    	die "Cannot read config file $fileName: $!";

	while ( <INFILE> ) {			# read a line
		chomp;						# remove newline
		s/#.*//;					# remove comments
		s/^\s+//;					# remove leading whitespace
		s/\s+$//;					# remove trailing whitespace
		next unless length;			# if anything left
		( $key, $val ) = split (/\s*=\s*/, $_, 2);	# split into key, value pair
		$table->{ $key } = $val;			# store in config hash
	}
	close( INFILE );

	if ($global_debug) {
		print "\n"; 
		printf ( "%s line(s) read from config file\n", scalar( keys( %$table ) ));
	}
}


#################################################
### Initialisation
#################################################

GetOptions(	"config=s" => \$configFile );	# get optional alternate config file


#################################################
### Main
#################################################

my $startTime = time();
#if ($global_debug) {
	print "\n$progname started.\n";						# log notice
#}

ReadConfig( $configFile, \%config );				# read configuration file
my $dataDir = $config{ "datadir" };						# get data directory
my $tableDB = $config{ "TableDB" };
my $diveDB = $config{ "DiveDB" };
my $udcf = $dataDir."/".$progname.".udcf";
my $uddf = $dataDir."/".$progname.".uddf";

ReadTables ( $dataDir.$tableDB );
ReadDives ( $dataDir.$diveDB);

# WritePDL();

#WriteUDCF($udcf);

WriteUDDF($uddf);

# $Data::Dumper::Indent = 0;
# $Data::Dumper::Useqq  = 1;
$Data::Dumper::Purity = 1;

my @sortedDives = sort { $logbookEntry{$a} cmp $logbookEntry{$b} } keys %logbookEntry; 

my $logFile = $dataDir.$progname.".log";
open (LOGFILE, ">$logFile") || die "Can't open $logFile: $!";
#if ($global_debug) {
	my $dd = Data::Dumper->new(
    	[ \%diver, \%units, \%locations, \%places, \%suits, \%diveComputers, \%tanks, \%buddies, \%diveTypes, \%logbookEntry, \@sortedDives, \%diveDebugInfo],
    	[ qw(*diver *units *locations *places *suits *diveComputers *tanks *buddies *diveTypes *logbookEntry *DiveList *DiveDebugInfo) ]
    );
print LOGFILE $dd->Dump;

print LOGFILE sprintf("#%-25s: %i\n", "Locations", scalar(keys %locations));
print LOGFILE sprintf("#%-25s: %i\n", "Places", scalar(keys %places));
print LOGFILE sprintf("#%-25s: %i\n", "Suits", scalar(keys %suits));
print LOGFILE sprintf("#%-25s: %i\n", "DiveComputers", scalar(keys %diveComputers));
print LOGFILE sprintf("#%-25s: %i\n", "Tanks", scalar(keys %tanks));
print LOGFILE sprintf("#%-25s: %i\n", "Buddies", scalar(keys %buddies));
print LOGFILE sprintf("#%-25s: %i\n", "Dives", scalar(keys %logbookEntry));


#}

my $endTime = time();
#if ($global_debug) {
	printf("\n$progname ended in %i seconds.\n", $endTime - $startTime);						# log notice
#}
exit;
