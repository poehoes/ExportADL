package WriteUDDF;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use DateTime;

$VERSION     = 1.00;
@ISA         = qw(Exporter);
	# See perlboot for all the gory details on what @ISA is or just use it as shown.
@EXPORT      = ();
	# @EXPORT contains a list of functions that we export by default, in this case nothing. Generally the less you export by default using @EXPORT the better. This avoids accidentally clashing with functions defined in the script using the module. If a script wants a function let it ask.
@EXPORT_OK   = qw(&WriteUDDF);
	# @EXPORT_OK contains a list of functions that we export on demand so we export &func1 &func2 only if specifically requested to. Use this in preference to just blindly exporting functions via @EXPORT. You can also export variables like $CONFIG provided they are globals not lexicals scoped with my (read declare them with our or use vars).
%EXPORT_TAGS = ( UDDF    => [qw(&WriteUDDF)]);
	# %EXPORT_TAGS. For convenience we define two sets of export tags. The ':DEFAULT' tag exports only &func1; the ':Both' tag exports both &func1 &func2. This hash stores labels pointing to array references. In this case the arrays are anonymous.

our($progname);
my $DCUsed;
my $consumption;
my $TSStartDive="";
my $TSEndDive="";
my $SurfaceInterval="";

### Clean the text to be written to the UDDF file
sub WriteUDDF_DocType {
# Parameters:
	local *UUDF = shift;
	
	print UDDF "<!DOCTYPE uddf [\n";

	print UDDF "<!ENTITY Agrave \"Ë\">\n";
	print UDDF "<!ENTITY Aacute \"ç\">\n";
	print UDDF "<!ENTITY Acirc \"å\">\n";
	print UDDF "<!ENTITY Atilde \"Ì\">\n";
	print UDDF "<!ENTITY Auml \"€\">\n";

	print UDDF "<!ENTITY Egrave \"é\">\n";
	print UDDF "<!ENTITY Eacute \"ƒ\">\n";
	print UDDF "<!ENTITY Ecirc \"æ\">\n";
	print UDDF "<!ENTITY Euml \"è\">\n";

	print UDDF "<!ENTITY Igrave \"í\">\n";
	print UDDF "<!ENTITY Iacute \"ê\">\n";
	print UDDF "<!ENTITY Icirc \"ë\">\n";
	print UDDF "<!ENTITY Iuml \"ì\">\n";

	print UDDF "<!ENTITY Ograve \"ñ\">\n";
	print UDDF "<!ENTITY Oacute \"î\">\n";
	print UDDF "<!ENTITY Ocirc \"ï\">\n";
	print UDDF "<!ENTITY Otilde \"Í\">\n";
	print UDDF "<!ENTITY Ouml \"…\">\n";

	print UDDF "<!ENTITY Ugrave \"ô\">\n";
	print UDDF "<!ENTITY Uacute \"ò\">\n";
	print UDDF "<!ENTITY Ucirc \"ó\">\n";
	print UDDF "<!ENTITY Uuml \"†\">\n";

	print UDDF "<!ENTITY agrave \"ˆ\">\n";
	print UDDF "<!ENTITY aacute \"‡\">\n";
	print UDDF "<!ENTITY acirc \"‰\">\n";
	print UDDF "<!ENTITY atilde \"‹\">\n";
	print UDDF "<!ENTITY auml \"Š\">\n";

	print UDDF "<!ENTITY egrave \"\">\n";
	print UDDF "<!ENTITY eacute \"Ž\">\n";
	print UDDF "<!ENTITY ecirc \"\">\n";
	print UDDF "<!ENTITY euml \"‘\">\n";

	print UDDF "<!ENTITY igrave \"“\">\n";
	print UDDF "<!ENTITY iacute \"’\">\n";
	print UDDF "<!ENTITY icirc \"”\">\n";
	print UDDF "<!ENTITY iuml \"•\">\n";

	print UDDF "<!ENTITY ograve \"˜\">\n";
	print UDDF "<!ENTITY oacute \"—\">\n";
	print UDDF "<!ENTITY ocirc \"™\">\n";
	print UDDF "<!ENTITY otilde \"›\">\n";
	print UDDF "<!ENTITY ouml \"š\">\n";

	print UDDF "<!ENTITY ugrave \"\">\n";
	print UDDF "<!ENTITY uacute \"œ\">\n";
	print UDDF "<!ENTITY ucirc \"ž\">\n";
	print UDDF "<!ENTITY uuml \"Ÿ\">\n";

	print UDDF "]>\n";
	print UDDF "\n";
}


###############################################################################
# Perl left function to keep "length" characters of "string"
sub left {
	my ($string, $length) = @_;
	return substr($string, 0, $length);
}


###############################################################################
# Perl trim function to remove whitespace from the start and end of the string
sub trim($) {
	my $string= shift;
	$string=~ s/^\s+//;
	$string=~ s/\s+$//;
	return $string;
}


### Clean the text to be written to the UDDF file
sub CleanUDDF ($) {
# Parameters: one line of text (put in $_)
	my $UDDF_Line = shift;
	
	$UDDF_Line =~ s/\xC0/&Agrave;/g;	# Translate "Ë" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xC1/&Aacute;/g;	# Translate "ç" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xC2/&Acirc;/g;		# Translate "å" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xC3/&Atilde;/g;	# Translate "Ì" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xC4/&Auml;/g;		# Translate "€" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xC5/&Aring;/g;		# Translate "A with a ring on top" into a valid XML / UDDF code.

	$UDDF_Line =~ s/\xC8/&Egrave;/g;	# Translate "é" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xC9/&Eacute;/g;	# Translate "ƒ" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xCA/&Ecirc;/g;		# Translate "æ" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xCB/&Euml;/g;		# Translate "è" into a valid XML / UDDF code.

	$UDDF_Line =~ s/\xCC/&Igrave;/g;	# Translate "í" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xCD/&Iacute;/g;	# Translate "ê" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xCE/&Icirc;/g;		# Translate "ë" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xCF/&Iuml;/g;		# Translate "ì" into a valid XML / UDDF code.

	$UDDF_Line =~ s/\xD2/&Ograve;/g;	# Translate "ñ" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xD3/&Oacute;/g;	# Translate "î" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xD4/&Ocirc;/g;		# Translate "ï" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xD5/&Otilde;/g;	# Translate "Í" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xD6/&Ouml;/g;		# Translate "…" into a valid XML / UDDF code.

	$UDDF_Line =~ s/\xD9/&Ugrave;/g;	# Translate "ô" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xDA/&Uacute;/g;	# Translate "ò" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xDB/&Ucirc;/g;		# Translate "ó" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xDC/&Uuml;/g;		# Translate "†" into a valid XML / UDDF code.

	$UDDF_Line =~ s/\xE0/&agrave;/g;	# Translate "ˆ" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xE1/&aacute;/g;	# Translate "‡" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xE2/&acirc;/g;		# Translate "‰" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xE3/&atilde;/g;	# Translate "‹" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xE4/&auml;/g;		# Translate "Š" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xE6/&aring;/g;		# Translate "a with a ring on top" into a valid XML / UDDF code.

	$UDDF_Line =~ s/\xE8/&egrave;/g;	# Translate "" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xE9/&eacute;/g;	# Translate "Ž" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xEA/&ecirc;/g;		# Translate "" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xEB/&euml;/g;		# Translate "‘" into a valid XML / UDDF code.

	$UDDF_Line =~ s/\xEC/&igrave;/g;	# Translate "“" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xED/&iacute;/g;	# Translate "’" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xEE/&icirc;/g;		# Translate "”" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xEF/&iuml;/g;		# Translate "•" into a valid XML / UDDF code.

	$UDDF_Line =~ s/\xF2/&ograve;/g;	# Translate "˜" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xF3/&oacute;/g;	# Translate "—" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xF4/&ocirc;/g;		# Translate "™" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xF5/&otilde;/g;	# Translate "›" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xF6/&ouml;/g;		# Translate "š" into a valid XML / UDDF code.

	$UDDF_Line =~ s/\xF9/&ugrave;/g;	# Translate "" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xFA/&uacute;/g;	# Translate "œ" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xFB/&ucirc;/g;		# Translate "ž" into a valid XML / UDDF code.
	$UDDF_Line =~ s/\xFC/&uuml;/g;		# Translate "Ÿ" into a valid XML / UDDF code.

	$UDDF_Line =~ s/>/&gt;/g;			# Translate ">" into a valid XML / UDDF code.
	$UDDF_Line =~ s/</&lt;/g;			# Translate "<" into a valid XML / UDDF code.
	$UDDF_Line =~ s/&/&amp;/g;			# Translate "&" into a valid XML / UDDF code.
    
#	#Temporary disabled because of use of DocType entities
#	$UDDF_Line =~ s/&//g;
#	$UDDF_Line =~ s/;//g;

	return $UDDF_Line;
}


### Calculate the End-of-Dive TimeStamp
sub CalculateDiveEnd {
# Parameters: TSStartDive & DiveDuration
	my $Start = shift;
	my $Duration = shift;
	my $End;
	
	my ($sdate, $stime) = split('T', $Start);
	my ($syyyy, $smm, $sdd) = split('-', $sdate);
	my ($shh, $smin, $sss) = split(':', $stime);
	
	if ( not defined $sss ) {
		$sss = 0;
	}
	my $dt = DateTime->new(
			year		=> $syyyy,
			month		=> $smm,
			day			=> $sdd,
			hour		=> $shh,
			minute		=> $smin,
			second		=> $sss,
			nanosecond	=> 0,
			time_zone	=> 'Europe/Amsterdam',
	);
	$dt->add( seconds => $Duration );

	$End = sprintf("%4d-%02d-%02dT%02d:%02d:%02d",$dt->year(),$dt->month(),$dt->day(),$dt->hour(),$dt->minute(),$dt->second());	
	return $End;
}


