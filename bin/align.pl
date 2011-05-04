#!/usr/bin/perl
# AUTHOR: GPL(C) Mohsin Ahmed, http://www.cs.albany.edu/~mosh.

my $splitter = ' ';

$USAGE = "
USAGE:    align options file > tabularfile
SYNOPSIS: Aligns the columns of file,
          - Breaks lines into columns, COLUMNS = split( SPLITTER_REGEXP, LINE )
          - Determines the max column widths and printf FORMAT,
          - printf( FORMAT, COLUMNS ) or s/line/sprintf(FORMAT,\@COLUMNS)/e

          You can supply the SPLITTER REGEXP, each match () becomes a column.
            number of columns, the center, the printf FORMAT,

OPTIONS:  -s:regexp   For split(  regexp,  line ), default is '$splitter'.
          -s/regexp/  For split( /regexp/, line ).
                -ss   Split on multiple spaces.
          -m:regexp   COLUMNS = ( line =~ m/(re)(ge)(xp)/ )
                      Each column comes from a paren exp, aligns on regexp.
                      If m// fails, line is printed as is.
          -c:center   same as -m:^(.?*)(center)(.*)\$, minimal initial match.
          -number     Limit above split to number columns.
          -d          Just compute the format, so you can doctor it.
                      and redo with -f option.
          -f:format   printf format string, default is to compute format.
          -v -v2 -v3  verbose, more verbose, debug.
          -Sc         Separate each column with char c.
          -pick/re/    Process lines matching re.
          -skip/re/    Skip lines matching re.

EXAMPLE:  > align -ss  infile  - infile columns are space separated.
          > align -ss -v2 file - Verbose to see what columns are causing problem.
          > align -S-  infile  - Shows each column clearly.
          > align -c:= infile  - aligns columns by first equalto,
          > align -c:= -pick/=/  - aligns all the assignments.
Notes:
    Align para inside vi:   !} align
    Emacs shell-command-on-region align
    Blanks lines are skipped and printed as is.

AUTHOR: GPL(C) Mohsin Ahmed, http://www.cs.albany.edu/~mosh
";

while( $_ = $ARGV[0], /^-/ ){
    shift;
    if( m/^--$/ ){
      last;
    }elsif( m/^-S(.)/ ){
      $separcol = $1;
    }elsif( m/^-(\d+)/ ){
      $splitcol = $1;
    }elsif( m,^-ss, ){
      $splitre = '[ \t]+';
      print STDERR "-split=/$splitre/\n";
    }elsif( m,^-s/(.+)/, ){
      $splitre = $1;
      print STDERR "-split=/$splitre/\n";
    }elsif( m/^-s:(.+)/ ){
      $splitter = $1;
      print STDERR "-split='$splitter'\n";
    }elsif( m/^-m:(.+)/ ){
        $matcher  = $1;
        print STDERR "-match=\'$matcher\'\n";
    }elsif( m/^-c:(.+)/ ){
        $matcher  = "^(.*?)($1)(.*)\$";
        print STDERR "-center -match=$matcher\n";
    }elsif( m/^-d/ ){
        print STDERR "-doctor\n";
        $doctor++;
    }elsif( m,^-pick/(.+)/, ){
        $pick = $1;
        print STDERR " -pick =~ /$pick/\n";
    }elsif( m,^-skip/(.+)/, ){
        $skip = $1;
        print STDERR " -skip  =~ /$skip/\n";
    }elsif( m/^-f:(.+)/ ){
        $format = $1;
        print STDERR "-format=\'$format\'\n";
    }elsif( m/^-v(\d*)/ ){
        $verbose = $1 || 1;
    $separcol ||= '|';
    }elsif( m/^-[?h]/ ){
        print $USAGE; exit;
    }
}

print STDERR
        "# matcher=/$matcher/, splitter='$splitter', splitcol='$splitcol',",
        "# splitre=/$splitre/, format='$format', doctor='$doctor',",
        "ARGV='@ARGV',. \n"
        if $verbose;

# Emacs will use this now via pipe.
# @ARGV || die "Need arg, see -? for help\n";

while(  $line = <> ){
    chop $line;
    push( @lines, $line );
    if( ( $pick && $line =~ m/$pick/o ) ||
        ( $skip && $line =~ m/$skip/o ) ||
        (          $line !~ m/\S/     )
    ){
      next;
    }

    if( $matcher ){
        @cols = ( $line =~ m/$matcher/ );
    }elsif( $splitre ){
        @cols = split( /$splitre/o, $line, $splitcol );
    }else{
        @cols = split( $splitter, $line, $splitcol );
    }
    print "# $. ",join( "|", @cols ) if $verbose > 1;
    for( $i=0; $col = shift( @cols ) || @cols ; $i++ ){
        my $collen = length( $col );
        if( !defined( $maxwidth[$i]) || $maxwidth[$i] < $collen ){
            $maxwidth   [$i] = $collen;
            $maxcolvalue[$i] = $col;
            $maxcolline [$i] = $.;
        }
        if( ! defined( $maxcols ) || ( $i > $maxcols ) ){
            $maxcols = $i;
        }
        print "# Format: $i $collen: $maxwidth[$i]\n" if $verbose > 2;
    }
}

unless( defined( $format ) ){
    $format = '';
    for( $i=0; $i <= $maxcols; $i++ ){
        my $collen = $maxwidth[$i];
        $format .= "$separcol \%-${collen}s";
        printf STDERR "#  col=%d width=%2d, linenumber=%3d, value=%20s\n",
               $i, $maxwidth[$i], $maxcolline[$i], $maxcolvalue[$i]
            if $verbose;
    }
    $format .= $separcol . "\n";
}


die "Format:$format" if $doctor;

print STDERR "# Format: $format" if $verbose;

foreach $line (@lines){
    my @cols;
    if( ( $pick && $line =~ m/$pick/o) ||
        ( $skip && $line =~ m/$skip/o) ||
        (          $line !~  m/\S/    )
    ){
      print $line;  # print skipped lines as is.
      next;
    }
    if( $matcher ){
        @cols = ( $line =~ m/$matcher/ );
    }elsif( $splitre ){
        @cols = split( /$splitre/o, $line, $splitcol );
    }else{
        @cols = split( $splitter, $line, $splitcol );
    }
    if( @cols ){
        printf $format, @cols;
    }else{
        print $line;
    }
}
