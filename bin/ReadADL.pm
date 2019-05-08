package ReadADL;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use DateTime::Locale;

$VERSION     = 1.00;
@ISA         = qw(Exporter);
	# See perlboot for all the gory details on what @ISA is or just use it as shown.
@EXPORT      = ();
	# @EXPORT contains a list of functions that we export by default, in this case nothing. Generally the less you export by default using @EXPORT the better. This avoids accidentally clashing with functions defined in the script using the module. If a script wants a function let it ask.
@EXPORT_OK   = qw(ReadTables ReadDives);
	# @EXPORT_OK contains a list of functions that we export on demand so we export &func1 &func2 only if specifically requested to. Use this in preference to just blindly exporting functions via @EXPORT. You can also export variables like $CONFIG provided they are globals not lexicals scoped with my (read declare them with our or use vars).
%EXPORT_TAGS = ( Both    => [qw(&ReadTables &ReadDives)]);
	# %EXPORT_TAGS. For convenience we define two sets of export tags. The ':DEFAULT' tag exports only &func1; the ':Both' tag exports both &func1 &func2. This hash stores labels pointing to array references. In this case the arrays are anonymous.


# Reverse Engineering information
# Number of Records (Logboek + Profile) is stored at offset 0x4C
# Record pointers start at offset 0x4E
my $palmDBHeader = 0x4C;
my $palmDBRecords;
my $palmDBRecPtrs = 0x4E;

# Useful Record Pointers
my ($dvrRec1Start, $dvrRec2Start, $dvrRec3Start, $locRec1Start, $locRec2Start, $suitRecStart, $dcRecStart, $tankRecStart, $buddyRecStart, $diveTypeRecStart);

# Mentioned (but unused) Record Pointers
my ($divePageRecStart, $generalRecStart, $computerRecStart, $gpsRecStart, $plannerRecStart, $diveListRecStart);
	
my $diveNr;				# The sequence number of the dive.
my $manufacturerID = 0;
my $dummy;
my $buddyCounter = 0;



###############################################################################
# Perl trim function to extend the hash of gas Mixtures
sub AddMixture {
	my $oxygen = shift;
	my $helium = shift;
	my $mix = "";

	if ( $helium > 0 ) {
		$mix = sprintf("trimix%02d%02d", $oxygen, $helium);
	} elsif ( $oxygen == 21 ) {
		$mix = "air";
	} elsif ( $oxygen == 100 ) {
		$mix = "oxygen";
	} else {
		$mix = sprintf("ean%02d", $oxygen);	
	}
	if ( not defined $::mixtures{$mix} ) {
		$::mixtures{$mix} = {
			Oxygen => $oxygen,
			Helium => $helium
		}
	}
}


###############################################################################
# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
{
my $string= shift;
$string=~ s/^\s+//;
$string=~ s/\s+$//;
return $string;
}


### Read "AquaPalm-TableDB - Rec#1-3 - Diver Info Records 1-3" from input file
sub ConvertADLDate {
	# Parameters:
	# - HexDate		- ADL Date in Hex Format
	
	my ( $HexDate ) = @_;
	my $adlBaseDate = DateTime->new( year => 1904, month => 1, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'floating', locale => 'nl' );
	my ($ADLDate, $ADLDateSeconds);
	
	# $dvrBirthDaySeconds should be 1849219200 for my birthday of August 7th, 1962
	# String appears to be reversed aka "Network / Big-Endian"
	$ADLDateSeconds = unpack('N',$HexDate);
	$ADLDate = $adlBaseDate->add( seconds => $ADLDateSeconds );
	return($ADLDate);
}

### Read "AquaPalm-TableDB - Rec#1-3 - Diver Info Records 1-3" from input file
sub ReadDiverRec {
	# Parameters:
	# - fileHandle		- Handle of File to read
	# - RecStart	- Fileposition to start reading from
	
	my ( $fileHandle, $RecStart, $debug ) = @_;
	
	my $dvrGender;		# Gender
	my $dvrBirthday;	# Birthday
	my $dvrLic;			# License
	my $firstName;		# Firstname
	my $familyName;		# Familyname / Lastname
	my $middleName;		# Middle Initial or name
	my $nickName;		# Nickname or Alias
	my $motherName;		# Mother's Maiden name
	my $placeOfBirth;	# Place of birth
	my $medicalInfo;	# Additional Medical Info;
	
	my $dvrBirthdayHex;
	
	# Positioning filepointer to start of Diver Record #1
	seek ($fileHandle, $RecStart, 0);
	
	### Read "AquaPalm-TableDB - Rec#1 - Diver Info Record 1" from input file
	# Reading the DiverInfo
	read ($fileHandle, $dvrGender, 1);
	read ($fileHandle, $dvrBirthdayHex, 4);
	$dvrBirthday = ConvertADLDate($dvrBirthdayHex);
	
	$dvrLic = <$fileHandle>; chomp $dvrLic;                      
	$firstName = <$fileHandle>; chomp $firstName;                      
	$familyName = <$fileHandle>; chomp $familyName;                      
	$middleName = <$fileHandle>; chomp $middleName;                      
	$nickName = <$fileHandle>; chomp $nickName;                      
	$motherName = <$fileHandle>; chomp $motherName;                      
	$placeOfBirth = <$fileHandle>; chomp $placeOfBirth;                      
	$medicalInfo = <$fileHandle>; chomp $medicalInfo;                      
	
 	$::diver{Gender}		= $dvrGender;
	$::diver{Birthday}	= $dvrBirthday->ymd('-');
	$::diver{License}		= $dvrLic;
	$::diver{Firstname}	= $firstName;
	$::diver{Lastname}	= $familyName;
	$::diver{Middlename}	= $middleName;
	$::diver{Nickname}	= $nickName;
	$::diver{MotherName}	= $motherName;
	$::diver{PlaceBirth}	= $placeOfBirth;
	$::diver{MedicalInfo}	= $medicalInfo;
	
	### Read "AquaPalm-TableDB - Rec#2 - Diver Info Record 2" from input file
	my ($street, $city, $state, $zip, $country);			# Complete Addressinfo
	my $citizen;		# Citizenship
	my $passport;		# Passport Number
	my $language;		# Language
	my $phone;			# Phone Number
	my $email;			# E-Mail address
	
	#	# Positioning filepointer to start of Diver Record #2
	#	seek ($fileHandle, $RecStart, 0);
	
	$street = <$fileHandle>;	chomp $street;                      
	$city = <$fileHandle>;		chomp $city;                      
	$state = <$fileHandle>;		chomp $state;                      
	$zip = <$fileHandle>;		chomp $zip;                      
	$country = <$fileHandle>;	chomp $country;                      
	$citizen = <$fileHandle>;	chomp $citizen;                      
	$passport = <$fileHandle>;	chomp $passport;                      
	$language = <$fileHandle>;	chomp $language;                      
	$phone = <$fileHandle>;		chomp $phone;                      
	$email = <$fileHandle>;		chomp $email;
	
	$::diver{Street}		= $street;
	$::diver{City}		= $city;
	$::diver{State}		= $state;
	$::diver{Zip}			= $zip;
	$::diver{Country}		= $country;
	$::diver{CitizenShip}	= $citizen;
	$::diver{Passport}	= $passport;
	$::diver{Language}	= $language;
	$::diver{Phone}		= $phone;
	$::diver{EMail}		= $email;
	
	### Read "AquaPalm-TableDB - Rec#3 - Diver Info Record 3" from input file
	my $units;			# Preferred units
	my $daysTemplate;	# Number of days use last dive as default template
	my ($userDefinedType, $userDefType1, $userDefType2, $userDef1, $userDef2);
	my $dan;			# DAN Member number
	my $organization;	# Dive Organization
	my $level;			# Diver level
	my $cCard;			# Credit Card
	
	#	# Positioning filepointer to start of Diver Record #2
	#	seek ($fileHandle, $RecStart, 0);
	
	read ($fileHandle, $units, 1);
	# Process preferred units:
	# Bit 0: 0 - m / 1 - ft
	# Bit 1: 0 - bar / 1 - PSI
	# Bit 2: 0 - ∞C / 1 - ∞F
	# Bit 3: 0 - kg / 1 - lbs
	# Bit 4-5: GPS format  0 - D∞M'S" / 1 - D∞M.mm' / 2 - D.ddd∞
	$::units{Depth}			= ($units & 0b00000001) ? "Feet" : "Meter";
	$::units{Pressure}		= ($units & 0b00000010) ? "PSI" : "Bar";
	$::units{Temperature}	= ($units & 0b00000100) ? "∞F" : "∞C";
	$::units{Weight}		= ($units & 0b00001000) ? "lbs" : "Kg";
	$::units{GPS}			= ($units & 0b00010000) ? "D∞M.mm'" : ( ($units & 0b00100000) ? "D.ddd∞" : "D.ddd∞");
	
	read ($fileHandle, $daysTemplate, 1);
	read ($fileHandle, $dummy, 2);
	# Process preferred units:
	# Bit 0-1: field 1
	# Bit 2-3: field 2
	#     0 - string field
	#     1 - check box
	read ($fileHandle, $userDefinedType, 1);
	$userDefType1		= ($userDefinedType & 0b00000001) ? "Check Box" : "String";
	$userDefType2		= ($userDefinedType & 0b00000100) ? "Check Box" : "String";
	
	$userDef1 = <$fileHandle>; chomp $userDef1;                      
	$userDef2 = <$fileHandle>; chomp $userDef2;                      
	$dan = <$fileHandle>; chomp $dan;                      
	$organization = <$fileHandle>; chomp $organization;                      
	$level = <$fileHandle>; chomp $level;                      
	$cCard = <$fileHandle>; chomp $cCard;                      
	
	$::diver{DAN}				= $dan;
	$::diver{Organization}	= $organization;
	$::diver{Level}			= $level;
	$::diver{CreditCard}		= $cCard;
	
	if ($debug) {
		print Dumper(\%::diver);
		print Dumper(\%::units);
 	}	 	
}

