# Program for converting BioNetGen .net file to Smoldyn input file
# Written by Weiren Cui and modified by Steve Andrews

#$filename = $ARGV[0];		# first command line parameter: filename for input
$c2p = $ARGV[1];				# second command line parameter: multiplier for bimolecular reaction rates

@filedata = get_file_data("camkii-test2.net");

#$filename =~ s/\.net//;
$filename="camkii-test2.net";
$txtname = $filename.".txt";
open(OUTPUT, '>'.$txtname);
print OUTPUT "# Smoldyn reaction list converted automatically from BioNetGen output\n\n";
open(OBS, '>obs.txt');

# read in input file into data_para, data_species, data_rxn, and data_obs
%para = %species = %rxn = %mol = %obs = ();
%substant = ();
$flag_para = $flag_species = $flag_rxn = $flag_obs = 0;
$data_para = $data_species = $data_rxn = $data_obs = '';
foreach $line(@filedata){
	if($line =~ /^begin parameters/) {
		$flag_para = 1; }
	elsif($line =~ /^end parameters/) {
		$flag_para = 0; }
	elsif($line =~ /^begin species/) {
		$flag_species = 1; }
	elsif($line =~ /^end species/) {
		$flag_species = 0; }
	elsif($line =~ /^begin reactions/) {
		$flag_rxn = 1; }
	elsif($line =~ /^end reactions/) {
		$flag_rxn = 0; }
	elsif($line =~ /^begin groups/) {
		$flag_obs = 1; }
	elsif($line =~ /end groups/) {
		$flag_obs = 0; }
	else{
		if($flag_para == 1) {
			$data_para .= $line; }
		elsif($flag_species == 1) {
			$data_species .= $line; }
		elsif($flag_rxn == 1) {
			$data_rxn .= $line; }
		elsif($flag_obs == 1) {
			$data_obs .= $line; }}}

@spd_para = split("\n", $data_para);
@spd_species = split("\n", $data_species);
@spd_rxn = split("\n", $data_rxn);
@spd_obs = split("\n", $data_obs);

# extract parameters from spd_para into para list
foreach $each_para(@spd_para) {
	@spe_para = split(' ', $each_para);
	$para{$spe_para[1]} = $spe_para[2]; }

# extract species from spd_species into $species and also output species list
$species_index = 1;
$track_index = 1;
$str_track = '';
foreach $each_species(@spd_species) {
	@spe_species = split(' ', $each_species);
	if($spe_species[1] =~ /,track~/) {						# I'm not sure what this does; it's usually not run
		$bak_species = $spe_species[1];
		if($spe_species[1] =~ /,track~[1-9]/) {
			$bak_species =~ s/,track~[0-9]+//g;
			if(exists $substant{$bak_species}) {
				$sub = $substant{$bak_species}; }
			else {
				$sub = 'N/A'; }
			$str_track .= 't'.$track_index."\t".$spe_species[1]."\t".$sub."\n";
			$species{$spe_species[0]}= 't'.$track_index;
			#print OUTPUT 'species t'.$track_index."\n";
			$track_index++; }
		else {
			$bak_species =~ s/,track~0//g;
			$species{$spe_species[0]} = 's'.$species_index;
			$substant{$bak_species} = $species_index;
			#print OUTPUT 'species s'.$species_index."\n";
			$species_index++; }}
	else {																			# output species list
		$species{$spe_species[0]} = 's'.$species_index;
		#print OUTPUT 'species s'.$species_index."\t# ".$spe_species[1]."\n";
		$species_index++; }}
#print OUTPUT "\n";

# output the track.list.  This is usually not run
if(!($str_track eq '')) {
	open(TRACK, ">track.list");
	print TRACK $str_track;
	close TRACK; }

# extract obs from spd_obs.  I don't know what this does.
$track_count = 0;
#print OBS "species";
for($i = 1; $i <= scalar(@spd_species); $i++) {
	print OBS " ".$species{$i}; }
	print OBS "\n";
	foreach $each_obs(@spd_obs){
	@spe_obs = split(' ', $each_obs);
	@s2_obs = split(',', $spe_obs[2]);
	@m = ();
	for($i = 0; $i < scalar(@spd_species); $i++) {
		$m[$i] = 0; }
	foreach $s2e(@s2_obs) {
		if($s2e =~ /\*/) {
			@s = split('\*', $s2e);
			$m[$s[1] - 1] = $s[0]; }
		else {
			$m[$s2e - 1] = 1; }}
	print OBS $spe_obs[1];
	for($i = 0; $i < scalar(@spd_species); $i++){
		print OBS ' '.$m[$i]; 
		# added
		$species{1}="cam-ca4";
		if($m[$i]==1) { $species{$i+1}=$spe_obs[1]; }
		
	}
	#added
	print OUTPUT 'species '.$spe_obs[1]."\n";		
	print OBS "\n"; }