### Calculate the SurfaceInterval (in seconds) between the Timestamps of the last Dive and the start of the new dive.
sub CalculateSurfaceInterval {
# Parameters: TSStartDive & TSEndDive
	my $TSStartDive = shift;
	my $TSEndDive = shift;
	my $SurfaceInterval;
	
	my ($sdate, $stime) = split('T', $TSStartDive);
	my ($syyyy, $smm, $sdd) = split('-', $sdate);
	my ($shh, $smin, $sss) = split(':', $stime);
	if ( not defined $sss ) {
		$sss = 0;
	}
	
	my ($edate, $etime) = split('T', $TSEndDive);
	my ($eyyyy, $emm, $edd) = split('-', $edate);
	my ($ehh, $emin, $ess) = split(':', $etime);
	if ( not defined $ess ) {
		$ess = 0;
	}
	
	my $sdt = DateTime->new(
			year		=> $syyyy,
			month		=> $smm,
			day			=> $sdd,
			hour		=> $shh,
			minute		=> $smin,
			second		=> $sss,
			nanosecond	=> 0,
			time_zone	=> 'Europe/Amsterdam',
	);
	my $edt = DateTime->new(
			year		=> $eyyyy,
			month		=> $emm,
			day			=> $edd,
			hour		=> $ehh,
			minute		=> $emin,
			second		=> $ess,
			nanosecond	=> 0,
			time_zone	=> 'Europe/Amsterdam',
	);
	$SurfaceInterval = $sdt->subtract_datetime( $edt );

#	my $epoch = DateTime->new(
#			year		=> 1970,
#			month		=> 1,
#			day			=> 1,
#			hour		=> 0,
#			minute		=> 0,
#			second		=> 0,
#			nanosecond	=> 0,
#			time_zone	=> 'Europe/Amsterdam',
#	);
#	$sdt->subtract_datetime( $epoch );

#	$SurfaceInterval = $sdt;	
	return $SurfaceInterval->seconds + ( $SurfaceInterval->minutes * 60 ) + ( $SurfaceInterval->days * 24 * 3600);
}


### Clean the text to be used as an ID
sub CleanID ($) {
# Parameters: one line of text (put in $_)
	my $ID = shift;
	
	$ID =~ s/ /_/g;			# Translate " " into an underscore "_"
	$ID =~ s/\./_/g;		# Translate "." into an underscore "_"
	$ID =~ s/&/-/g;			# Translate "&" into a plus sign "-"
	$ID =~ s/\(//g;			# Remove "(" from ID's
	$ID =~ s/\)//g;			# Remove ")" from ID's
	$ID =~ s/\///g;			# Remove "/" from ID's
	$ID =~ s/\*/-/g;		# Translate "*" into a plus sign "-"

	$ID =~ s/_-_/-/g;		# Translate "*" into a plus sign "-"

	return $ID;
}

### Create UDDF DiveComputerControl Section
sub WriteUDDF_Date {
# Parameters:
	local *UUDF = shift;
	my $tag = shift;
	my $date = shift;

	if ( substr($date,10,1) ne "T" ) {		#	If "time is missing", add a default. Suggested a change in the XSD to use xsd:date format!
		$date .= "T00:00:00";
	} elsif ( length($date) == 16 ) {		#	If "seconds" are missing add a default.
		$date .= ":00";	# MoreMobileSoftware accepted seconds from version 2.3.4.7, to match "xsd:datetime" datatype format!
	}

	if ( $tag ne "" ) {
		print UDDF "				<".$tag.">\n";	
	}
#TODO If suggestion to use "xsd:date" datatype is accepted, following tag needs to be adjusted accordingly for dates without times.
	if ( substr($date,10,1) ne "T" ) {		#	If "time is missing", add a default. Suggested a change in the XSD to use xsd:date format!
		print UDDF "					<date>".$date."</date>\n";
	} else {
		print UDDF "					<datetime>".$date."</datetime>\n";	
	}
	if ( $tag ne "" ) {
		print UDDF "				</".$tag.">\n";	
	}
}


#######################################################################################################################
###### Writing the UDDF file
#######################################################################################################################


### Create UDDF DiveComputerControl Section
sub WriteUDDF_Dive_ComputerControl {
# Parameters:

	local *UUDF = shift;

#    <divecomputercontrol>
#        <!-- statements for setting on data on a divecomputer, or downloading data from a dive computer -->
#    </divecomputercontrol>

}

### Create UDDF Buddies Section
sub WriteUDDF_Diver_Buddies {
	# Parameters:
    
	local *UUDF = shift;
	my ($buddy, $firstName, $lastName);

	#	for each buddy
	foreach $buddy (sort keys %::buddies) {
		print UDDF "	<buddy id=\"bd-".CleanID($buddy)."\">\n";
		print UDDF "		<personal>\n";
		if ( index($::buddies{$buddy}{Name}, ' ') ) {
			($firstName, $lastName) = split (' ', $::buddies{$buddy}{Name}, 2);
		} elsif ( index($::buddies{$buddy}{Name}, '.') ) {
			($firstName, $lastName) = split ('.', $::buddies{$buddy}{Name}, 2);
		} else {
			$firstName = $::buddies{$buddy}{Name};
			$lastName = $::buddies{$buddy}{Name};
		}
		print UDDF "			<firstname>".CleanUDDF($firstName)."</firstname>\n";
		print UDDF "			<lastname>".CleanUDDF($lastName)."</lastname>\n";
#		print UDDF "			<sex>m/f</sex>\n";
#		print UDDF "			<birthdate>\n";
#		print UDDF "				<year>1974</year>\n";
#		print UDDF "			</birthdate>\n";
		print UDDF "		</personal>\n";
#		print UDDF "		<address>\n";
#		print UDDF "			<street>Check Notes</street>\n";
#		print UDDF "			<city>Check Notes</city>\n";
#		print UDDF "			<postcode>Check Notes</postcode>\n";
#		print UDDF "			<province>Check Notes</province>\n";
#		print UDDF "			<country>Check Notes</country>\n";
#		print UDDF "		</address>\n";
#		print UDDF "		<contact>\n";
#		print UDDF "			<language>Check Notes</language>\n";
#		print UDDF "			<mobilephone>Check Notes</mobilephone>\n";
#		print UDDF "			<fax>Check Notes</fax>\n";
#		print UDDF "			<email>Check Notes</email>\n";
#		print UDDF "		</contact>\n";
#		print UDDF "		<equipment>\n";
#		print UDDF "			<!-- listing of buddy's equipment -->\n";
#		print UDDF "		</equipment>\n";
#		print UDDF "		<medical>\n";
##		print UDDF "			<!-- listing of buddy's dive medical examinations - if known -->\n";
#		print UDDF "		</medical>\n";
#		print UDDF "		<education>\n";
##		print UDDF "			<certification>\n";
##		print UDDF "				<level>Gold</level>\n";
##		print UDDF "				<organization>CMAS</organization>\n";
##		print UDDF "			</certification>\n";
#		print UDDF "		</education>\n";
		print UDDF "		<notes>\n";
		print UDDF "			<para>\n";
		print UDDF "				FullName: ".CleanUDDF($::buddies{$buddy}{Name})."\n";
		if ( $::buddies{$buddy}{Address} ne "" ) {
			print UDDF "				Address: ".CleanUDDF($::buddies{$buddy}{Address})."\n";
		}
		if ( $::buddies{$buddy}{Remarks} ne "" ) {
			print UDDF "				Notes:\n";
			print UDDF "				".CleanUDDF($::buddies{$buddy}{Remarks})."\n";
		}
#		print UDDF "				<link ref=\"img_linda1\"/>\n";
#		print UDDF "				<link ref=\"img_linda2\"/>\n";
#		print UDDF "				<link ref=\"video_by_linda_great_barrier_reef\"/>\n";
		print UDDF "			</para>\n";
		print UDDF "		</notes>\n";
		print UDDF "	</buddy>\n";

	}
}

### Create UDDF DiveInsurance Section
sub WriteUDDF_Diver_DiveInsurance {
	# Parameters:
    
	local *UUDF = shift;
	
	print UDDF "		<diveinsurances>\n";
	print UDDF "			<insurance>\n";
	print UDDF "				<name>For Ever Diving</name>\n";
	WriteUDDF_Date( \*UDDF , "issuedate", "2004-03-30");
	WriteUDDF_Date( \*UDDF , "validdate", "2005-03-29");
	print UDDF "			</insurance>\n";
	print UDDF "		</diveinsurances>\n";
}

### Create UDDF DivePermissions Section
sub WriteUDDF_Diver_DivePermissions {
	# Parameters:
    
	local *UUDF = shift;

	print UDDF "		<divepermissions>\n";
##						<!-- as many dive permissions as needed can be listed here -->
	print UDDF "			<permit>\n";
	print UDDF "				<name>DiveCard</name>\n";
	print UDDF "				<region>Austria</region>\n";
	WriteUDDF_Date( \*UDDF , "issuedate", "2004-08-24");
	WriteUDDF_Date( \*UDDF , "validdate", "2005-08-23");
	print UDDF "			</permit>\n";
	print UDDF "		</divepermissions>\n";
}