### Read "AquaPalm-TableDB - Rec#4 - Locations" from input file
sub ReadLocationRec {
	# Parameters:
	# - fileHandle		- Handle of File to read
	# - RecStart	- Fileposition to start reading from
	# - debug			- indicates whether output is required, for debugging
	
	my ( $fileHandle, $RecStart, $debug ) = @_;
	my $siteNameOffset;	# Offset to Site names
	my $siteCounter = 0;	# Counter of sites / Index to Dive Site hash 
	my $siteName;		# - SiteName
	
	seek ($fileHandle, $RecStart, 0);
	read ($fileHandle, $siteNameOffset, 2);
	$siteNameOffset = unpack('n',$siteNameOffset);
	
	read ($fileHandle, $dummy, $siteNameOffset - 2);
	
	seek ($fileHandle, $RecStart + $siteNameOffset, 0);
	
	$siteName = <$fileHandle>; chomp $siteName;                      
	while ($siteName ne '') {
		$::locations{$siteCounter++} = $siteName;                      
		$siteName = <$fileHandle>; chomp $siteName;
	}
	
	if ($debug) {
		print Dumper(\%::locations);
	}
}

### Read "AquaPalm-TableDB - Rec#5 - Places" from input file
sub ReadPlacesRec {
	# Parameters:
	# - fileHandle		- Handle of File to read
	# - RecStart		- Fileposition to start reading from
	# - RecEnd			- Fileposition to read to
	# - debug			- indicates whether output is required, for debugging
	
	my ( $fileHandle, $RecStart, $RecEnd, $debug ) = @_;
	my $placeBlockLength;
	my $placeID;		# - Place ID
	my $longitude;		# - Longitude	deg. *1000000  <0 = west; >0 = east
	my $latitude;		# - Latitude	deg. *1000000  <0 = south; >0 = north  
	my $altitude;		# - Altitude	meter
	my $depth;			# - Depth		meter *10 max. depth of dive site  
	my $waterType;		# - Type
	my $water;			# 	- Sea / Fresh
	my $env;			#	- Open Water / Wreck, Cave
	my $locationRef;
	my $timeZone;		# - Timezone
	my $rating;			# - Rating (1 = worst ... 5 = best)
	my $placeName;		# - PlaceName
	my $description;	# - Description
	my $placeCounter = 0;
	
	
	seek ($fileHandle, $RecStart, 0);
	while (tell($fileHandle) < $RecEnd) {
		read ($fileHandle, $placeID, 2);			$placeID		= unpack('n', $placeID);
		$placeID = sprintf("%05d",$placeID);
		read ($fileHandle, $longitude, 4);			$longitude		= unpack('N', $longitude) / 1000000;
#		if ( $longitude < 0 ) {
#			$longitude = 'W'.$longitude;
#		} else {
#			$longitude = 'E'.$longitude;
#		}
		read ($fileHandle, $latitude, 4);			$latitude		= unpack('N', $latitude) / 1000000;
#		if ( $latitude < 0 ) {
#			$latitude = 'S'.$latitude;
#		} else {
#			$latitude = 'N'.$latitude;
#		}
		read ($fileHandle, $altitude, 2);			$altitude		= unpack('n', $altitude);
		read ($fileHandle, $depth, 2);				$depth 			= unpack('N', $depth) / 10;
		
#		printf ("FileHandle: %x\n", tell($fileHandle));
		read ($fileHandle, $waterType, 1);			$waterType		= unpack('c', $waterType);	# - Type (Sea / Fresh, Open Water / Wreck, Cave)
#		printf("WaterType: %08b\n",$waterType);
		$water	= ($waterType & 0b0000_0001) ? "Fresh Water" : "Sea" ;											# Bit 0: 0 - sea / 1 - fresh water
		$env	= ($waterType & 0b0000_0010) ? "Wreck" : (($waterType & 0b0000_0100) ? "Cave" : "Open Water");	# Bit 1-2: 0 - open water / 1 - wreck / 2 - cave
		
		read ($fileHandle, $dummy, 1); 														# Reserved (forr future use?)
		
		read ($fileHandle, $locationRef, 1);		$locationRef	= unpack('c', $locationRef);
		read ($fileHandle, $timeZone, 1);			$timeZone		= unpack('c', $timeZone);
		read ($fileHandle, $rating, 1);				$rating 		= unpack('c', $rating);		#	$rating = "*" * $rating;
		$placeName = <$fileHandle>; chomp $placeName;
#		print "PlaceName: ".$placeName."\n";
		$description = <$fileHandle>; chomp $description;
		$placeCounter += 1;
		$placeBlockLength = 19+length($placeName)+length($description)+2 ;
		if ( $placeBlockLength % 2 != 0) {
			read ($fileHandle, $dummy, 1);
		}
		$placeCounter += 1;
		
		$::places{$placeID}{ID}				= $placeID;
		$::places{$placeID}{WaterType}		= $waterType;
		$::places{$placeID}{Longitude}		= $longitude;
		$::places{$placeID}{Latitude}		= $latitude;
		$::places{$placeID}{Altitude}		= $altitude;
		$::places{$placeID}{Depth}			= $depth;
		$::places{$placeID}{Water}			= $water;
		$::places{$placeID}{Type}			= $env;
		$::places{$placeID}{Location}		= $::locations{$locationRef};
		#		$::places{$placeID}{Location}		= $locationRef;
		$::places{$placeID}{TimeZone}		= $timeZone;
		$::places{$placeID}{Rating}			= $rating;
		$::places{$placeID}{Name}			= $placeName;
		$::places{$placeID}{Description}	= $description;
		
	}
	
	if ($debug) {
		print Dumper(\%::places);	
	}
}

