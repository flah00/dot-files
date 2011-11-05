#!/usr/bin/perl
#use Shell qw(rm mkdir ln);
$dict_counter = 0;
$in_tracks = 0;
%labels = ();
%catno = ();
$debug = 0;
if ("$ARGV[0]" eq "-d") {
	$debug= 1;
	shift();
}

print `cp .Icon Icon 2>&1`;

while (<>) {
	my($label, $catno, $path, $tpath);

	if (m#<dict>#) {
		$dict_counter++;
	} elsif (m#</dict>#) {
		$dict_counter--;
	}

	if (m#<key>Artist</key># && $dict_counter == 3 && $in_tracks) {
		$_ = htmlDecode($_);
		($artist) = $_ =~ m#<string>(.*)</string>#;

	} elsif (m#<key>Album</key># && $dict_counter == 3 && $in_tracks) {
		$_ = htmlDecode($_);
		($album) = $_ =~ m#<string>(.*)</string>#;

	} elsif (m#<key>Comments</key># && $dict_counter == 3 && $in_tracks) {
		$_ = htmlDecode($_);
		($label, $catno) = $_ =~ m#.*\[([^\]]+)\]\s*\(([^)]+)\)#;
		next if ($catno eq $last_catno);

		$labels{"$label"} ||= [];
		if (!exists($catno{"$catno"})) {
			$catno{"$catno"} = 1;
			$tmphash = {catno=>"$catno",artist=>"$artist",album=>"$album"};
			push(@{$labels{"$label"}}, $tmphash);
			$artist = $album = undef;
		}

	} elsif (m#<key>Location</key># && $dict_counter == 3 && $in_tracks) {
		$_ = htmlDecode($_);
		($path) = $_ =~ m#.*localhost(/.*)</string>#;
		## album names might have "/" in them
		$tpath = $path;
		$tpath =~ s#/[^/]*$##;
		while (! -e "$tpath") { $tpath =~ s#/[^/]+$##; print "\tPATH: $tpath\n" if($debug); }
		if ($tpath eq "") { print STDERR "error fixing '$path'"; next; }
		$tmphash->{dir} = "$tpath";

	} elsif (m#<key>Compilation</key><true/\s*># && $dict_counter == 3) {
		$tmphash->{artist} = "Various";

	} elsif (m#<key>Tracks</key># && $dict_counter == 1) {
		$in_tracks = 1;

	} elsif ($dict_counter == 0 && $in_tracks == 1) {
		$in_tracks = 0;
	}
	$last_catno = $catno;
}

foreach my $l (sort keys %labels) {
	($lstr = $l) =~ s#/#_#g;
	$!=0;
	$r=mkdir($lstr);
	if ($! && $! !~ m#File exists#) { print STDERR "mkdir($lstr): $!\n"; next; }

	foreach my $c (@{$labels{$l}}) {
		$str = "[$c->{catno}] $c->{artist} - $c->{album}";
		$str =~ s#/#_#g;
		$dir=$c->{dir};
		if ($dir eq '/Volumes') {
			print "ERROR: $str = $dir\n";
			next;
		}
		print "DIR $c->{dir}\n" if($debug);
		unlink("$lstr/$str");
		print qq|symlink("$dir", "$lstr/$str")\n| if($debug);
		symlink("$dir", "$lstr/$str")
			or print STDERR qq|\tFAILED 'ln -sf "$dir" "$lstr/$str"'\n|;
	}
}

sub htmlDecode {
	my($str) = @_;

	$str =~ s/&amp;/&/g;
	$str =~ s/&quot;/\"/g; #"
	$str =~ s/&gt;/>/g;
	$str =~ s/&lt;/</g;
	$str =~ s/&#([0-9]{1,3});/chr($1)/ge;
	$str =~ s#%([A-Fa-z0-9]{2})#chr(hex($1))#ge;

	return $str;
}