### Create UDDF Education Section
sub WriteUDDF_Diver_Education {
	# Parameters:
    
	local *UUDF = shift;

	print UDDF "		<education>\n";
#						<!-- all levels of diving education -> several -->
#						<!-- <certification> elements one after the other -->
	print UDDF "			<certification>\n";
	print UDDF "				<level>".$::diver{Level}."</level>\n";
	print UDDF "				<organization>".$::diver{Organization}."</organization>\n";
##								<!-- because the data of the then diving instructor were not -->
##								<!-- written into the UDDF file a cross refence via -->
##								<!-- <link ref="..."/> is omitted -->
#	WriteUDDF_Date( \*UDDF , "issuedate", "1994-03-15");
	print UDDF "			</certification>\n";
	print UDDF "		</education>\n";
}

### Create UDDF Equipment BCDs Section
sub WriteUDDF_Diver_Equipment_BCDs {
	# Parameters:
    
	local *UUDF = shift;

	print UDDF "				<buoyancycontroldevice id=\"my_bcd\">\n";
	print UDDF "					<name>ABC</name>\n";
	print UDDF "					<link ref=\"man-JM\" />\n";
	print UDDF "					<model>Underwater Camping Team</model>\n";
	print UDDF "					<serialnumber>123456789</serialnumber>\n";
	print UDDF "					<purchase>\n";
	WriteUDDF_Date( \*UDDF , "", "1960-05-31");
	print UDDF "						<price currency=\"EUR\">100.00</price>\n";
	print UDDF "						<shop id=\"DDD\">\n";
	print UDDF "							<name>Dive Deep Down</name>\n";
	print UDDF "							<address>\n";
	print UDDF "								<!-- address of shop -->\n";
	print UDDF "								<street>Betterstr. 46</street>\n";
	print UDDF "								<city>Atown</city>\n";
	print UDDF "								<postcode>87678</postcode>\n";
	print UDDF "								<country>Texas, USA</country>\n";	
	print UDDF "							</address>\n";
	print UDDF "							<contact>\n";
	print UDDF "								<!-- phone number, email address etc. -->\n";
	print UDDF "							</contact>\n";
	print UDDF "							<notes>\n";
	print UDDF "								<!-- additional remarks -->\n";
	print UDDF "							</notes>\n";
	print UDDF "						</shop>\n";
	print UDDF "					</purchase>\n";
	print UDDF "					<!-- service every year -->\n";
	print UDDF "					<serviceinterval>365</serviceinterval>\n";
	WriteUDDF_Date( \*UDDF , "nextservicedate", "2006-05-31");
	print UDDF "			    </buoyancycontroldevice>\n";
}

### Create UDDF Equipment Regulators Section
sub WriteUDDF_Diver_Equipment_DiveComputers {
	# Parameters:
    
	local *UUDF = shift;
	my ($dcID);

	
	foreach $dcID (sort keys %::diveComputers) {
		print UDDF "			<divecomputer id=\"dc-".sprintf("%02d",$dcID)."\">\n";
		print UDDF "				<name>".CleanUDDF($::diveComputers{$dcID}{Model})."[dc-".sprintf("%02d",$dcID)."]</name>\n";
		print UDDF "				<link ref=\"man-".CleanID(sprintf("%03d",$::diveComputers{$dcID}{ManufacturerID}))."\" />\n";
		print UDDF "				<model>".CleanUDDF($::diveComputers{$dcID}{Model})."</model>\n";
		print UDDF "				<serialnumber>".CleanUDDF($::diveComputers{$dcID}{Serial})."</serialnumber>\n";
#		print UDDF "				<purchase>\n";
#		print UDDF "					<datetime>1994-05-28</datetime>\n";
#		print UDDF "					<price currency=\"DM\">400.00</price>\n";
#		print UDDF "					<shop>\n";
#		print UDDF "						<name>various electronical shops</name>\n";
#		print UDDF "						<address>\n";
##												<!-- address of shop -->\n";
#		print UDDF "						</address>\n";
#		print UDDF "						<contact>\n";
##												<!-- phone number, email address etc. -->\n";
#		print UDDF "						</contact>\n";
#		print UDDF "						<notes>\n";
##												<!-- additional remarks -->\n";
#		print UDDF "						</notes>\n";
#		print UDDF "					</shop>\n";
#		print UDDF "				</purchase>\n";
		print UDDF "			</divecomputer>\n";
	}
}

### Create UDDF Equipment Regulators Section
sub WriteUDDF_Diver_Equipment_Regulators {
	# Parameters:
    
	local *UUDF = shift;

	print UDDF "			<regulator id=\"roberts_best_piece\">\n";
	print UDDF "				<name>Black Shark</name>\n";
	print UDDF "				<link ref=\"man-Neptun\" />\n";
	print UDDF "				<model>Black Shark 5</model>\n";
	print UDDF "				<serialnumber>111111</serialnumber>\n";
	print UDDF "				<purchase>\n";
	WriteUDDF_Date( \*UDDF , "", "1967-10-13");
	print UDDF "					<price currency=\"USD\">100.00</price>\n";
	print UDDF "					<shop id=\"DEM\">\n";
	print UDDF "						<name>Diving Equipment Muller</name>\n";
	print UDDF "						<address>\n";
	print UDDF "							<street>Betterstr. 46</street>\n";
	print UDDF "							<city>Atown</city>\n";
	print UDDF "							<postcode>87678</postcode>\n";
	print UDDF "							<country>Texas, USA</country>\n";
	print UDDF "						</address>\n";
	print UDDF "						<contact>\n";
	print UDDF "							<language>English</language>\n";
	print UDDF "							<phone>0345/123123</phone>\n";
	print UDDF "						</contact>\n";
	print UDDF "					</shop>\n";
	print UDDF "				</purchase>\n";
	WriteUDDF_Date( \*UDDF , "nextservicedate", "2007-05-31");
	print UDDF "			</regulator>\n";
}

### Create UDDF Equipment Suits Section
sub WriteUDDF_Diver_Equipment_Suits {
	# Parameters:
    
	local *UUDF = shift;
	my $suitID;
	my %ADLSuitTypes = (
		"0" => "Swim Suit",
		"1" => "Dive Skin",
		"2" => "Wet Suit",
		"3" => "Semi Dry Suit",
		"4" => "Dry Suit",
		"5" => "Hot Water Suit",
		"6" => "Other"
	);
	my %ADLSuitTypeConversion = (
		"Swim Suit"			=> "other",
		"Dive Skin"			=> "dive-skin",
		"Wet Suit"			=> "wet-suit",
		"Semi Dry Suit"		=> "wet-suit",
		"Dry Suit"			=> "dry-suit",
		"Hot Water Suit"	=> "hot-water-suit",
		"Other"				=> "other"
	);
	
	foreach $suitID (sort keys %::suits) {
		print UDDF "			<suit id=\"suit-".$suitID."\">\n";
#		Allowed keywords are: dive-skin, wet-suit (also a "semi-dry suit" is classified hereunder), dry-suit, hot-water-suit, other.
		print UDDF "				<name>".CleanUDDF($::suits{$suitID}{Name})."</name>\n";
		print UDDF "				<notes>\n";
		print UDDF "					<para>\n";
		print UDDF "						ADL-Suit-Type: ".CleanUDDF($::suits{$suitID}{Type})."\n";
		print UDDF "						Default Weight: ".$::suits{$suitID}{Weight}."\n";
		print UDDF "						Status Active: ".$::suits{$suitID}{Active}."\n";
		print UDDF "					</para>\n";
		print UDDF "				</notes>\n";
		print UDDF "				<suittype>".CleanUDDF($ADLSuitTypeConversion{$::suits{$suitID}{Type}})."</suittype>\n";
		print UDDF "			</suit>\n";
	}
}

### Create UDDF Equipment Tanks Section
sub WriteUDDF_Diver_Equipment_Tanks {
	# Parameters:
    
	local *UUDF = shift;
	my $tankID;
	my %tankMaterialConversion = (
		"Steel" 	=> "steel",
		"Aluminium" => "aluminium"
	);
	
	foreach $tankID (sort keys %::tanks) {
		print UDDF "			<tank id=\"tank-".CleanID($tankID)."\">\n";
		print UDDF "				<name>".CleanUDDF($::tanks{$tankID}{Name})."</name>\n";
#		print UDDF "				<link ref=\"man-STM\" />\n";
#		print UDDF "				<model>Hard as Steel</model>\n";
#		print UDDF "				<serialnumber>12345</serialnumber>\n";
#		print UDDF "				<purchase>\n";
#		WriteUDDF_Date( \*UDDF , "", "2005-10-10");
#		print UDDF "					<price currency=\"USD\">125.00</price>\n";
#		print UDDF "					<shop id=\"TankShop\">\n";
##										<!-- information about the shop where the tank was bought -->
#		print UDDF "						<name>TankShop</name>\n";
#		print UDDF "					</shop>\n";
#		print UDDF "				</purchase>\n";
#		print UDDF "				<nextservicedate>\n";
##									<!-- date of next service interval -->
#		WriteUDDF_Date( \*UDDF , "", "2010-10-10");
#		print UDDF "				</nextservicedate>\n";
		print UDDF "				<notes>\n";
		print UDDF "					<para>\n";
		print UDDF "						Tank Material: ".$::tanks{$tankID}{Type}."\n";
		print UDDF "						Tank Defaults:\n";
		print UDDF "						- Pressure: ".$::tanks{$tankID}{DefPressure}."Bar \n";
		print UDDF "						- O2: ".$::tanks{$tankID}{Oxygen}."%\n";
		print UDDF "						- He: ".$::tanks{$tankID}{Helium}."%\n";
		print UDDF "					</para>\n";
		print UDDF "				</notes>\n";
		if ($::tanks{$tankID}{Type} ne "None") {
			print UDDF "				<tankmaterial>".$tankMaterialConversion{$::tanks{$tankID}{Type}}."</tankmaterial>\n";
		}
#								<!-- Volume of the tank used in cubicmetres [m^3] Ñ not in litres, as UDDF uses SI units! -->
		print UDDF "				<tankvolume>".sprintf("%.3f",$::tanks{$tankID}{Volume} / 1000)."</tankvolume>\n";
		print UDDF "			</tank>\n";
	}
}