### Read "AquaPalm-TableDB - Rec#6 - Suits" from input file
#TODO Change usage of the key to the %suits-hash. Name as used in ADL is key / $suitCounter = ID
sub ReadSuitRec {
	# Parameters:
	# - fileHandle		- Handle of File to read
	# - RecStart		- Fileposition to start reading from
	# - RecEnd			- Fileposition to read to
	# - debug			- indicates whether output is required, for debugging
	
	my ( $fileHandle, $RecStart, $RecEnd, $debug ) = @_;
	my $suitCounter = 0;
	my $suitID;			# - SuitID
	my $suitType;		# - SuitType (0 - Swim Suit, 1 - Dive Skin, 2 - Wet Suit, 3 - Semi Dry Suit, 4 - Dry Suit, 5 - Hot Water Suit, 6 - Other)
	my %suitTypes = ("0" => "Swim Suit", "1" => "Dive Skin", "2" => "Wet Suit", "3" => "Semi Dry Suit", "4" => "Dry Suit", "5" => "Hot Water Suit", "6" => "Other");
	my $suitWeight;		# - SuitWeight
	my $suitName;		# - SuitName
	my $suitBlockLength;
	my $suitActive;
	
	seek ($fileHandle, $RecStart, 0);
	while (tell($fileHandle) < $RecEnd) {
		read ($fileHandle, $suitID, 1);				$suitID = sprintf("%02d", unpack('w', $suitID) );
		read ($fileHandle, $suitType, 1);			$suitType = unpack('w', $suitType);			$suitType = $suitTypes{$suitType};
		read ($fileHandle, $suitWeight, 1);			$suitWeight = unpack('w', $suitWeight);		$suitWeight /= 4;
		$suitName = <$fileHandle>; chomp $suitName;
		$suitBlockLength = 3+length($suitName)+1 ;
		if ( $suitBlockLength % 2 != 0) {
			read ($fileHandle, $dummy, 1);
		}
		$suitCounter += 1;
		
		if ( substr($suitName,0,1) eq '.' ) {
			$suitName = substr($suitName,1);
			$suitActive = "No";
		} else {
			$suitActive = "Yes";
		}
		$::suits{$suitID}{ID}		= $suitID;
		$::suits{$suitID}{Type}		= $suitType;
		$::suits{$suitID}{Weight}	= $suitWeight;
		$::suits{$suitID}{Name}		= $suitName;
		$::suits{$suitID}{Active}	= $suitActive;
	}
	
	if ($debug) {
		print Dumper(\%::suits);
	}
}

### Read "AquaPalm-TableDB - Rec#7 - Dive Computers" from input file
#TODO Change usage of the key to the %diveComputers-hash. Name as used in ADL is key / $dcCounter = ID
sub ReadDiveComputerRec {
	# Parameters:
	# - fileHandle		- Handle of File to read
	# - RecStart		- Fileposition to start reading from
	# - RecEnd			- Fileposition to read to
	# - debug			- indicates whether output is required, for debugging
	
	my ( $fileHandle, $RecStart, $RecEnd, $debug ) = @_;
	my $dcCounter = 0;
	my $dcID;				# - DiveComputerID
	my $dcManufacturer;		# - DiveComputerManufacturer
	my $dcModel;			# - DiveComputerModel
	my $dcSerial;			# - DiveComputerSerial
	my $dcBlockLength;
	
	seek ($fileHandle, $RecStart, 0);
	while (tell($fileHandle) < $RecEnd) {
		read ($fileHandle, $dcID, 1);				$dcID	= unpack('c', $dcID);
		read ($fileHandle, $dummy, 7);
		$dcManufacturer = <$fileHandle>; chomp $dcManufacturer;
		$dcModel = <$fileHandle>; chomp $dcModel;
		$dcSerial = <$fileHandle>; chomp $dcSerial;
		$dcBlockLength = 8+length($dcManufacturer)+length($dcModel)+length($dcSerial)+3 ;
		if ( $dcBlockLength % 2 != 0) {
			read ($fileHandle, $dummy, 1);
		}
		$dcCounter += 1;
		
		$::manufacturers{$manufacturerID}{ID}	= $manufacturerID;
		$::manufacturers{$manufacturerID}{Name}	= $dcManufacturer;
		
		$::diveComputers{$dcID}{ID}				= sprintf("%02d",$dcID);
		$::diveComputers{$dcID}{Manufacturer}	= $dcManufacturer;
		$::diveComputers{$dcID}{ManufacturerID}	= $manufacturerID;
		$::diveComputers{$dcID}{Model}			= $dcModel;
		$::diveComputers{$dcID}{Serial}			= $dcSerial;

		$manufacturerID += 1;
	}
	
	if ($debug) {
		print Dumper(\%::diveComputers);
	}
}

### Read "AquaPalm-TableDB - Rec#8 - Tanks" from input file
#TODO Change usage of the key to the %tanks-hash. Name as used in ADL is key / $tankCounter = ID
sub ReadTankRec {
	# Parameters:
	# - fileHandle		- Handle of File to read
	# - RecStart		- Fileposition to start reading from
	# - RecEnd			- Fileposition to read to
	# - debug			- indicates whether output is required, for debugging
	
	my ( $fileHandle, $RecStart, $RecEnd, $debug ) = @_;
	my $tankID;				# - TankID
	my $tankVolumeType;		# - TankVolumeType [liter * 100] / [>0 = steel tank / <0 = aluminium tank ]
	my $tankVolume;			# - Volume
	my $tankType;			# - Type
	my $tankDefPressure;	# - tankDefPressure [bar * 10]
	my $tankO2;				# - TankOxygene
	my $tankHe;				# - TankHelium
	my $tankName;			# - TankName
	my $tankBlockLength;
	my $tankCounter = 0;
	
	seek ($fileHandle, $RecStart, 0);
	while (tell($fileHandle) < $RecEnd) {
		read ($fileHandle, $tankID, 1);				$tankID = sprintf("%02d",unpack('c', $tankID));
		read ($fileHandle, $tankVolumeType, 2);		$tankVolumeType = unpack('s>*', $tankVolumeType) / 100;		# 's>*' is used to process a "Big-Endian 16-bit signed integer"
		$tankType =  ($tankVolumeType == 0 ) ? "None" : (($tankVolumeType > 0) ? "Steel" : "Aluminium");
		$tankVolume = abs($tankVolumeType);
		read ($fileHandle, $tankDefPressure, 2);	$tankDefPressure = unpack('N', $tankDefPressure) / 10;	# - tankDefPressure [bar * 10]
		read ($fileHandle, $tankO2, 1);				$tankO2 = unpack('w', $tankO2);							# - TankOxygene
		read ($fileHandle, $tankHe, 1);				$tankHe = unpack('w', $tankHe);						# - TankHelium
		$tankName = <$fileHandle>; chomp $tankName;															# - TankName
		$tankBlockLength = 7+length($tankName)+1 ;
		if ( $tankBlockLength % 2 != 0) {
			read ($fileHandle, $dummy, 1);
		}
		$tankCounter += 1;
		
		$::tanks{$tankID}{ID}			= $tankID;
		$::tanks{$tankID}{Volume}		= $tankVolume;
		$::tanks{$tankID}{Type}			= $tankType;
		$::tanks{$tankID}{DefPressure}	= $tankDefPressure;
		$::tanks{$tankID}{Oxygen}		= $tankO2;
		$::tanks{$tankID}{Helium}		= $tankHe;
		$::tanks{$tankID}{Name}			= $tankName;
	}
	
	if ($debug) {
		print Dumper(\%::tanks);
	}
}

