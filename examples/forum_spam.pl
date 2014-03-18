use Modern::Perl;
use Getopt::Long::Descriptive;
use Try::Tiny;
use String::Markov;
use lib '../lib';
use SomethingAwful::Forums;

# Post the same thing to every thread in a forum 

my ($opt, $usage) = describe_options(
  "$0 %o",
    [ 'username|u=s',   'your username maybe?',                              ],
    [ 'password|p:s',   'hmmmmm',                                            ],
    [ 'forum_id|t:i',   'forum_id to use',                { required => 1 }, ],
    [ 'message|m:s',    'message to post to each thread', { required => 1 }, ],
    [ 'goatse',         'add goatse to your posts',                          ],    
    [ 'sleep|s:i',      'Seconds to sleep between posts', { default  => 3 }, ],
    [],
    [ 'help', 'print usage message and exit'                                 ],
);
if( $opt->help ) {
    say $usage->text; 
    exit; 
}

my $message = $opt->message;
if( $opt->goatse ) {
    $message .= qw([img]http://www.goatse.info/hello.jpg[/img]);    
}

my $SA = SomethingAwful::Forums->new;

say 'Starting...';

$SA->login(
    'username' => $opt->username,
    'password' => $opt->password,
);

my $mc = String::Markov->new( 
    order => 1, 
    sep   => ' ',
);

my %icons;
# gbs icons...
$icons{1} = (420, 655, 692, 757, 60, 61, 66, 77, 79, 81, 86, 89, 95, 115, 64, 65, 67, 68, 69);

my $scraped_forum = $SA->fetch_threads( forum_id => $opt->forum_id, pages => [1..100] );
my %title_holding;

foreach my $forum_page ( @{ $scraped_forum } ) {
    foreach my $thread ( @{$forum_page->{threads}} ) {
        $title_holding{$thread->{title}} = 1;
        $mc->add_sample( $thread->{title} );
    }
}


while(1) {
    my $sample = '';
    while( length($sample) < 10 || length($sample) > 75 || exists $title_holding{$sample} ) {
        $sample = $mc->generate_sample;
    }

    try {
        $SA->new_thread( forum_id => $opt->forum_id, icon => (exists $icons{$opt->forum_id}?rand(@{$icon{$opt->forum_id}}):undef), subject => $sample, body =>  ( $message . ( ' [b][/b]' x int(rand(1000)) ) ), );
        say $sample;
    };

    sleep($opt->sleep);
}


1;


__END__