### Create UDDF Equipment Watches Section
sub WriteUDDF_Diver_Equipment_Watches {
	# Parameters:
    
	local *UUDF = shift;
#							<!-- diving watch -->
	print UDDF "			<watch id=\"roberts_diving_watch\">\n";
	print UDDF "				<name>Tigershark diving watch</name>\n";
	print UDDF "				<link ref=\"man-NeptunWatches\" />\n";
	print UDDF "				<model>Tigershark</model>\n";
	print UDDF "				<serialnumber>007</serialnumber>\n";
	print UDDF "				<purchase>\n";
	WriteUDDF_Date( \*UDDF , "", "1969-09-13");
	print UDDF "					<price currency=\"USD\">90.00</price>\n";
	print UDDF "					<shop id=\"WatchShop\">\n";
	print UDDF "						<name>Watch Shop</name>\n";
	print UDDF "					</shop>\n";
	print UDDF "				</purchase>\n";
	print UDDF "			</watch>\n";
}

### Create UDDF Equipment Section
sub WriteUDDF_Diver_Equipment {
	# Parameters:
    
	local *UUDF = shift;
#	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
    
	print UDDF "			<equipment>\n";
#							<!-- listing of all parts of equipment of the ownwe of the UDDF file -->
#	WriteUDDF_Diver_Equipment_BCDs( \*UDDF );
	WriteUDDF_Diver_Equipment_DiveComputers( \*UDDF );
#	WriteUDDF_Diver_Equipment_Regulators( \*UDDF );
	WriteUDDF_Diver_Equipment_Suits( \*UDDF );
	WriteUDDF_Diver_Equipment_Tanks( \*UDDF );
#	WriteUDDF_Diver_Equipment_Watches( \*UDDF );
#							<!-- Here more descriptions of parts of equipment can be given. Of course, several -->
#							<!-- regulators, tanks, masks etc. can be given. -->
	print UDDF "		</equipment>\n";
	
}

### Create UDDF Equipment Section
sub WriteUDDF_Diver_Medical {
	# Parameters:
    
	local *UUDF = shift;

	print UDDF "		<medical>\n";
#							<!-- For Each examination, repeat the next set -->
	print UDDF "			<examination id=\"ex-01\">\n";
	WriteUDDF_Date( \*UDDF , "", "2003-04-12");
#	print UDDF "				<doctor id=\"doctorDusel\">";
#	print UDDF "					<personal>\n";
#	print UDDF "						<firstname>Diego</firstname>\n";
#	print UDDF "						<lastname>Dusel</lastname>\n";
#	print UDDF "						<honorific>Dr.</honorific>\n";
#	print UDDF "						<sex>male</sex>\n";
#	print UDDF "						<birthdate>\n";
##											<!-- if date of birth is known it can be given here -->
#	print UDDF "						</birthdate>\n";
#	print UDDF "					</personal>\n";
#	print UDDF "					<address>\n";
#	print UDDF "						<street>Duddlestr. 34</street>\n";
#	print UDDF "						<city>Acity</city>\n";
#	print UDDF "						<postcode>54321</postcode>\n";
#	print UDDF "						<country>New Mexico, USA</country>\n";
#	print UDDF "					</address>\n";
#	print UDDF "					<contact>\n";
#	print UDDF "						<language>English</language>\n";
#	print UDDF "						<phone>01234/987654</phone>\n";
##										<!-- no mobile phone, neither email address nor homepage known -->
#	print UDDF "					</contact>\n";
#	print UDDF "				</doctor>\n";
#	print UDDF "				<examinationresult>passed</examinationresult>\n";
	print UDDF "				<notes>\n";
	print UDDF "					<para>\n";
	print UDDF "						".$::diver{MedicalInfo}."\n";
	print UDDF "					</para>\n";
#	print UDDF "					<link ref=\"img_flatfoot\"/>\n";
	print UDDF "				</notes>\n";
	print UDDF "			</examination>\n";
#	print UDDF "			<examination>\n";
#	WriteUDDF_Date( \*UDDF , "", "2004-04-20");
##								<!-- following a cross reference to the doctor examining -->
##								<!-- because information about the person is given above -->
#	print UDDF "				<link ref=\"doctorDusel\"/>\n";
#	print UDDF "				<examinationresult>passed</examinationresult>\n";
#	print UDDF "			</examination>\n";
	print UDDF "		</medical>\n";
}

### Create UDDF Diver Section
sub WriteUDDF_Diver {
	my $gender;
	# Parameters:
    
	local *UUDF = shift;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);

	print UDDF "	<diver>\n";
	print UDDF "		<owner id=\"".CleanID($::diver{Nickname})."\">\n";
	print UDDF "			<personal>\n";
	print UDDF "				<firstname>".CleanUDDF($::diver{Firstname})."</firstname>\n";
	print UDDF "				<middlename>".CleanUDDF($::diver{Middlename})."</middlename>\n";
	print UDDF "				<lastname>".CleanUDDF($::diver{Lastname})."</lastname>\n";
	print UDDF "				<honorific>".CleanUDDF($::diver{License})."</honorific>\n";
	if ( $::diver{Gender} == "M" ) {
		$gender = "male";
	} else {
		$gender = "female";
	}
	print UDDF "				<sex>".$gender."</sex>\n";
	WriteUDDF_Date( \*UDDF , "birthdate", $::diver{Birthday});
	if ( $::diver{Passport} ne "" ) {
		print UDDF "				<passport>".CleanUDDF($::diver{Passport})."</passport>\n";
	}
	if ( ( defined $::diver{DAN} ) && ( $::diver{DAN} ne "" ) ) {
		print UDDF "				<membership organisation=\"DAN\" memberid=\"".CleanUDDF($::diver{DAN})."\" />\n";
	} 
	if ( defined $::diver{Organization} ) {
		print UDDF "				<membership organisation=\"".CleanUDDF($::diver{Organization})."\" />\n";
	} 
	print UDDF "			</personal>\n";
	print UDDF "			<address>\n";
	print UDDF "				<street>".CleanUDDF($::diver{Street})."</street>\n";
	print UDDF "				<city>".CleanUDDF($::diver{City})."</city>\n";
	print UDDF "				<postcode>".CleanUDDF($::diver{Zip})."</postcode>\n";
	print UDDF "				<province>".CleanUDDF($::diver{State})."</province>\n";
	print UDDF "				<country>".CleanUDDF($::diver{Country})."</country>\n";
	print UDDF "			</address>\n";
	print UDDF "			<contact>\n";
	print UDDF "				<language>".CleanUDDF($::diver{Language})."</language>\n";
	print UDDF "				<phone>".CleanUDDF($::diver{Phone})."</phone>\n";
	print UDDF "				<mobilephone>".CleanUDDF($::diver{Phone})."</mobilephone>\n";
#	print UDDF "				<fax>0123/456780</fax>\n";
	print UDDF "				<email>".CleanUDDF($::diver{EMail})."</email>\n";
#	print UDDF "				<homepage>".$diver{HomePage}."</homepage>\n";
	print UDDF "			</contact>\n";
	
	WriteUDDF_Diver_Equipment( \*UUDF );
	WriteUDDF_Diver_Medical( \*UUDF );
	WriteUDDF_Diver_Education( \*UUDF );
#	WriteUDDF_Diver_DivePermissions( \*UUDF );
#	WriteUDDF_Diver_DiveInsurance( \*UUDF );
	print UDDF "		<notes>\n";
#	print UDDF "			<link ref=\"img_my_equipment_and_me_1978\"/>\n";
#	print UDDF "			<link ref=\"img_my_first_divecomputer_1992\"/>\n";
#	print UDDF "			<link ref=\"img_dive_1111-our_group\"/>\n";
#	print UDDF "			<link ref=\"audio_talk_for_celebration of dive_888\"/>\n";
#	print UDDF "			<link ref=\"video_party_dive_1000\"/>\n";
	print UDDF "		</notes>\n";
	print UDDF "	</owner>\n";
	
	WriteUDDF_Diver_Buddies( \*UUDF );
	
	print UDDF "	</diver>\n";
}