### Read "AquaPalm-TableDB - Rec#9 - Buddies" from input file
sub ReadBuddyRec {
	# Parameters:
	# - fileHandle		- Handle of File to read
	# - RecStart		- Fileposition to start reading from
	# - RecEnd			- Fileposition to read to
	# - debug			- indicates whether output is required, for debugging
	
	my ( $fileHandle, $RecStart, $RecEnd, $debug ) = @_;
	my $buddyCntr;			# - Number of Buddies
	my $buddyNick;			# - BuddyNick
	my $buddyName;			# - BuddyName
	my $buddyAddress;		# - BuddyAddress
	my $buddyRemarks;		# - BuddyRemarks
	my $buddyBlockLength;
	
	seek ($fileHandle, $RecStart, 0);
	read ($fileHandle, $buddyCntr, 2);
	while (tell($fileHandle) < $RecEnd) {
		$buddyNick = <$fileHandle>;		chomp $buddyNick;		# - BuddyNick
		$buddyName = <$fileHandle>;		chomp $buddyName;		# - BuddyNick
		$buddyAddress = <$fileHandle>;	chomp $buddyAddress;	# - BuddyNick
		$buddyRemarks = <$fileHandle>;	chomp $buddyRemarks;	# - BuddyNick
		$buddyCounter += 1;
		
		$buddyNick = trim($buddyNick);
		$::buddies{$buddyNick}{ID}		= $buddyCounter;
		$::buddies{$buddyNick}{Name}	= $buddyName;
		$::buddies{$buddyNick}{Address}	= $buddyAddress;
		$::buddies{$buddyNick}{Remarks}	= $buddyRemarks;
	}
	
	if ($debug) {
		print Dumper(\%::buddies);
	}
}

### Read "AquaPalm-TableDB - Rec#14 - DiveTypes" from input file
sub ReadDiveTypeRec {
	# Parameters:
	# - fileHandle		- Handle of File to read
	# - RecStart	- Fileposition to start reading from
	# - debug			- indicates whether output is required, for debugging
	
	my ( $fileHandle, $RecStart, $debug ) = @_;
	my ($diveTypeID, $diveTypeName) ;
	my $diveTypeBlockLength;
	
	seek ($fileHandle, $RecStart, 0);
	
	for (my $cntr = 0; $cntr <= 15; $cntr++) {
		read ($fileHandle, $diveTypeID, 1);		$diveTypeID	=  unpack('c',$diveTypeID);
		read ($fileHandle, $dummy, 3);
		$diveTypeName = <$fileHandle>; chomp $diveTypeName;
		
		$diveTypeBlockLength = 4+length($diveTypeName)+1 ;
		if ( $diveTypeBlockLength % 2 != 0) {
			read ($fileHandle, $dummy, 1);
		}
		
		$::diveTypes{$diveTypeID} = $diveTypeName;
	}
	
	if ($debug) {
		print Dumper(\%::diveTypes);
	}
}