print OUTPUT 'species '.$species{1}."\n";

# extract reactions from spd_rxn and print them out
foreach $each_rxn(@spd_rxn){
	@rxn_cb[100]=();
	@spe_rxn = split(' ', $each_rxn);
	@rxn_smol="";
	@reactants = split(',', $spe_rxn[1]);
	@rxn_i=0;
	@rxn_now="";
	@print_flag=1;

	$rxn_smol="";
	foreach $reactant(@reactants) {
		$reactant = $species{$reactant}; }
	$rxn_smol .= join(' + ', @reactants);
	$rxn_smol .= ' -> ';
	@products = split(',', $spe_rxn[2]);
	foreach $product(@products) {
		$product = $species{$product}; }
	$rxn_smol .= join(' + ', @products);
	
	# added
	$rxn_now = $rxn_smol;
	$rxn_i_tmp=$rxn_i;
	$rxn_cb_val=TRUE;
	for($tmp_i=0;$tmp_i<=$rxn_i_tmp;$tmp_i++){
		$rxn_cb_val=($rxn_now ne $rxn_cb[$tmp_i])&& $rxn_cb_val;
	}
	if($rxn_cb_val){
		$rxn_cb[$rxn_i]=$rxn_now;
		$rxn_i+=1;
		$print_flag=1;
	}
	else {$print_flag=0;}
	
	if($print_flag==1){
		print OUTPUT $rxn_i." ".$rxn_cb_val." ".$rxn_cb[$rxn_i-1]."\n";
	}
}


foreach $each_rxn(@spd_rxn){
		@rxn_smol="";
		@spe_rxn = split(' ', $each_rxn);
		@reactants = split(',', $spe_rxn[1]);
		@products = split(',', $spe_rxn[2]);					
		@rxn_rate[$rxn_i]=();		

		$rxn_smol="";
		foreach $reactant(@reactants) {
			$reactant = $species{$reactant}; }
		$rxn_smol .= join(' + ', @reactants);
		$rxn_smol .= ' -> ';
		foreach $product(@products) {
			$product = $species{$product}; }
		$rxn_smol .= join(' + ', @products);
		
		$rxn_tag=0;
		for($tmp_i=0;$tmp_i<=$rxn_i-1;$tmp_i++){
			if($rxn_smol eq $rxn_cb[$tmp_i]){ $rxn_tag=$tmp_i; }
		}
				
		if($spe_rxn[3] =~ /\*/) {
			@rate = split('\*', $spe_rxn[3]);
			$rate_c = $rate[0] * $para{$rate[1]}; }
		else {
			$rate_c = $para{$spe_rxn[3]}; }
		if(scalar(@reactants) > 1) {
			$rate_c *= $c2p * $c2p * $c2p; }
		$rxn_rate[$rxn_tag]+=$rate_c;		
		$rxn_smol .= ' '.$rxn_rate[$rxn_tag];
		#print OUTPUT 'reaction rxn'.$rxn_tag." ".$rxn_smol."\n";
}

for($tmp_i=0;$tmp_i<=$rxn_i-1;$tmp_i++){
	print OUTPUT 'reaction rxn'.$tmp_i." ".$rxn_cb[$tmp_i]." ".$rxn_rate[$tmp_i]."\n";
}
print OUTPUT "\nend_file\n";
close OUTPUT;
close OBS;

print "--------------------\nBNGL is translated into Smoldyn compliler\n--------------------\n";

sub get_file_data {
    my($filename) = @_;
    my @filedata = (  );
    unless( open(GET_FILE_DATA, $filename) ) {
        print STDERR "Cannot open file \"$filename\"\n\n";
        exit; }
    @filedata = <GET_FILE_DATA>;
    close GET_FILE_DATA;
    return @filedata; }