### Create UDDF Divesites Section
sub WriteUDDF_Dive_Sites {
# Parameters:

	local *UUDF = shift;
	my $placeID;

		print UDDF "	<divesite>\n";
		my @sortedDiveSites = sort { $a <=> $b } keys %::places;
    	foreach my $placeID ( @sortedDiveSites ) {
			print UDDF "		<site id=\"ds-".CleanID($placeID)."\">\n";
			print UDDF "			<name>".CleanUDDF($::places{$placeID}{Name})."</name>\n";
#			print UDDF "			<aliasname></aliasname>\n";
#			print UDDF "			<link/>\n";			#	(for cross-referencing <divebase> elements)
#			$env	= ($waterType & 0b0000_0010) ? "Wreck" : (($waterType & 0b0000_0100) ? "Cave" : "Open Water");	# Bit 1-2: 0 - open water / 1 - wreck / 2 - cave
#			Allowed keywords are: river-spring, pool, hyperbaric-chamber, under-ice, other.
			if ($::places{$placeID}{Type} eq "Open Water") {
				if ($::places{$placeID}{Water} eq "Sea") {
					print UDDF "			<environment>ocean-sea</environment>\n";							
				} else {
					print UDDF "			<environment>lake-quarry</environment>\n";							
				}
			} elsif ($::places{$placeID}{Type} eq "Cave") {
				print UDDF "			<environment>cave-cavern</environment>\n";							
			} else {
				print UDDF "			<environment>unknown</environment>\n";							
			}
			print UDDF "			<geography>\n";
#			print UDDF "				<address>\n";
#			print UDDF "					<street></street>\n";
#			print UDDF "					<city></city>\n";
#			print UDDF "					<postcode></postcode>\n";
#			print UDDF "					<country></country>\n";
#			print UDDF "					<province></province>\n";
#			print UDDF "				</address>\n";
			print UDDF "				<location>".CleanUDDF($::places{$placeID}{Location})."</location>\n";
			if ( $::places{$placeID}{Latitude} ne "0" ) {
				print UDDF "				<latitude>".CleanUDDF($::places{$placeID}{Latitude})."</latitude>\n";
			}
			if ( $::places{$placeID}{Longitude} ne "0" ) {
				print UDDF "				<longitude>".CleanUDDF($::places{$placeID}{Longitude})."</longitude>\n";
			}
			if ( $::places{$placeID}{Altitude} ne "0" ) {
				print UDDF "				<altitude>".CleanUDDF($::places{$placeID}{Altitude})."</altitude>\n";
			}
			if ( $::places{$placeID}{TimeZone} ne "0" ) {
				print UDDF "				<timezone>".CleanUDDF($::places{$placeID}{TimeZone})."</timezone>\n";
			}
			print UDDF "			</geography>\n";
			if ( $::places{$placeID}{Rating} ne 0 ) {
				print UDDF "			<rating><ratingvalue>".CleanUDDF($::places{$placeID}{Rating})."</ratingvalue></rating>\n";
			}
			print UDDF "			<sitedata>\n";
			if ($::places{$placeID}{Water} eq "Sea") {
				print UDDF "				<density>1030.0</density>\n";	#	<!-- salt water -->
			} else {
				print UDDF "				<density>1000.0</density>\n";	#	<!-- fresh water -->	
			}
			if ($::places{$placeID}{Depth} ne 0 ) {
				print UDDF "				<maximumdepth>".CleanUDDF($::places{$placeID}{Depth})."</maximumdepth>\n";
			}
			print UDDF "			</sitedata>\n";
			print UDDF "			<notes>\n";
			print UDDF "				<para>\n";
			print UDDF "					Type: ".CleanUDDF($::places{$placeID}{Type})."\n";		
			print UDDF "					Water: ".CleanUDDF($::places{$placeID}{Water})."\n";
			if ( $::places{$placeID}{Description} ne "" ) {
				print UDDF "					Description: ".CleanUDDF($::places{$placeID}{Description})."\n";
			}
			print UDDF "				</para>\n";
			print UDDF "			</notes>\n";
			print UDDF "		</site>\n";
		}
		print UDDF "	</divesite>\n";
}

### Create UDDF DiveTrips Section
sub WriteUDDF_Dive_Trips {
# Parameters:

	local *UUDF = shift;
	my $localCountry = $::diver{Country};
	my $currentCountry;
	my $diveSite;

#	I considered all dives in different countries than the diver's origin country to be a divetrip.
	print UDDF "	<divetrip>\n";
	#	Traverse the dive hash in numeric order
 	my @sortedDiveNrs = sort { $a <=> $b } keys %::logbookEntry;
    foreach my $diveNr ( @sortedDiveNrs ) {
    	$diveSite = $::logbookEntry{$diveNr}{Location}{ID};
    }	
	print UDDF "	</divetrip>\n";

}

### Create UDDF GasDefinitions Section
sub WriteUDDF_GasDefinitions {
	# Parameters:

	local *UUDF = shift;
	my ($mix, $mixName, $nitrogen);
 
	print UDDF "	<gasdefinitions>\n";

	foreach $mix (sort keys %::mixtures) {
		if ( $mix eq 'air' ) {
			$nitrogen = 79;
		} elsif ( $mix eq 'oxygen' ) {
			$nitrogen = 0;
		} else {
			$nitrogen = 100 - $::mixtures{$mix}{Oxygen} - $::mixtures{$mix}{Helium} ;
		}
		print UDDF "		<mix id=\"mix-".$mix."\">\n";
		print UDDF "			<name>".$mix."</name>\n";
		print UDDF "			<o2>0.".$::mixtures{$mix}{Oxygen}."</o2>\n";
		print UDDF "			<n2>0.".$nitrogen."</n2>\n";
		print UDDF "			<he>0.".$::mixtures{$mix}{Helium}."</he>\n";
		print UDDF "			<ar>0.0</ar>\n";
		print UDDF "			<h2>0.0</h2>\n";
		print UDDF "		</mix>\n";
	}

	print UDDF "	</gasdefinitions>\n";

}

### Create UDDF Generator Section
sub WriteUDDF_Generator {
	# Parameters:

	local *UUDF = shift;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);

	print UDDF "	<generator>\n";
#        <!-- "fingerprint" of the program generating the UDDF file -->
#        <!-- description of the software which generates this UDDF file -->
	print UDDF "		<name>".CleanUDDF($progname)."</name>\n";
	print UDDF "		<type>converter</type>\n";
	print UDDF "		<manufacturer id=\"man-".CleanID("van-Eerd.net")."\">\n";
	print UDDF "			<name>".CleanUDDF("van-Eerd.net")."</name>\n";
	print UDDF "			<address>\n";
	print UDDF "				<street>Trappistenborch 12</street>\n";
	print UDDF "				<city>Rosmalen</city>\n";
	print UDDF "				<postcode>5241 KX</postcode>\n";
	print UDDF "				<country>Netherlands</country>\n";
	print UDDF "			</address>\n";
	print UDDF "			<contact>\n";
	print UDDF "				<language>English</language>\n";
	print UDDF "				<phone>+31735230844</phone>\n";
	print UDDF "				<mobilephone>+31614432194</mobilephone>\n";
	print UDDF "				<email>rob\@van-Eerd.net</email>\n";
	print UDDF "				<homepage>http://van-Eerd.net</homepage>\n";
	print UDDF "			</contact>\n";
	print UDDF "		</manufacturer>\n";
	print UDDF "		<version>0.1</version>\n";
#        <!-- date and time of generation of the UDDF file -->
	printf UDDF "		<datetime>%4d-%02d-%02dT%02d:%02d:%02d</datetime>\n", $year+1900,$mon+1,$mday,$hour,$min,$sec;
	print UDDF "	</generator>\n";	
}

#### Create UDDF Makers Section
sub WriteUDDF_Makers {
# Parameters:
	local *UUDF = shift;
	my ($manID);

	print UDDF "	<maker>\n";
	foreach $manID (sort keys %::manufacturers) {
		print UDDF "		<manufacturer id=\"man-".CleanID(sprintf("%03d",$::manufacturers{$manID}{ID}))."\">\n";
		print UDDF "			<name>".CleanUDDF($::manufacturers{$manID}{Name})."</name>\n";
#		print UDDF "			<address>Some Address</address>\n";
#		print UDDF "			<contact>Some ContactDetails</contact>\n";
		print UDDF "		</manufacturer>\n";
	}
	print UDDF "	</maker>\n";	

}

#### Create UDDF Media Section
sub WriteUDDF_Media {
# Parameters:

	local *UUDF = shift;

#    <mediadata>
#        <!-- declaration of all audio, image, and video files for later cross-referencing inside the UDDF file -->
#    </mediadata>

}

### Create UDDF ProfileData Section: "ApplicationData"
sub WriteUDDF_Dive_ProfileData_ApplicationData {
# Parameters:

	local *UUDF = shift;

#		print UDDF "				<applicationdata>\n";
#		print UDDF "					<decotrainer />\n";
#		print UDDF "					<hargikas />\n";
#		print UDDF "					<heinrichsweikamp />\n";
#		print UDDF "					<tausim />\n";
#		print UDDF "					<tautabu />\n";
#		print UDDF "				</applicationdata>\n";

}