### Read "AquaPalm-DiveDB - Rec#Even - LogbookEntry" from input file
sub ReadLogbookEntry {
	# Parameters:
	# - fileHandle		- Handle of File to read
	# - RecStart		- Fileposition to start reading from
	# - RecEnd			- Fileposition to read to
	# - debug			- indicates whether output is required, for debugging
	
	my ( $fileHandle, $RecStart, $RecEnd, $debug ) = @_;
	my ( $diveRecordPtr, $diveEquipmentPtr, $diveSchedulePtr, $diveNotesPtr );		# Each 2 bytes Unsigned Integer
	
	my $diveDate;			# actual date
	my $diveLocation;		# DB-Ref, location DB Lookup
	my $diveTime;			# Seconds (see profile)
	my $diveMaxDepth;		# meter * 10 (see profile)
	my $diveVisibility;		# meter * 10
	my $diveAirTemp;		# °C (dive computer if possible, see also: http://www.vedur.is/english/temperature_eng.html)
	my $diveWaterTemp;		# °C (dive computer if possible, see also: http://www.vedur.is/english/temperature_eng.html)
	my %hDiveCurrent		= (0, "---", 1, "None", 2, "Light", 3, "Moderate", 4, "Strong", 5, "Very Strong");
	my $diveCurrent;
	my %hDiveWorkload		= (0, "---", 1, "Resting", 2, "Light", 3, "Moderate", 4, "Severe", 5, "Exhausting");
	my $diveWorkload;
	my $diveWeather;		# 0 - N/A, 1 - sunny, 2 - partly sunny, 3 - foggy, 4 - partly cloudy, 5 - cloudy, 6 - overcasted, 7 - rainy, 8 - havy rain, 9 - stormy, 10 - thunderstorm, 11 - snow
	my $diveWind;			# 0 - calm, 1 - light air, 2 - light breeze, 3 - gentle breeze, 4 - moderate breeze, 5 - fresh breeze, 6 - strong breez, 7 - near gale, 8 - gale, 9 - strong gale, 10 - storm, 11 - violent storm, 12 - hurricane, 15 - N/A
	# (see also: http://www.vedur.is/english/wind_eng.html)
	my $seaConditions;		# 0 - N/A (wave height), 1 - calm (0m), 2 - ripples (0.3m), 3 - smooth (0.5m), 4 - slight (1m), 5 - moderate (2m), 6 - rough (3m), 7 - very rough (4m), 8 - high (6m)
	my $diveStatus;			# Bit 0: new dive, switch to edit mode
	my $diveRating;			# 1 (Worst) ... 5 (Best)  
	my $diveType;			# Bitwise reference to %diveTypes hash
	my $diveBuddies;
	
	my (%equipment, $suit, $weight, $tankOffset, $nrTanks, $tankCntr, $userDef1, $userDef2, $fillByte, $tankID, $tankName, $tankO2, $tankHe, $tankPressIn, $tankPressOut );
	my (%schedule, $scheduleEntries, $scheduleRuntime, $scheduleDepth, $scheduleTank);	# RunTime in Secs, Depth in M*10
	my $diveNotes;
	
	my ($diveDateHex, $diveDateSeconds);
	
	if ($debug) {
		printf("FilePointer: %x\n", $RecStart);	
	}
	
	seek ($fileHandle, $RecStart, 0);			# Jump to the start of the dive-information record.
	
	read ($fileHandle, $diveRecordPtr, 2);		$diveRecordPtr		=  unpack('n',$diveRecordPtr);
	read ($fileHandle, $diveEquipmentPtr, 2);	$diveEquipmentPtr	=  unpack('n',$diveEquipmentPtr);
	read ($fileHandle, $diveSchedulePtr, 2);	$diveSchedulePtr	=  unpack('n',$diveSchedulePtr);
	read ($fileHandle, $diveNotesPtr, 2);		$diveNotesPtr		=  unpack('n',$diveNotesPtr);
	read ($fileHandle, $dummy, 2);			# Skip "End of Reference Block" marker
	
	# Now, on to the DiveInformation section
	seek ($fileHandle, $RecStart + $diveRecordPtr, 0);			# Jump to the start of the dive-information record.
	if ($debug) {
		printf("FilePointer [DiveNr]: %x\n", tell($fileHandle));
	}
	read ($fileHandle, $diveNr, 2);				$diveNr		=  unpack('n',$diveNr);
	
#	if ( $diveNr == 69 ) {
#		$debug = 1;
#	} else {
#		$debug = 0;
#	}

#	if ($diveNr == 121) {
#		printf("FilePointer after reading DiveNr: %d\t %x\n", $diveNr, tell($fileHandle));
#	}
	
	$diveNr = sprintf("%05d",$diveNr);

	$::diveDebugInfo{$diveNr}{FileDiveInfoOffset}	= sprintf("0x%x", $RecStart);
	
#	Schedule included:	309, 310, 312, 313, 331
#	if ($diveNr == 396) { $debug = 1 };
	
	if ($debug) {
		printf("FilePointer [Date]: %x\n", tell($fileHandle));
	}
	read ($fileHandle, $diveDateHex, 4);
	$diveDate = ConvertADLDate($diveDateHex);
	$::logbookEntry{$diveNr}{Date}		= $diveDate->ymd('-')."T".sprintf("%02d",$diveDate->hour).":".sprintf("%02d",$diveDate->minute);
	$::logbookEntry{$diveNr}{DateRaw}	= $diveDate;
	
	if ($debug) {
		printf("FilePointer [Location]: %x\n", tell($fileHandle));
	}
	read ($fileHandle, $diveLocation, 2);				$diveLocation		=  unpack('n',$diveLocation);
	$diveLocation = sprintf("%05d",$diveLocation);
		$::logbookEntry{$diveNr}{Location}	= $::places{$diveLocation};
	
	if ($debug) {
		printf("FilePointer [DiveTime]: %x\n", tell($fileHandle));
	}
	read ($fileHandle, $diveTime, 2);				$diveTime		=  unpack('n',$diveTime);
	$::logbookEntry{$diveNr}{DiveTime}	= sprintf("%.1f",$diveTime);		# In Seconds as a foating number
	
	if ($debug) {
		printf("FilePointer [MaxDepth]: %x\n", tell($fileHandle));
	}
	read ($fileHandle, $diveMaxDepth, 2);				$diveMaxDepth		=  unpack('n',$diveMaxDepth);
	$::logbookEntry{$diveNr}{DiveMaxDepth}	= sprintf("%.1f",$diveMaxDepth / 10); # as a foating number
	
	if ($debug) {
		printf("FilePointer [Visibility]: %x\n", tell($fileHandle));
	}
	read ($fileHandle, $diveVisibility, 2);				$diveVisibility		=  unpack('n',$diveVisibility);
	$::logbookEntry{$diveNr}{DiveVisibility}	= $diveVisibility / 10;
	
	if ($debug) {
		printf("FilePointer [AirTemp]: %x\n", tell($fileHandle));
	}
	read ($fileHandle, $diveAirTemp, 1);				$diveAirTemp		=  unpack('c',$diveAirTemp);
	$::logbookEntry{$diveNr}{DiveAirTemp}	= $diveAirTemp;
	
	if ($debug) {
		printf("FilePointer [WaterTemp]: %x\n", tell($fileHandle));
	}
	read ($fileHandle, $diveWaterTemp, 1);				$diveWaterTemp		=  unpack('c',$diveWaterTemp);
	$::logbookEntry{$diveNr}{DiveWaterTemp}	= $diveWaterTemp;
	
	if ($debug) {
		printf("FilePointer [Current & Workload]: %x\n", tell($fileHandle));
	}
	read ($fileHandle, $dummy, 1);				
	$dummy = unpack('c', $dummy);	# DiveCurrent & DiveWorkload are put in a single byte
	$diveCurrent = ($dummy >> 4) & 0b00001111;
	$diveWorkload = $dummy & 0b00001111;
	$::logbookEntry{$diveNr}{DiveCurrent}		= $hDiveCurrent{$diveCurrent};
	$::logbookEntry{$diveNr}{DiveWorkload}	= $hDiveWorkload{$diveWorkload};
	
	if ($debug) {
		printf("FilePointer [Weather]: %x\n", tell($fileHandle));
	}
	read ($fileHandle, $diveWeather, 1);				$diveWeather		=  unpack('c',$diveWeather);
	$::logbookEntry{$diveNr}{DiveWeather}	= $diveWeather;
	
	if ($debug) {
		printf("FilePointer [Wind & Conditions]: %x\n", tell($fileHandle));
	}
	read ($fileHandle, $dummy, 1);				# diveWind & seaConditions are put in a single byte
	$diveWind = ($dummy >> 4) & 0b00001111;
	$seaConditions = $dummy & 0b00001111;
	$::logbookEntry{$diveNr}{Wind}			= $diveWind;
	$::logbookEntry{$diveNr}{SeaConditions}	= $seaConditions;
	
	if ($debug) {
		printf("FilePointer [New Dive?]: %x\n", tell($fileHandle));
	}
	read ($fileHandle, $dummy, 1);				# Bit 0: new dive (switch to edit mode)
	
	if ($debug) {
		printf("FilePointer [Rating]: %x\n", tell($fileHandle));
	}
	read ($fileHandle, $diveRating, 1);			$diveRating		=  unpack('c',$diveRating);				# 1 (worst) ... 5 (best)
	$::logbookEntry{$diveNr}{DiveRating}		= $diveRating;		# x '*';
	
	if ($debug) {
		printf("FilePointer [DiveType]: %x\n", tell($fileHandle));
	}
	my $diveTypeIndividual;
	read ($fileHandle, $diveType, 2);				$diveType		=  unpack('n',$diveType);
	for ( my $diveTypeID = 0; $diveTypeID <= 15; $diveTypeID++) {
		if ($diveType & 0b0000_0001) {													# If any of the bits is set, the type is added to the list
			$::logbookEntry{$diveNr}{Type}{$::diveTypes{$diveTypeID}} = 1;
		}
		$diveType = $diveType >> 1; 
	}
	if ( !defined($::logbookEntry{$diveNr}{Type}) ) {
		$::logbookEntry{$diveNr}{Type} = "Regular";
	}
	
	if ($debug) {
		printf("FilePointer [Filler]: %x\n", tell($fileHandle));
	}
	read ($fileHandle, $dummy, 8);
	
#	if ($debug || $diveNr == 121 || $diveNr == 122 || $diveNr == 222 || $diveNr == 223 || $diveNr == 224) {
#		printf("FilePointer [Buddies] for DiveNr: %d\t%x\n", $diveNr, tell($fileHandle));
#	}
	$diveBuddies = <$fileHandle>; chomp $diveBuddies;
	$::logbookEntry{$diveNr}{Buddies} = $diveBuddies;
	
#	If buddies exist, not listed in the "Buddies-hash", create them.
	$diveBuddies =~ s/,/#/g;	
	$diveBuddies =~ s/\(/#/g;	
	$diveBuddies =~ s/\)/#/g;	
	$diveBuddies =~ s/\&/#/g;

	my ($tmpBuddy, $tmpBuddyCntr, $tmpBuddyExists);
	foreach $tmpBuddy ( split('#', $diveBuddies) ) {
		$tmpBuddy = trim($tmpBuddy);
		if ( not(exists($::buddies{$tmpBuddy})) ) {
			$buddyCounter += 1;
			$::buddies{$tmpBuddy}{ID}		= $buddyCounter;
			$::buddies{$tmpBuddy}{Name}		= $tmpBuddy;
			$::buddies{$tmpBuddy}{Address}	= "";
			$::buddies{$tmpBuddy}{Remarks}	= "Buddy generated because he/she didn't exist in the buddy-table";
		}
	};
	                      
	
	# Now, on to the Equipment section
	seek ($fileHandle, $RecStart + $diveEquipmentPtr, 0);			# Jump to the start of the dive-equipment-information.
	if ($debug) {
		printf("FilePointer [Start of Equipment Section]: %x\n", tell($fileHandle));
	}
	read ($fileHandle, $suit, 1);				$suit		=  sprintf("%02d", unpack('c',$suit) );
	$::logbookEntry{$diveNr}{Equipment}{Suit}	= $::suits{$suit};
	
	read ($fileHandle, $weight, 1);				$weight		=  unpack('c',$weight);
	$::logbookEntry{$diveNr}{Equipment}{weight}	= $weight / 4;
	
	read ($fileHandle, $tankOffset, 2);			$tankOffset		=  unpack('n',$tankOffset);
	read ($fileHandle, $nrTanks, 1);			$nrTanks		=  unpack('c',$nrTanks);
	$::logbookEntry{$diveNr}{Equipment}{NrTanks}	= $nrTanks;
	
	$userDef1 = <$fileHandle>; chomp $userDef1;
	$::logbookEntry{$diveNr}{Equipment}{UserDefined1} = $userDef1;                      
	
	$userDef2 = <$fileHandle>; chomp $userDef2;
	$::logbookEntry{$diveNr}{Equipment}{UserDefined2} = $userDef2;                      
	
	seek ($fileHandle, $RecStart + $diveEquipmentPtr + $tankOffset, 0);			# Jump to the start of the dive-tank-information.
	if ($debug) {
		printf("FilePointer [Start of Tanks Section]: %x\n", tell($fileHandle));
	}
	for ($tankCntr = 0; $tankCntr lt $nrTanks; $tankCntr++) {
		read ($fileHandle, $tankID, 1);						$tankID		=  sprintf("%02d",unpack('c',$tankID));
		$::logbookEntry{$diveNr}{Equipment}{Tank}{$tankCntr}{ID}	= $::tanks{$tankID};
		read ($fileHandle, $dummy, 1);						# Fill byte
		read ($fileHandle, $tankO2, 1);						$tankO2 = unpack('w', $tankO2);			# - TankOxygene
		read ($fileHandle, $tankHe, 1);					$tankHe = unpack('w', $tankHe);		# - TankHelium
		$::logbookEntry{$diveNr}{Equipment}{Tank}{$tankCntr}{Oxygen}	= $tankO2;
		$::logbookEntry{$diveNr}{Equipment}{Tank}{$tankCntr}{Helium}	= $tankHe;
		read ($fileHandle, $tankPressIn, 2);				$tankPressIn = unpack('n', $tankPressIn) / 10;
		read ($fileHandle, $tankPressOut, 2);				$tankPressOut = unpack('n', $tankPressOut) / 10;
		$::logbookEntry{$diveNr}{Equipment}{Tank}{$tankCntr}{PressureIn}	= $tankPressIn;
		$::logbookEntry{$diveNr}{Equipment}{Tank}{$tankCntr}{PressureOut}	= $tankPressOut;
		AddMixture($tankO2, $tankHe);
	}
	
	# Now, on to the Tec-Schedule section
	seek ($fileHandle, $RecStart + $diveSchedulePtr, 0);			# Jump to the start of the dive-equipment-information.
	if ($debug) {
		printf("DiveNr: %d\tFilePointer [Start of Tec-Schedule Section]: %x\n", $diveNr, tell($fileHandle));
	}
	read ($fileHandle, $scheduleEntries, 1);				
	$scheduleEntries		=  unpack('c',$scheduleEntries);
	for (my $scheduleEntry = 0; $scheduleEntry < $scheduleEntries; $scheduleEntry++) {
		read ($fileHandle, $scheduleRuntime, 2);			$scheduleRuntime	=  unpack('n',$scheduleRuntime);
		read ($fileHandle, $scheduleDepth, 2);				$scheduleDepth		=  unpack('n',$scheduleDepth) / 10;
		read ($fileHandle, $scheduleTank, 1);				$scheduleTank		=  unpack('c',$scheduleTank);
		#		printf("ScheduleEntries: %i, CurrentEntry: %i\n", $scheduleEntries, $scheduleEntry);
		if ( ( $scheduleDepth != 0 ) && ( $scheduleDepth != 6544 ) && ( $scheduleEntry <= $scheduleEntries ) ) { 
			$::logbookEntry{$diveNr}{Schedule}{$scheduleRuntime}{Runtime}	= $scheduleRuntime;
			$::logbookEntry{$diveNr}{Schedule}{$scheduleRuntime}{Depth}		= $scheduleDepth;
			$::logbookEntry{$diveNr}{Schedule}{$scheduleRuntime}{Tank}		= $scheduleTank;
			if ($debug) {
				printf("ScheduleEntries: Runtime: %3i, Depth: %4.1f, Tank: %2i (At filelocation: %x)\n", $scheduleRuntime, $scheduleDepth, $scheduleTank, tell($fileHandle));
			}
		}
	}
	
	# Now, on to the DiveNotes section
	seek ($fileHandle, $RecStart + $diveNotesPtr, 0);			# Jump to the start of the dive-equipment-information.
	if ($debug) {
		printf("FilePointer [Start of Dive-Notes Section]: %x\n", tell($fileHandle));
	}
	$diveNotes = <$fileHandle>; chomp $diveNotes;
	$::logbookEntry{$diveNr}{Notes}		= $diveNotes;
	
	
	#	if ($debug) {
	#		print Dumper(\%logbookEntry);
	#	}
}

