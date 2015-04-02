use Modern::Perl;
use Getopt::Long::Descriptive;
use Number::Range;
use Acme::Goatse;
use Try::Tiny;
use lib '../lib';
use SomethingAwful::Forums;

# Snipe somethingawful threads (first post)

my ($opt, $usage) = describe_options(
  "$0 %o",
    [ 'username|u=s',   'your username maybe?',       { required => 1     }, ],
    [ 'password|p:s',   'hmmmmm',                     { required => 1     }, ],
    [ 'forum_id|f:i',   'forum_id to use',            { required => 1     }, ],
    [ 'recheck_after:i','Rerun every X seconds',                             ],
    [ 'message|m:s',    'message to post to each thread', { required => 1 }, ],
    [ 'goatse',         'add acsii goatse to your posts',                    ],    
    [],
    [ 'help', 'print usage message and exit'                                 ],
);
if( $opt->help ) {
    say $usage->text; 
    exit; 
}

my $message = $opt->message;
if( $opt->goatse ) {
    $message .= '[code]' . goatse() . '[/code]';    
}
say 'Starting...';

my $SA = SomethingAwful::Forums->new;
$SA->login(
    'username' => $opt->username,
    'password' => $opt->password,
);


my %memory;

while(1) {
    my $waketime = ($opt->recheck_after?( time + $opt->recheck_after ):1);
    my $scraped_forum = $SA->fetch_threads( forum_id => $opt->forum_id, pages => 1 );

    foreach my $forum_page ( @{ $scraped_forum } ) {
        foreach my $thread ( @{ $forum_page->{threads} } ) {
            next if $thread->{counts}->{reply} != 0;
            next if( exists $memory{$thread->{id}} && $memory{$thread->{id}} > 5);

            try {
                $SA->reply_to_thread( 
                    thread_id => $thread->{id}, 
                    body => ( $message . ( ' [b][/b]' x int(rand(100)) ) ), 
                );
            };

            say $thread->{title};
            $memory{$thread->{id}}++;
        }
    }

    if( $waketime ) {
        my $sleep_for = $waketime - time;
        $sleep_for = $opt->recheck_after unless($sleep_for && $sleep_for != 0 && $sleep_for > 0);
        say "Rechecking in $sleep_for seconds";
        sleep( $sleep_for );
    }
    else {
        last;
    }
}


1;


__END__