### Create UDDF ProfileData Section: "InformationBeforeDive"
sub WriteUDDF_Dive_ProfileData_InformationBeforeDive {
# Parameters:
	local *UUDF = shift;
	my $diveNr = shift;
	
	my ($startMix, $diveBuddies);
	
		print UDDF "				<informationbeforedive>\n";
		print UDDF "					<link ref=\"ds-".CleanID($::logbookEntry{$diveNr}{Location}{ID})."\" />\n";
		if ($::logbookEntry{$diveNr}{Profile}{DiveComputer} ne "None") {
			print UDDF "					<link ref=\"dc-".CleanID(sprintf("%02d",$::logbookEntry{$diveNr}{Profile}{DiveComputer}{ID}))."\" />\n";
		}
		if ($::logbookEntry{$diveNr}{Buddies} ) {
			$diveBuddies = $::logbookEntry{$diveNr}{Buddies};
			$diveBuddies =~ s/,/#/g;	
			$diveBuddies =~ s/\(/#/g;	
			$diveBuddies =~ s/\)/#/g;	
			$diveBuddies =~ s/\&/#/g;	
			print UDDF "					<link ref=\"bd-".CleanID(trim($_))."\" />\n"	foreach split('#', $diveBuddies);
		}
		print UDDF "					<divenumber>".CleanUDDF($diveNr)."</divenumber>\n";
#		print UDDF "					<internaldivenumber>77</internaldivenumber>\n";	# <!-- with this dive computer only 77 dives were made -->
		WriteUDDF_Date( \*UDDF , "", $::logbookEntry{$diveNr}{Date});
		if ( $::logbookEntry{$diveNr}{DiveAirTemp} ne "" ) {
			print UDDF "					<airtemperature>".CleanUDDF(273 + $::logbookEntry{$diveNr}{DiveAirTemp})."</airtemperature>\n";		# <!-- 23 ¡C -->
		}

		print UDDF "					<surfaceintervalbeforedive>\n";
		if ( ( $TSStartDive eq "" ) || ( $SurfaceInterval > (24*3600) ) ) { #	Surface Interval > 24hr, means "Infinity" 
			print UDDF "						<infinity/>\n";
		} else {
			print UDDF "						<passedtime>".sprintf("%d",$SurfaceInterval)."</passedtime>\n";
		}
		$TSStartDive = $::logbookEntry{$diveNr}{Date};
		print UDDF "					</surfaceintervalbeforedive>\n";
		
#		print UDDF "					<altitude>0.0</altitude>\n";

##										<!-- Allowed keywords are: beach-shore, pier, small-boat, charter-boat, live-aboard, barge, landside, hyperbaric-facility, other. >
#		print UDDF "					<platform>beach-shore</platform>\n";

##										<!-- Allowed keywords are: sightseeing, learning (if the owner of the UDDF file is a student diving with an instructor on an educational dive), teaching (if the owner of the UDDF file is an instructor teaching a student), research, photography-videography, spearfishing (unfortunately, even nowadays not frowned upon :-( ), proficiency, work, other.>
#		print UDDF "					<purpose>sightseeing</purpose>\n";

##										<!-- Allowed keywords are: not-specified, rested, tired, exhausted.>
		print UDDF "					<stateofrestbeforedive>not-specified</stateofrestbeforedive>\n";

#		print UDDF "					<alcoholbeforedive>\n";
#		print UDDF "					    <drink>\n";
#		print UDDF "					    	<name>Tequila Sunrise</name>\n";
##										        <!-- not periodically taken -->
#		print UDDF "					    	<periodicallytaken>no</periodicallytaken>\n";
##												<!-- taken an hour before the dive -->
#		print UDDF "					    	<timespanbeforedive>3600.0</timespanbeforedive>\n";
##										        <!-- no additional comments concerning this drink -->
#		print UDDF "					    </drink>\n";
#		print UDDF "					</alcoholbeforedive>\n";

#		print UDDF "					<medicalbeforedive>\n";
#		print UDDF "						<medicine>\n";
#		print UDDF "							<name>Paracetamol</name>\n";
##												<!-- not periodically taken -->
#		print UDDF "							<periodicallytaken>no</periodicallytaken>\n";
##												<!-- taken five hours before the dive -->
#		print UDDF "							<timespanbeforedive>18000.0</timespanbeforedive>\n";
#		print UDDF "							<notes>\n";
#		print UDDF "								<para>\n";
#		print UDDF "									Taken five hours before the planned start of the dive because\n";
#		print UDDF "									a severe headache was coming up...\n";
#		print UDDF "								</para>\n";
#		print UDDF "							</notes>\n";
#		print UDDF "						</medicine>\n";
#		
#		print UDDF "					</medicalbeforedive>\n";

#		if ( "dived without a suite") {
#			print UDDF "					<nosuit />\n";
#		}

#		print UDDF "					<price currency=\"EUR\">0.0</price>\n";	#	<!-- 123,45 Euro -->

		WriteUDDF_Dive_ProfileData_InformationBeforeDive_InputProfile( \*UDDF, $diveNr );
		WriteUDDF_Dive_ProfileData_InformationBeforeDive_PlannedProfile( \*UDDF, $diveNr );

#		print UDDF "					<surfacepressure>102000.0</surfacepressure>\n";	#	<!-- surface pressure of 1020 mbar -->
#										<!-- Allowed keywords are: open-scuba, rebreather, surface-supplied, chamber, experimental, other.>
#		print UDDF "					<apparatus>open-scuba</apparatus>\n";
		print UDDF "				</informationbeforedive>\n";
}

### Create UDDF ProfileData Section: "InformationBeforeDive" - "InputProfile"
sub WriteUDDF_Dive_ProfileData_InformationBeforeDive_InputProfile {
# Parameters:
	local *UUDF = shift;
	my $diveNr = shift;
	my $startMix;
	
	print UDDF "					<inputprofile>\n";
# Waypoint: Start of Dive
	print UDDF "						<waypoint>\n";
	print UDDF "							<depth>0.0</depth>\n";
	print UDDF "							<divetime>0.0</divetime>\n";
	if ($::logbookEntry{$diveNr}{Equipment}{Tank}{0}{Helium} > 0) {
		$startMix = sprintf("trimix%02d%02d",$::logbookEntry{$diveNr}{Equipment}{Tank}{0}{Oxygen},$::logbookEntry{$diveNr}{Equipment}{Tank}{0}{Helium});
	} elsif ($::logbookEntry{$diveNr}{Equipment}{Tank}{0}{Oxygen} eq 21) {
		$startMix = "air";
	} else {
		$startMix = sprintf("ean%02d",$::logbookEntry{$diveNr}{Equipment}{Tank}{0}{Oxygen});
	}
	print UDDF "							<switchmix ref=\"mix-".$startMix."\"/>\n";
	print UDDF "						</waypoint>\n";
# Waypoint: at the bottom/end of the Descent
	print UDDF "						<waypoint>\n";
	print UDDF "							<depth>".CleanUDDF($::logbookEntry{$diveNr}{DiveMaxDepth})."</depth>\n";
	print UDDF "							<divetime>".CleanUDDF( sprintf("%.1f",($::logbookEntry{$diveNr}{DiveMaxDepth} / 10 * 60) ) )."</divetime>\n";
	print UDDF "						</waypoint>\n";
# Waypoint: at the start of the ascent
	print UDDF "						<waypoint>\n";
	print UDDF "							<depth>".CleanUDDF($::logbookEntry{$diveNr}{DiveMaxDepth})."</depth>\n";
	print UDDF "							<divetime>".CleanUDDF( sprintf("%.1f",($::logbookEntry{$diveNr}{DiveTime} - ( $::logbookEntry{$diveNr}{DiveMaxDepth} / 10 * 60 ) ) ) )."</divetime>\n";
	print UDDF "						</waypoint>\n";
# Waypoint: End of Dive
	print UDDF "						<waypoint>\n";
	print UDDF "							<depth>0.0</depth>\n";
	print UDDF "							<divetime>".CleanUDDF($::logbookEntry{$diveNr}{DiveTime})."</divetime>\n";
	print UDDF "						</waypoint>\n";
	print UDDF "					</inputprofile>\n";
}

### Create UDDF ProfileData Section: "InformationBeforeDive" - "PlannedProfile"
sub WriteUDDF_Dive_ProfileData_InformationBeforeDive_PlannedProfile {
# Parameters:
	local *UUDF = shift;
	my $diveNr = shift;
	my ($mix, $lastMix, $tankID, $oxygen, $helium);

#	Implement traversing through the "TEC-Schedule" from $::logbookEntry{$diveNr}{Schedule}
	if (defined $::logbookEntry{$diveNr}{Schedule} ) {
#		if ( $diveNr ) {
#			printf("Tec-Schedule exists for DiveNr: %d\n",$diveNr);
#		}
		print UDDF "					<plannedprofile>\n";
		print UDDF "						<waypoint>\n";
		print UDDF "							<depth>0.0</depth>\n";
		print UDDF "							<divetime>0.0</divetime>\n";
		if ($::logbookEntry{$diveNr}{Equipment}{Tank}{0}{Helium} > 0) {
			$mix = sprintf("trimix%02d%02d",$::logbookEntry{$diveNr}{Equipment}{Tank}{0}{Oxygen},$::logbookEntry{$diveNr}{Equipment}{Tank}{0}{Helium});
		} elsif ($::logbookEntry{$diveNr}{Equipment}{Tank}{0}{Oxygen} eq 21) {
			$mix = "air";
		} else {
			$mix = sprintf("ean%02d",$::logbookEntry{$diveNr}{Equipment}{Tank}{0}{Oxygen});
		}
		print UDDF "						<switchmix ref=\"mix-".$mix."\"/>\n";
		$lastMix = $mix;
		print UDDF "						</waypoint>\n";
	 	my @sortedSamples = sort { $a <=> $b } keys %{ $::logbookEntry{$diveNr}{Schedule} };
    	foreach my $runTime ( @sortedSamples ) {
			print UDDF "						<waypoint>\n";
			print UDDF "							<depth>".sprintf("%.1f",$::logbookEntry{$diveNr}{Schedule}{$runTime}{Depth})."</depth>\n";
			print UDDF "							<divetime>".sprintf("%.1f",$runTime)."</divetime>\n";
			$tankID = $::logbookEntry{$diveNr}{Schedule}{$runTime}{Tank};
			$helium = $::logbookEntry{$diveNr}{Equipment}{Tank}{$tankID}{Helium};
			$oxygen = $::logbookEntry{$diveNr}{Equipment}{Tank}{$tankID}{Oxygen};
			if ( defined $oxygen ) {
				if ($::logbookEntry{$diveNr}{Equipment}{Tank}{$tankID}{Helium} > 0) {
					$mix = sprintf("trimix%02d%02d",$::logbookEntry{$diveNr}{Equipment}{Tank}{$tankID}{Oxygen},$::logbookEntry{$diveNr}{Equipment}{Tank}{$tankID}{Helium});
				} elsif ($::logbookEntry{$diveNr}{Equipment}{Tank}{$tankID}{Oxygen} == 21) {
					$mix = "air";
				} else {
					$mix = sprintf("ean%02d",$::logbookEntry{$diveNr}{Equipment}{Tank}{$tankID}{Oxygen});
				}
				if ( $mix ne $lastMix ) {
					print UDDF "						<switchmix ref=\"mix-".$mix."\"/>\n";
					$lastMix = $mix;
				}
			}
			print UDDF "						</waypoint>\n";
    	}
		print UDDF "					</plannedprofile>\n";
	}
}