### Read "AquaPalm-DiveDB - Rec#Odd - DiveProfile" from input file
sub ReadDiveProfile {
	# Parameters:
	# - fileHandle		- Handle of File to read
	# - RecStart		- Fileposition to start reading from
	# - RecEnd			- Fileposition to read to
	# - debug			- indicates whether output is required, for debugging
	
	my ( $fileHandle, $RecStart, $RecEnd, $debug ) = @_;
	my $diveComputer;
	my (%profile, $profileRuntime, $lastProfileRuntime, $profileDepthMarker, $profileDepth, $profileMarker);
	my $currentTank = 0;
	$profileDepthMarker = 0;
	
	my $markerStartDive				= 0b0000_0000_0000_0000 ; 
	my $markerEndDive				= 0b1111_1111_1111_1111 ; 
	my $markerSlowWarning			= 0b1111_1111_1111_1110 ; 
	my $markerDecoAlarm				= 0b1111_1111_1111_1101 ; 
	my $markerDecoStart				= 0b1111_1111_1111_1100 ; 
	my $markerDecoStop				= 0b1111_1111_1111_1011 ; 
	my $markerDecoEnd				= 0b1111_1111_1111_1010 ; 
	my $markerBreathWarning			= 0b1111_1111_1111_1001 ; 
	my $markerTemperatureWarning	= 0b1111_1111_1111_1000 ; 
	my $markerStressWarnng			= 0b1111_1111_1111_0111 ; 
	my $markerWorkloadWarning		= 0b1111_1111_1111_0110 ; 
	my $markerGeneralWarnng			= 0b1111_1111_1111_0101 ; 
	my $markerBookMark5				= 0b1111_1111_1111_0100 ; 
	my $markerBookMark4				= 0b1111_1111_1111_0011 ; 
	my $markerBookMark3				= 0b1111_1111_1111_0010 ; 
	my $markerBookMark2				= 0b1111_1111_1111_0001 ; 
	my $markerBookMark1				= 0b1111_1111_1111_0000 ; 
	#	my $markerGSTank16				= 0b1111_1111_1110_1111 ; 
	#	my $markerGSTank15				= 0b1111_1111_1110_1110 ; 
	#	my $markerGSTank14				= 0b1111_1111_1110_1101 ; 
	#	my $markerGSTank13				= 0b1111_1111_1110_1100 ; 
	#	my $markerGSTank12				= 0b1111_1111_1110_1011 ; 
	#	my $markerGSTank11				= 0b1111_1111_1110_1010 ; 
	#	my $markerGSTank10				= 0b1111_1111_1110_1001 ; 
	#	my $markerGSTank09				= 0b1111_1111_1110_1000 ; 
	#	my $markerGSTank08				= 0b1111_1111_1110_0111 ; 
	#	my $markerGSTank07				= 0b1111_1111_1110_0110 ; 
	#	my $markerGSTank06				= 0b1111_1111_1110_0101 ; 
	#	my $markerGSTank05				= 0b1111_1111_1110_0100 ; 
	#	my $markerGSTank04				= 0b1111_1111_1110_0011 ; 
	#	my $markerGSTank03				= 0b1111_1111_1110_0010 ; 
	#	my $markerGSTank02				= 0b1111_1111_1110_0001 ; 
	#	my $markerGSTank01				= 0b1111_1111_1110_0000 ; 
	my $markerGasSwitch				= 0b1111_1111_1110_0000 ;	# (Upper three nibbles of) GasSwitch Marker
	my $selectTank					= 0b0000_0000_0000_1111 ;	# To extract the tank number being used.
	my $markerSet;												# Identifies a marker has been set.
	
#	Schedule included:		309, 310, 312, 313, 331
#	Profile starting from:	323
#	if ($diveNr == 331) {
#		$debug = 1
#	};

#	if ($diveNr == 331) {	# To start the processing of a single dive
			
	# Now, on to the Profile section
	seek ($fileHandle, $RecStart, 0);			# Jump to the start of the dive-profile-information.
	
	if ($debug) {
		printf("FilePointer [Start of Profile Section]: %x\n", tell($fileHandle));
	}
	
	$::diveDebugInfo{$diveNr}{FileProfileOffset}	= sprintf("0x%x", $RecStart);
	
	read ($fileHandle, $diveComputer, 1);				$diveComputer		=  unpack('c',$diveComputer);
	$::logbookEntry{$diveNr}{Profile}{DiveComputer}		= $diveComputer == 0 ? "None" : $::diveComputers{$diveComputer};
	
	read ($fileHandle, $dummy, 5);						# Reserved for future use!
	
	$::logbookEntry{$diveNr}{Profile}{0}{Tank}		= $::logbookEntry{$diveNr}{Equipment}{Tank}{$currentTank};		# The dive starts with
	until ($profileDepthMarker == $markerEndDive) {
		read ($fileHandle, $profileRuntime, 2);			$profileRuntime			=  unpack('n',$profileRuntime);
		read ($fileHandle, $profileDepthMarker, 2);		$profileDepthMarker		=  unpack('n',$profileDepthMarker);
		
#		printf ("DiveNr: %s - ProfileRunTime: %d - ProfileDepthMarker %b\n", $diveNr, $profileRuntime, $profileDepthMarker);
#        if ( $debug ){
#        	printf("RunTime: %x - Depth / Marker: %x (at position: %x)\n", $profileRuntime, $profileDepthMarker, tell($fileHandle));	
#        }
        
		if ($profileDepthMarker == $markerStartDive)				{
							 $::logbookEntry{$diveNr}{Profile}{$profileRuntime}{Marker}{StartDive} = 1;
		} ;
		if ($profileDepthMarker == $markerEndDive)				{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{EndDive} = 1} ;
		if ($profileDepthMarker == $markerSlowWarning)			{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{SlowWarning} = 1} ;
		if ($profileDepthMarker == $markerDecoAlarm)				{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{DecoAlarm} = 1} ;
		if ($profileDepthMarker == $markerDecoStart)				{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{DecoStart} = 1} ;
		if ($profileDepthMarker == $markerDecoStop)				{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{DecoStop} = 1} ;
		if ($profileDepthMarker == $markerDecoEnd)				{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{DecoEnd} = 1} ;
		if ($profileDepthMarker == $markerBreathWarning)			{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{BreathWarning} = 1} ;
		if ($profileDepthMarker == $markerTemperatureWarning)	{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{TemperatureWarning} = 1} ;
		if ($profileDepthMarker == $markerStressWarnng)			{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{StressWarning} = 1} ;
		if ($profileDepthMarker == $markerWorkloadWarning)		{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{WorkloadWarning} = 1} ;
		if ($profileDepthMarker == $markerGeneralWarnng)			{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{GeneralWarning} = 1} ;
		if ($profileDepthMarker == $markerBookMark5)				{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{BookMark5} = 1} ;
		if ($profileDepthMarker == $markerBookMark4)				{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{BookMark4} = 1} ;
		if ($profileDepthMarker == $markerBookMark3)				{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{BookMark3} = 1} ;
		if ($profileDepthMarker == $markerBookMark2)				{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{BookMark2} = 1} ;
		if ($profileDepthMarker == $markerBookMark1)				{
			$markerSet = 1; $::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Marker}{BookMark1} = 1} ;
		
		if ( ($profileDepthMarker == 0xFFF0) == $markerGasSwitch ) {	# Only upper three nibbles are used for the GasSwitchMarker
			$currentTank = $profileDepthMarker & $selectTank;
			$::logbookEntry{$diveNr}{Profile}{$lastProfileRuntime}{Tank}		= $::logbookEntry{$diveNr}{Equipment}{Tank}{$currentTank};
		}
		
		if ( !$markerSet ) {
			$::logbookEntry{$diveNr}{Profile}{$profileRuntime}{Depth} = $profileDepthMarker / 10;
			$lastProfileRuntime = $profileRuntime;
		}
		$markerSet = 0;
		
		}

