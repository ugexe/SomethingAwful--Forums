use Modern::Perl;
use Getopt::Long::Descriptive;
use Number::Range;
use Try::Tiny;
use lib '../lib';
use SomethingAwful::Forums;

# Post the same thing to every thread in a forum 

my ($opt, $usage) = describe_options(
  "$0 %o",
    [ 'username|u=s',   'your username maybe?',                              ],
    [ 'password|p:s',   'hmmmmm',                                            ],
    [ 'forum_id|t:i',   'forum_id to use',                { required => 1 }, ],
    [ 'pages:s',        'pages of forum to reply to',     { required => 1 }, ],
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

my @pages = Number::Range->new($opt->pages)->range;
my $scraped_forum = $SA->fetch_threads( forum_id => $opt->forum_id, pages => \@pages );

foreach my $forum_page ( @{ $scraped_forum } ) {
    foreach my $thread ( @{$forum_page->{threads}} ) {
        try {
            $SA->reply_to_thread( 
                thread_id => $thread->{id}, 
                body => ( $message . ( ' [b][/b]' x int(rand(1000)) ) ), # add nonsense to bypass duplicate detection
            );
        };

        sleep($opt->sleep);
    }
}


1;


__END__
