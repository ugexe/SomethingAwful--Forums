use Modern::Perl;
use Getopt::Long::Descriptive;
use Number::Range;
use String::Markov;
use lib '../lib';
use SomethingAwful::Forums;

# Use Markov chains to generate a post based on a specific thread

my ($opt, $usage) = describe_options(
  "$0 %o",
    [ 'username|u=s',   'your username maybe?',                          ],
    [ 'password|p:s',   'hmmmmm',                                        ],
    [ 'thread_id|t:i',  'thread_id to use',           { required => 1 }, ],
    [ 'pages:s',        'pages of thread to use',     { required => 1 }, ],
    [ 'min_length:i',   'Minimum markov text length', { default => 10 }, ],
    [ 'reply',          'Reply with markov text',                        ],
    [],
    [ 'markov_order:i', '(see String::Markov)',       { default => 1 },  ],
    [ 'help', 'print usage message and exit'                             ],
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
    order => $opt->markov_order, 
    sep   => ' ',
);

foreach my $thread_page ( @{ $scraped_thread } ) {
    foreach my $post ( @{$thread_page->{posts}} ) {
        $mc->add_sample( $post->{body_no_quotes} );
    }
}

while(1) {
    sleep 3;
    my $sample = '';
    while( length($sample) < 10 ) {
        $sample = $mc->generate_sample;
    }

    if( $opt->reply ) {
        $SA->reply_to_thread( thread_id => $opt->thread_id, body => $sample );
        say 'Reply made!'
    }
}

1;


__END__