### Create UDDF ProfileData Section: "InformationBeforeDive"
sub WriteUDDF_Dive_ProfileData_TankData {
# Parameters:
	local *UUDF = shift;
	my $diveNr = shift;
	my ($nrTanks, $tankID, $mix, $tankPressureBegin, $tankPressureEnd, $tankVolume);
	
	for (my $tankNr = 0; $tankNr lt $::logbookEntry{$diveNr}{Equipment}{NrTanks}; $tankNr++ ) {
		if ($::logbookEntry{$diveNr}{Equipment}{Tank}{$tankNr}{Oxygen} eq 21) {
			$mix = "air";
		} else {
			$mix = "ean".$::logbookEntry{$diveNr}{Equipment}{Tank}{$tankNr}{Oxygen};
		}

		$tankID				= $::logbookEntry{$diveNr}{Equipment}{Tank}{$tankNr}{ID}{ID};
		$tankVolume			= $::tanks{$tankID}{Volume} / 1000;
		$tankPressureBegin	= $::logbookEntry{$diveNr}{Equipment}{Tank}{$tankNr}{PressureIn} * 100000 ;	# Converted to Pascal
		$tankPressureEnd	= $::logbookEntry{$diveNr}{Equipment}{Tank}{$tankNr}{PressureOut} * 100000 ;	# Converted to Pascal

		print UDDF "				<tankdata>\n";
		print UDDF "					<link ref=\"mix-".$mix."\"/>\n";
		print UDDF "					<tankvolume>".sprintf("%.3f",$tankVolume)."</tankvolume>\n";
#		if ( not(($::logbookEntry{$diveNr}{Equipment}{Tank}{$tankNr}{PressureIn} == 200 ) && ($::logbookEntry{$diveNr}{Equipment}{Tank}{$tankNr}{PressureOut} == 0) ) ) {
			print UDDF "					<tankpressurebegin>".sprintf("%.1f",$tankPressureBegin)."</tankpressurebegin>\n";
			print UDDF "					<tankpressureend>".sprintf("%.1f",$tankPressureEnd)."</tankpressureend>\n";
			$consumption += $tankPressureBegin - $tankPressureEnd;
#		}
#			<!-- because the breathing consumption volume is given - in [m^3/s] units! - -->
#			<!-- the end pressure information can be omitted -->
#			<!-- 20 litres / minute ^= 0.00033333... m^3/s -->
#		print UDDF "					<breathingconsumptionvolume>0.000333333333</breathingconsumptionvolume>\n";
		print UDDF "				</tankdata>\n";
	}
}

### Create UDDF ProfileData "Samples" Section
sub WriteUDDF_Dive_ProfileData_Samples {
# Parameters:

	local *UUDF = shift;
	my $diveNr = shift;
	my $startMix;
	my $alarm;
	
	$DCUsed = 0;
	
# If both StartOfDive-Marker and EndOfDive-Marker are set, it means a dive without a profile, hence no samples required
	if ( ( $::logbookEntry{$diveNr}{Profile}{0}{Marker}{StartDive} ne 1) || ($::logbookEntry{$diveNr}{Profile}{0}{Marker}{EndDive} ne 1) ) {
#	} else {
		$DCUsed = 1;
		print UDDF "				<samples>\n";
	 	my @sortedSamples = sort { $a <=> $b } keys %{ $::logbookEntry{$diveNr}{Profile} };
    	foreach my $runTime ( @sortedSamples ) {
			print UDDF "					<waypoint>\n";
#			Currently, following alarms are allowed: ascent, breath, deco, error, link, microbubbles, rbt, skincooling, surface
#			If a dive computer sets a "stage", or a numerical value for a given alarm, it can be set here as an attribute level.
#			Examples:
#			<alarm>ascent</alarm>				<!-- ascent too fast -->
#			<alarm level="2.0">breath</alarm>	<!-- breathing too high, stage 2 - although the dive computer sets this value -->
#												<!-- as an integer, UDDF uses a real number here -->
			if ( $::logbookEntry{$diveNr}{Profile}{$runTime}{Marker}{SlowWarning} == 1) {
				$alarm = "ascent";
			} elsif ( $::logbookEntry{$diveNr}{Profile}{$runTime}{Marker}{BreathWarning} == 1) {
				$alarm = "breath";
			} elsif ( $::logbookEntry{$diveNr}{Profile}{$runTime}{Marker}{DecoAlarm} == 1) {
				$alarm = "deco";
			} elsif ( $::logbookEntry{$diveNr}{Profile}{$runTime}{Marker}{GeneralWarning} == 1) {
				$alarm = "error";
			} elsif ( $::logbookEntry{$diveNr}{Profile}{$runTime}{Marker}{EndDive} == 1) {
				$alarm = "surface";
			} else {
				$alarm="";
			}
			if ( $alarm ne "") {
				print UDDF "						<alarm>".$alarm."</alarm>\n";
			}
			print UDDF "						<depth>".sprintf("%.1f",$::logbookEntry{$diveNr}{Profile}{$runTime}{Depth})."</depth>\n";
			print UDDF "						<divetime>".sprintf("%.1f",$runTime)."</divetime>\n";
			if ( $::logbookEntry{$diveNr}{Profile}{$runTime}{Marker}{StartDive} == 1) {
				if ($::logbookEntry{$diveNr}{Equipment}{Tank}{0}{Oxygen} eq 21) {
					$startMix = "air";
				} else {
					$startMix = "ean".$::logbookEntry{$diveNr}{Equipment}{Tank}{0}{Oxygen};
				}
				print UDDF "						<switchmix ref=\"mix-".$startMix."\"/>\n";
			}
			print UDDF "					</waypoint>\n";
		}			
		print UDDF "				</samples>\n";
	}
}