#	}	# To end the processing of a single dive

#	if ($debug) {
#		print Dumper(\$..logbookEntry{$diveNr});
#	}
}


### Read Tables from input file
sub ReadTables {
	# Parameters:
	# fileName	Name of Menu-File to read
	
	my ( $fileName ) = @_;
	my $fileHandle;		# Pointer to the filehandle, used for passing it on to subroutines

	open $fileHandle, $fileName || die "Can't open $fileName: $!";
	binmode $fileHandle;
	
	# Skipping the PalmHeader
	seek ($fileHandle, $palmDBHeader, 0);		# For now, we're not interested in the header. We just want to start reading the "Record Pointers"
	read ($fileHandle, $palmDBRecords, 2);	$palmDBRecords =  unpack('n',$palmDBRecords) / 2;
	
	read ($fileHandle, $dvrRec1Start, 4);		$dvrRec1Start		=  unpack('N',$dvrRec1Start); 		seek ($fileHandle, 4, 1);
	read ($fileHandle, $dvrRec2Start, 4); 	$dvrRec2Start		=  unpack('N',$dvrRec2Start); 		seek ($fileHandle, 4, 1);
	read ($fileHandle, $dvrRec3Start, 4); 	$dvrRec3Start		=  unpack('N',$dvrRec3Start); 		seek ($fileHandle, 4, 1);
	read ($fileHandle, $locRec1Start, 4); 	$locRec1Start		=  unpack('N',$locRec1Start); 		seek ($fileHandle, 4, 1);
	read ($fileHandle, $locRec2Start, 4); 	$locRec2Start		=  unpack('N',$locRec2Start);		seek ($fileHandle, 4, 1);
	read ($fileHandle, $suitRecStart, 4); 	$suitRecStart		=  unpack('N',$suitRecStart);		seek ($fileHandle, 4, 1);
	read ($fileHandle, $dcRecStart, 4); 		$dcRecStart			=  unpack('N',$dcRecStart);			seek ($fileHandle, 4, 1);
	read ($fileHandle, $tankRecStart, 4); 	$tankRecStart		=  unpack('N',$tankRecStart);		seek ($fileHandle, 4, 1);
	read ($fileHandle, $buddyRecStart, 4); 	$buddyRecStart		=  unpack('N',$buddyRecStart);		seek ($fileHandle, 4, 1);
	read ($fileHandle, $divePageRecStart, 4); $divePageRecStart	=  unpack('N',$divePageRecStart);	seek ($fileHandle, 4, 1);
	read ($fileHandle, $generalRecStart, 4); 	$generalRecStart	=  unpack('N',$generalRecStart);	seek ($fileHandle, 4, 1);
	read ($fileHandle, $computerRecStart, 4); $computerRecStart	=  unpack('N',$computerRecStart);	seek ($fileHandle, 4, 1);
	read ($fileHandle, $gpsRecStart, 4); 		$gpsRecStart		=  unpack('N',$gpsRecStart);		seek ($fileHandle, 4, 1);
	read ($fileHandle, $plannerRecStart, 4); 	$plannerRecStart	=  unpack('N',$plannerRecStart);	seek ($fileHandle, 4, 1);
	read ($fileHandle, $diveListRecStart, 4); $diveListRecStart	=  unpack('N',$diveListRecStart);	seek ($fileHandle, 4, 1);
	read ($fileHandle, $diveTypeRecStart, 4); $diveTypeRecStart	=  unpack('N',$diveTypeRecStart);	seek ($fileHandle, 4, 1);
	
	# Set separator to "0x00"
	$/ = "\0";
	
	if ($::global_debug) {
		print "AquaPalm-TableDB - Rec#1-3 - Diver Info Records 1-3\n";
	}
	ReadDiverRec( $fileHandle, $dvrRec1Start, $::global_debug || 0 ); # Last parameter indicates Debugging (1) or not (0)
	
	if ($::global_debug) {
		print "\n"; 
		print "AquaPalm-TableDB - Rec#4 - Locations\n";
	}
	ReadLocationRec( $fileHandle, $locRec1Start, $::global_debug || 0 ); # Last parameter indicates Debugging (1) or not (0) 
	
	if ($::global_debug) {
		print "\n"; 
		print "AquaPalm-TableDB - Rec#5 - Places\n";
	}
	ReadPlacesRec( $fileHandle, $locRec2Start, $suitRecStart, $::global_debug || 0 ); # Last parameter indicates Debugging (1) or not (0)
	
	if ($::global_debug) {
		print "\n"; 
		print "AquaPalm-TableDB - Rec#6 - Suits\n";
	}
	ReadSuitRec( $fileHandle, $suitRecStart, $dcRecStart, $::global_debug || 0 ); # Last parameter indicates Debugging (1) or not (0)
	
	if ($::global_debug) {
		print "\n"; 
		print "AquaPalm-TableDB - Rec#7 - Dive Computers\n";
	}
	ReadDiveComputerRec( $fileHandle, $dcRecStart, $tankRecStart, $::global_debug || 0 ); # Last parameter indicates Debugging (1) or not (0)
	
	if ($::global_debug) {
		print "\n"; 
		print "AquaPalm-TableDB - Rec#8 - Tanks\n";
	}
	ReadTankRec( $fileHandle, $tankRecStart, $buddyRecStart, $::global_debug || 0 ); # Last parameter indicates Debugging (1) or not (0)
	
	if ($::global_debug) {
		print "\n"; 
		print "AquaPalm-TableDB - Rec#9 - Buddies\n";
	}
	ReadBuddyRec( $fileHandle, $buddyRecStart, $divePageRecStart, $::global_debug || 0 ); # Last parameter indicates Debugging (1) or not (0)
	
	if ($::global_debug) {
		print "\n"; 
		print "AquaPalm-TableDB - Rec#14 - DiveTypes\n";
	}
	ReadDiveTypeRec( $fileHandle, $diveTypeRecStart, $::global_debug || 0 ); # Last parameter indicates Debugging (1) or not (0) 
	
	close $fileHandle;
}


