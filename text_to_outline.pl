#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;

sub HELP_MESSAGE {
  print <<"EOF";
Usage:
  $0 [<options>]

Options:
  -i     Input text file containing the outline of the image (what you get out
         of fetch_outline.sh). Default is 'out/outline.txt'.
  -o     Basebane (no extension) for the output logo. .txt and .svg files will
         be created. Default is 'out/txt/image'.
  -t     Input text file for the filling content. It will be hex encoded and
         written in place of the non-space characters of the outline file.
         Default is 'content.txt'.
  -b     Background color. Used only if the outline is in HTML format.
         Characters with this (exact) color will be removed. Must match what is
         in the outline file, e.g. white and #ffffff, and #FFFFFF and treated
         differently. Default is 'white'.
  -a     Treat the input as ASCII instead of HTML (you gave the equivalent
         switch to fetch_outlinel.sh). Default is HTML, unless the outline text
         file has .txt extension.
EOF
  exit 0;
}

my %options=();
getopts("hai:o:t:b:", \%options) or HELP_MESSAGE();
HELP_MESSAGE() if @ARGV or defined $options{h};

my $outline_fname = (defined $options{i}) ? $options{i} : "out/outline.txt";
my $outimg_basename = (defined $options{o}) ? $options{o} : "out/txtimage";
my $content_fname = (defined $options{t}) ? $options{t} : "content.txt";
my $bgcol = (defined $options{b}) ? $options{b} : "white";
my $html = "1";
if (defined $options{a} or ( $outline_fname =~ /\./ &&
    ((split /\.([^\.]*)$/, $outline_fname)[1]) eq "txt") ) {
  $html = "";
};

# read in files
my $outimg = undef;
my $content = undef;
do {
  local $/ = undef; # read whole input, not just one line

  open my $fh, '<', $outline_fname or die "error opening $outline_fname $!";
  $outimg = <$fh>;
  close $fh;

  open $fh, '<', $content_fname or die "error opening $content_fname $!";
  $content = <$fh>;
  close $fh;
};

(my $charset = $content) =~ s!(.)!sprintf "%02x",ord($1)!egs;

sub nextcharsinit {
    my $pos = 0;
    return sub {
        my $len = $_[0];
        my $s = substr $charset, $pos, $len;
        my $left =  $pos + $len - length $charset;
        while ($left >= 0) {
          # wrapped around
          $pos = 0;
          $len = $left;
          $s .= substr $charset, $pos, $len;
          $left -= length $charset;
        };
        $pos += $len;
        return $s;
    };
}

my $nextchars = nextcharsinit();
$outimg =~ s!\r!!g;
if ($html) {
  print "Processing as HTML\n";
  # replace text in the bgcol color with equivalent number of spaces
  $outimg =~ s!<font color="?$bgcol"?>([a-f0-9]+)</font>!" " x length $1!eg;
  # replace the rest of the text with equivalent number of characters from the
  # character set, at the current position in the charset
  $outimg =~ s!<font color=[^>]+>([a-f0-9]+)</font>!$nextchars->(length $1) . ""!eg;
  $outimg =~ s!</? *br */?>!\n!g; # add newlines
  $outimg =~ s!<[^>]+>!!g; # remove left over html tags
  $outimg =~ s!^ *(\n|\z)!!gm; # delete blank lines
} else { # ascii
  print "Processing as ASCII\n";
  $outimg =~ s!([^ \n]+)!$nextchars->(length $1) . ""!eg;
}

do {
  # txt
  open my $fh, '>', $outimg_basename . '.txt';
  print $fh $outimg;
  close $fh;

  # svg
  my $text = "";
  my @outimglines = split /\n/, $outimg;
  ## calculate the stepY to get approx 1:1 aspect ratio
  my $stepY = 100/(1+@outimglines); # in percentage
  my $currY = $stepY;
  my $w = length($outimglines[0]); # all lines have the same no. of chars
  foreach my $line (@outimglines) {
    $text .= <<"EOF";
  <text x="0" y="$currY%">
  $line
  </text>
EOF
    $currY += $stepY;
  }

  open $fh, '>', $outimg_basename . '.svg';
  # at 16px monospace, the width should be 10xno. of chars
  print $fh <<"EOF";
<svg viewBox="0 0 ${w}0 ${w}0" xmlns="http://www.w3.org/2000/svg">
  <style>
    text {
      font: bold 16px monospace;
      white-space: pre;
    }
  </style>
$text
</svg>
EOF
  close $fh;
};

print "Saved to $outimg_basename.txt and $outimg_basename.svg\n";