### Create UDDF ProfileData Section
sub WriteUDDF_Dive_ProfileData_InformationAfterDive {
# Parameters:

	local *UUDF = shift;
	my $diveNr = shift;
	
	my %Current=  (
		"---"			=> "no-current",
		"None"			=> "no-current", 			#	ADL uses one level less, so I left out the "very-mild-current"
		"Light"			=> "mild-current",			#	no problem to swim against it
		"Moderate"		=> "moderate-current", 
		"Strong"		=> "hard-current",			#	even for trained divers it is possible to swimm against it only for a short period of time
		"Very Strong"	=> "very-hard-current"		#	it is not possible to swim against it, even trained divers cannot
	);
	my %Workload =  (
		"---"			=> "not-specified",
		"Resting"		=> "resting", 
		"Light"			=> "light",
		"Moderate"		=> "moderate", 
		"Severe"		=> "severe",
		"Exhausting"	=> "exhausting"
	);
	
	
		print UDDF "				<informationafterdive>\n";
#		print UDDF "					<anysymptoms>\n";
#		print UDDF "						<notes>\n";
#		print UDDF "							<para>\n";
##										    	    <!-- here description of possibly occurred DCS symptoms -->
#		print UDDF "							</para>\n";
#		print UDDF "						</notes>\n";
#		print UDDF "					</anysymptoms>\n";
		print UDDF "					<lowesttemperature>".CleanUDDF($::logbookEntry{$diveNr}{DiveWaterTemp})."</lowesttemperature>\n";
		print UDDF "					<greatestdepth>".CleanUDDF($::logbookEntry{$diveNr}{DiveMaxDepth})."</greatestdepth>\n";
		print UDDF "					<visibility>".CleanUDDF($::logbookEntry{$diveNr}{DiveVisibility})."</visibility>\n";
		print UDDF "					<current>".$Current{$::logbookEntry{$diveNr}{DiveCurrent}}."</current>\n";
		print UDDF "					<diveduration>".CleanUDDF($::logbookEntry{$diveNr}{DiveTime})."</diveduration>\n";	#	<!-- duration of dive 65 min -->
		$TSEndDive = CalculateDiveEnd( $TSStartDive, $::logbookEntry{$diveNr}{DiveTime} );
#TODO	Average Depth: Calculate Average Dive Depth from Samples
		if ( $::logbookEntry{$diveNr}{AvgDepth} ) {
			print UDDF "					<averagedepth>".CleanUDDF($::logbookEntry{$diveNr}{AvgDepth})."</averagedepth>\n";
		}
		if ( $DCUsed eq 1) {
			print UDDF "					<diveplan>dive-computer</diveplan>\n";	# Allowed keywords are: none, table, dive-computer, another-diver.
		} else {
			print UDDF "					<diveplan>none</diveplan>\n";	# Allowed keywords are: none, table, dive-computer, another-diver.
		}
		print UDDF "					<equipmentused>\n";	# Here reference links to the equipment used with this dive
		if (defined $::logbookEntry{$diveNr}{Equipment}{Suit}{ID} ) {
			print UDDF "						<link ref=\"suit-".$::logbookEntry{$diveNr}{Equipment}{Suit}{ID}."\" />\n";
		}
		for (my $tankNr = 1; $tankNr <= $::logbookEntry{$diveNr}{Equipment}{NrTanks}; $tankNr++ ) {
			print UDDF "						<link ref=\"tank-".$::tanks{sprintf("%02d",$tankNr)}{ID}."\" />\n";
		}
		if ( $DCUsed eq 1) {
			print UDDF "						<link ref=\"dc-".$::logbookEntry{$diveNr}{Profile}{DiveComputer}{ID}."\" />\n";
		}
		print UDDF "					</equipmentused>\n";
#		print UDDF "					<equipmentmalfunction>none</equipmentmalfunction>\n";
#		Pressuredrop: Add pressuredrop (air used during the dive) by calculating from pressure start / end.
#		Pressuredrop: For multiple tanks, calculate pressuredrop by traversing through tanks used.
		print UDDF "					<pressuredrop>".sprintf("%.1f",$consumption)."</pressuredrop>\n";	#	<!-- 160 bar -->
#		print UDDF "					<problems>equalisation</problems>\n";
#TODO	Check if this can be populated from the info in $::logbookEntry{$diveNr}{Type} and $::diveTypes
#		print UDDF "					<program>recreation</program>\n";
#		print UDDF "					<thermalcomfort>comfortable</thermalcomfort>\n";
		print UDDF "					<workload>".$Workload{$::logbookEntry{$diveNr}{DiveWorkload}}."</workload>\n";
#		print UDDF "					<desaturationtime>63840.0</desaturationtime>\n";	#	<!-- 17 h 44 min -->
#		print UDDF "					<noflighttime>34200.0</noflighttime>\n";	#	<!--  9 h 30 min -->
		print UDDF "					<notes>\n";
		print UDDF "						<para>\n";	# Here text written into the logbook -->
		print UDDF "							".CleanUDDF($::logbookEntry{$diveNr}{Notes})."\n";
		my $diveTypeList = "";
#		Determine whether the DiveType is a String or a Hash. String can be "published" a Hash needs to be traversed.
		my $diveTypes = $::logbookEntry{$diveNr}{Type};
		if (ref($diveTypes) eq "HASH") {
			for my $diveType (keys %$diveTypes)
			{
				if ($diveTypeList eq "") {
					$diveTypeList = $diveType;	
				} else {
					$diveTypeList = $diveTypeList.", ".$diveType;
				}
			}
		} else {
			$diveTypeList = $::logbookEntry{$diveNr}{Type};							
		}
		if ( $diveTypeList ne "" ) {
			print UDDF "							DiveType(s): ".CleanUDDF($diveTypeList)."\n";
			print UDDF "							Buddy/Buddies: ".CleanUDDF($::logbookEntry{$diveNr}{Buddies})."\n";
		}
		print UDDF "						</para>\n";
#											<!-- here any number of images, audio, and video files can be inserted via <link ref="..."/>  -->
#		print UDDF "						<link ref=\"img_from_dive123\"/>\n";
		print UDDF "					</notes>\n";
#										<!-- personal rating of the dive -->
		if ( $::logbookEntry{$diveNr}{DiveRating} ne 0 ) {
			print UDDF "					<rating>\n";
			print UDDF "						<ratingvalue>".CleanUDDF($::logbookEntry{$diveNr}{DiveRating})."</ratingvalue>\n";
			print UDDF "					</rating>\n";
		}
		print UDDF "				</informationafterdive>\n";
}

### Create UDDF ProfileData Section
sub WriteUDDF_Dive_ProfileData {
# Parameters:

	local *UUDF = shift;
	my $repGrp = 0;
	my $repGrpContinued;

	print UDDF "	<profiledata>\n";
#        <!-- description of the individual dive profiles -->
#            <!-- the first dive within a <repetitiongroup> section should have an infinite surface interval -->
#TODO	RepetitionGroups: Implement RepetitionGroups by "Day". All Dives on the same day will belong to the same Repetition Group.
#		Maybe also dives on consequtive Days.
#TODO	RepetitionGroups: In case multiple days diving in a row can be detected, this might be identified as a DiveTrip
#	Traverse the dive hash in numeric order
 	my @sortedDiveNrs = sort { $a <=> $b } keys %::logbookEntry;
    foreach my $diveNr ( @sortedDiveNrs ) {
    	
#		Calculate Surface Interval based on end-time of previous dive and start-time of current dive
		if ( ( $TSStartDive ne "" ) && ( $TSEndDive ne "" ) ) {
			$TSStartDive = $::logbookEntry{$diveNr}{Date};
			$SurfaceInterval = CalculateSurfaceInterval( $TSStartDive, $TSEndDive );
		}
		
#		Determine use of "RepetitionGroup"
#		if ($::logbookEntry{$diveNr}{Profile}{DiveComputer} ne "None") {
#			print UDDF "					<link ref=\"dc-".CleanID(sprintf("%02d",$::logbookEntry{$diveNr}{Profile}{DiveComputer}{ID}))."\" />\n";
#		}

		if ( ( $SurfaceInterval eq "" ) || ( ( $::logbookEntry{$diveNr}{Profile}{DiveComputer} eq "None" ) && (left($TSStartDive,10) gt left($TSEndDive,10) ) ) || ( $SurfaceInterval >= (24*3600) ) ) {
			if ( $diveNr > 1 ) {
				print UDDF "		</repetitiongroup>\n";
			}
			print UDDF "		<repetitiongroup id=\"RG-".sprintf("%05d",$repGrp++)."\">\n";
			$repGrpContinued = 0;
		} else {
			$repGrpContinued = 1;
		}

		print UDDF "			<dive id=\"dive-".CleanID($diveNr)."\">\n";

#		WriteUDDF_Dive_ProfileData_ApplicationData( \*UUDF, $diveNr );
		WriteUDDF_Dive_ProfileData_InformationBeforeDive( \*UUDF, $diveNr );
		$consumption = 0;
		WriteUDDF_Dive_ProfileData_TankData( \*UUDF, $diveNr );
		WriteUDDF_Dive_ProfileData_Samples( \*UUDF, $diveNr );
		WriteUDDF_Dive_ProfileData_InformationAfterDive( \*UUDF, $diveNr );
		print UDDF "			</dive>\n";
	}
	print UDDF "		</repetitiongroup>\n";
	print UDDF "	</profiledata>\n";

}

### Create UDDF TableGeneration Section
sub WriteUDDF_TableGeneration {
# Parameters:

	local *UUDF = shift;

#    <tablegeneration>
#        <!-- parameters for the generation of different table types -->
#    </tablegeneration>

}

### Create UDDF file
sub WriteUDDF {
	# Parameters:

	my ( $fileName ) = @_;

	open (UDDF, ">$fileName") || die "Can't open $fileName: $!";
	
	print UDDF "<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>\n";
#	WriteUDDF_DocType( \*UDDF );
	print UDDF "<uddf xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.streit.cc/uddf/3.2 http://www.streit.cc/uddf/3.2/uddf_3.2.2.xsd\" xmlns=\"http://www.streit.cc/uddf/3.2/\" version=\"3.2.2\">\n";
	WriteUDDF_Generator( \*UUDF );
#	WriteUDDF_Media( \*UUDF );					# Not implemented yet
	WriteUDDF_Makers( \*UUDF );
#	WriteUDDF_Business( \*UDDF );				# Not implemented yet
	WriteUDDF_Diver( \*UUDF );
	WriteUDDF_Dive_Sites( \*UUDF );
	WriteUDDF_Dive_Trips( \*UDDF );				# Not implemented yet
	WriteUDDF_GasDefinitions( \*UUDF );
#	WriteUDDF_Deco_Model( \*UDDF );				# Not implemented yet
	WriteUDDF_Dive_ProfileData( \*UUDF );
#	WriteUDDF_TableGeneration( \*UUDF );		# Not implemented yet
#	WriteUDDF_Dive_ComputerControl( \*UUDF );	# Not implemented yet
	print UDDF "</uddf>\n";
	close( UDDF );
}

#### Create UDDF .......... Section
#sub WriteUDDF_.......... {
#	# Parameters:
#
#	local *UUDF = shift;
#
#}

1;
	# We need the 1; at the end because when a module loads Perl checks to see that the module returns a true value to ensure it loaded OK. You could put any true value at the end (see Code::Police) but 1 is the convention.