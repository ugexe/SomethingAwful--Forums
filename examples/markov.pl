use v5.10;
use strict;
use warnings;
use URI;
use Getopt::Long::Descriptive;
use lib '../lib';
use Number::Range;
use SomethingAwful::Forums;
use String::Markov;

# Use Markov chains to generate a post based on a specific thread

my ($opt, $usage) = describe_options(
  "$0 %o",
    [ 'username|u=s',   'your username maybe?',                          ],
    [ 'password|p:s',   'hmmmmm',                                        ],
    [ 'thread_id|t:i',  'thread_id to use',       { default => 3543334 } ],
    [ 'pages:s',        'pages of thread to use (specific pages, not a count)', { default => '1..10' } ],
    [],
    [ 'help', 'print usage message and exit'    ],
);
if( $opt->help ) {
    say $usage->text; 
    exit; 
}

my $SA = SomethingAwful::Forums->new;

say 'Starting...';
if(defined $opt->username && defined $opt->password) {
    $SA->login(
        'username' => $opt->username,
        'password' => $opt->password,
    );
}
else {
    say 'No login credentials supplied. Not logging in.'
}

my @pages = Number::Range->new($opt->pages)->range;
my $scraped_thread = $SA->fetch_posts( thread_id => $opt->thread_id, pages => \@pages );

my $mc = String::Markov->new( 
    order => 1, 
    sep   => ' ',
);

foreach my $thread_page ( @{ $scraped_thread } ) {
    foreach my $post ( @{$thread_page->{posts}} ) {
        $mc->add_sample( $post->{body_no_quotes} );
    }
}

say scalar $mc->generate_sample;

1;


__END__