### Read Dives from input file
sub ReadDives {
	# Parameters:
	# fileName	Name of Menu-File to read
	
	my ( $fileName ) = @_;
	my $fileHandle;		# Pointer to the filehandle, used for passing it on to subroutines
	my %recPtrs;		# Hash containing all Record Pointers
	my $recPtr;
	my $recPtrCtr = 0;
	
	open $fileHandle, $fileName || die "Can't open $fileName: $!";
	binmode $fileHandle;
	
	# Skipping the PalmHeader
	seek ($fileHandle, $palmDBHeader, 0);		# For now, we're not interested in the header. We just want to start reading the "Record Pointers"
#	read ($fileHandle, $palmDBRecords, 2);		$palmDBRecords =  unpack('n',$palmDBRecords) / 2;
	read ($fileHandle, $palmDBRecords, 2);		$palmDBRecords =  unpack('n',$palmDBRecords);
	
	#	read ($fileHandle, $recPtr, 4);	# Just reading the first pointer.
	#	$recPtr =  unpack('N',$recPtr);
	#	while ( $recPtr != 1 ) {
	for ( $recPtrCtr = 0; $recPtrCtr < $palmDBRecords; $recPtrCtr++ ) {
		#		$recPtrs{$recPtrCtr++} = $recPtr;
		#		seek ($fileHandle, 4, 1);
		read ($fileHandle, $recPtr, 4);
		$recPtr =  unpack('N',$recPtr);
		$recPtrs{$recPtrCtr} = $recPtr;
		seek ($fileHandle, 4, 1);
	}
	
	if ($::global_debug) {
		printf ("Record Pointers found: %i, Length of PointerHash: %i\n", $recPtrCtr, scalar keys %recPtrs);
	}
	
	# Set separator to "0x00"
	$/ = "\0";
	
	#	$recPtrCtr = 0;
    for ($recPtrCtr = 0; $recPtrCtr < scalar keys %recPtrs; $recPtrCtr += 1) {
		ReadLogbookEntry( $fileHandle, $recPtrs{$recPtrCtr}, $recPtrs{$recPtrCtr+1}, $::global_debug || 0 ); # Last parameter indicates Debugging (1) or not (0)
#		print "Last DiveNr: ".$diveNr."\n";
		$recPtrCtr += 1;	# Skip to DiveProfile)
		ReadDiveProfile( $fileHandle, $recPtrs{$recPtrCtr}, $recPtrs{$recPtrCtr+1}, $::global_debug || 0 ); # Last parameter indicates Debugging (1) or not (0)
	}
	
	close $fileHandle;
}

1;
	# We need the 1; at the end because when a module loads Perl checks to see that the module returns a true value to ensure it loaded OK. You could put any true value at the end (see Code::Police) but 1 is the convention.